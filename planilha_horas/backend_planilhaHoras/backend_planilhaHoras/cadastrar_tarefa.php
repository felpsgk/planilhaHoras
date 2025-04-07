<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');
require_once 'conexao.php';

$data = $_POST['data'] ?? date('Y-m-d');
$user_id = $_POST['user_id'] ?? null;
$categoria_id = $_POST['categoria'] ?? null;
$squad_id = $_POST['squad'] ?? null;
$ritm = $_POST['ritm'] ?? '';
$demandante = $_POST['demandante'] ?? '';
$descricao = $_POST['descricao'] ?? '';
$duracao = intval($_POST['duracao_minutos'] ?? 0);
$forcar = $_POST['confirmar_limite'] ?? false;

if (!$user_id || !$duracao || !$categoria_id || !$squad_id) {
    echo json_encode(['success' => false, 'message' => 'Campos obrigatórios ausentes.']);
    exit;
}

// 🔍 Buscar nome da categoria
$resCategoria = $conn->query("SELECT nome FROM categorias_planilhaHoras WHERE id = $categoria_id LIMIT 1");
if ($resCategoria->num_rows == 0) {
    echo json_encode(['success' => false, 'message' => 'Categoria inválida.']);
    exit;
}
$categoria_nome = $resCategoria->fetch_assoc()['nome'];

// 🔍 Buscar nome do squad
$resSquad = $conn->query("SELECT nome FROM squads_planilhaHoras WHERE id = $squad_id LIMIT 1");
if ($resSquad->num_rows == 0) {
    echo json_encode(['success' => false, 'message' => 'Squad inválido.']);
    exit;
}
$squad_nome = $resSquad->fetch_assoc()['nome'];

// 1. Buscar a faixa de trabalho do dia
$res = $conn->query("SELECT hora_inicio, hora_fim FROM faixas_trabalho WHERE user_id = $user_id AND data = '$data' LIMIT 1");
if ($res->num_rows == 0) {
    echo json_encode(['success' => false, 'message' => 'Faixa de trabalho não definida para o dia.']);
    exit;
}
$faixa = $res->fetch_assoc();
$inicio_faixa = $faixa['hora_inicio'];
$fim_faixa = $faixa['hora_fim'];

// 2. Buscar a última tarefa do dia
$res = $conn->query("SELECT hora_fim FROM tarefas WHERE user_id = $user_id AND data = '$data' ORDER BY hora_fim DESC LIMIT 1");

$nova_inicio = $inicio_faixa;
if ($res->num_rows > 0) {
    $ultima = $res->fetch_assoc();
    $nova_inicio = $ultima['hora_fim'];
}

// 3. Calcular hora_fim com base na duração
$nova_inicio_dt = new DateTime($data . ' ' . $nova_inicio);
$nova_fim_dt = clone $nova_inicio_dt;
$nova_fim_dt->modify("+$duracao minutes");

$hora_fim = $nova_fim_dt->format('H:i');

// 4. Validar se ultrapassa a faixa de trabalho
if ($hora_fim > $fim_faixa && !$forcar) {
    echo json_encode([
        'success' => false,
        'message' => 'Tarefa ultrapassa a faixa de trabalho.',
        'overflow' => true,
        'hora_fim' => $hora_fim
    ]);
    exit;
}

// 5. Inserir tarefa (salvando o NOME da categoria e squad)
$stmt = $conn->prepare("INSERT INTO tarefas (user_id, data, hora_inicio, hora_fim, duracao_minutos, categoria, squad, ritm, demandante, descricao)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("isssisssss", $user_id, $data, $nova_inicio, $hora_fim, $duracao, $categoria_nome, $squad_nome, $ritm, $demandante, $descricao);

$stmt->execute();

echo json_encode([
    'success' => true,
    'message' => 'Tarefa cadastrada com sucesso!',
    'hora_inicio' => $nova_inicio,
    'hora_fim' => $hora_fim
]);
?>

<?php
require_once 'conexao.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');

$tarefa_id = $_POST['tarefa_id'] ?? null;
$categoria = $_POST['categoria'] ?? '';
$dataPost = $_POST['data'] ?? date('Y-m-d');
$ritm = $_POST['ritm'] ?? '';
$demandante = $_POST['demandante'] ?? '';
$descricao = $_POST['descricao'] ?? '';
$duracao = intval($_POST['duracao_minutos'] ?? 0);
$ajustarFuturas = isset($_POST['ajustar_futuras']) && $_POST['ajustar_futuras'] == '1';

if (!$tarefa_id || !$duracao || !$categoria) {
    echo json_encode(['success' => false, 'message' => 'Campos obrigatórios ausentes.']);
    exit;
}

// Buscar a tarefa atual
$res = $conn->query("SELECT * FROM tarefas WHERE id = $tarefa_id");
if ($res->num_rows == 0) {
    echo json_encode(['success' => false, 'message' => 'Tarefa não encontrada.']);
    exit;
}
$tarefa = $res->fetch_assoc();

$user_id = $tarefa['user_id'];
$hora_inicio = $tarefa['hora_inicio'];

// Calcular nova hora_fim
$nova_inicio = new DateTime("$dataPost $hora_inicio");
$nova_fim = clone $nova_inicio;
$nova_fim->modify("+$duracao minutes");
$hora_fim = $nova_fim->format('H:i');

// Atualizar tarefa principal
$stmt = $conn->prepare("UPDATE tarefas SET data = ?,categoria = ?, ritm = ?, demandante = ?, descricao = ?, duracao_minutos = ?, hora_fim = ? WHERE id = ?");
$stmt->bind_param("sssssisi", $dataPost,$categoria, $ritm, $demandante, $descricao, $duracao, $hora_fim, $tarefa_id);
$stmt->execute();

if ($ajustarFuturas) {
    // Buscar tarefas após a tarefa atual
    $resFuturas = $conn->query("SELECT * FROM tarefas 
                                WHERE user_id = $user_id AND data = '$dataPost' AND hora_inicio > '$hora_inicio' 
                                ORDER BY hora_inicio ASC");

    $horaAnterior = $hora_fim;
    while ($row = $resFuturas->fetch_assoc()) {
        $nova_inicio = new DateTime("$dataPost $horaAnterior");
        $nova_fim = clone $nova_inicio;
        $nova_fim->modify("+{$row['duracao_minutos']} minutes");

        $novo_inicio_str = $nova_inicio->format('H:i');
        $novo_fim_str = $nova_fim->format('H:i');

        $id_tarefa = $row['id'];

        $conn->query("UPDATE tarefas 
                      SET hora_inicio = '$novo_inicio_str', hora_fim = '$novo_fim_str' 
                      WHERE id = $id_tarefa");

        $horaAnterior = $novo_fim_str;
    }
}

echo json_encode(['success' => true, 'message' => 'Tarefa atualizada com sucesso.']);

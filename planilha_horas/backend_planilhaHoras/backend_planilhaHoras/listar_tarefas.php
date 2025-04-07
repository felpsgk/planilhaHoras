<?php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');
require 'conexao.php';

$user_id = $_POST['user_id'] ?? '';
$data = $_POST['data'] ?? '';

if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'ID do usuário é obrigatório']);
    exit;
}

// Agora buscando com JOIN para trazer nomes da categoria e squad
$stmt = $conn->prepare("
    SELECT 
        t.id, 
        t.data, 
        t.hora_inicio, 
        t.hora_fim, 
        t.ritm, 
        t.demandante, 
        t.descricao, 
        t.duracao_minutos,
        t.categoria AS categoria_nome,
        t.squad AS squad_nome
    FROM tarefas t
    WHERE t.user_id = ? AND t.data = ?
    ORDER BY t.hora_inicio ASC
");
$stmt->bind_param("is", $user_id, $data);
$stmt->execute();
$result = $stmt->get_result();

$tarefas = [];
while ($row = $result->fetch_assoc()) {
    $tarefas[] = $row;
}

echo json_encode(['success' => true, 'tarefas' => $tarefas]);

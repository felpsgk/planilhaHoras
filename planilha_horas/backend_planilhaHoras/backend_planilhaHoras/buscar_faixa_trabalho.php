<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once 'conexao.php';

$user_id = $_GET['user_id'] ?? '';
$data = date('Y-m-d');

if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'user_id é obrigatório']);
    exit;
}

$stmt = $conn->prepare("SELECT hora_inicio, hora_fim FROM faixas_trabalho WHERE user_id = ? AND data = ?");
$stmt->bind_param("is", $user_id, $data);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode([
        'success' => true,
        'hora_inicio' => $row['hora_inicio'],
        'hora_fim' => $row['hora_fim']
    ]);
} else {
    echo json_encode(['success' => false, 'message' => 'Nenhuma faixa registrada para hoje.']);
}

<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'conexao.php';

$user_id = $_POST['user_id'] ?? '';
$hora_inicio = $_POST['hora_inicio'] ?? '';
$hora_fim = $_POST['hora_fim'] ?? '';
$data = date('Y-m-d'); // data de hoje

if (!$user_id || !$hora_inicio || !$hora_fim) {
    echo json_encode(['success' => false, 'message' => 'Parâmetros obrigatórios ausentes.']);
    exit;
}

// Verifica se já existe faixa para hoje
$sqlCheck = "SELECT id FROM faixas_trabalho WHERE user_id = ? AND data = ?";
$stmtCheck = $conn->prepare($sqlCheck);
$stmtCheck->bind_param("is", $user_id, $data);
$stmtCheck->execute();
$result = $stmtCheck->get_result();

if ($result->num_rows > 0) {
    // Atualiza se já existir
    $stmt = $conn->prepare("UPDATE faixas_trabalho SET hora_inicio = ?, hora_fim = ? WHERE user_id = ? AND data = ?");
    $stmt->bind_param("ssis", $hora_inicio, $hora_fim, $user_id, $data);
} else {
    // Insere novo
    $stmt = $conn->prepare("INSERT INTO faixas_trabalho (user_id, data, hora_inicio, hora_fim) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("isss", $user_id, $data, $hora_inicio, $hora_fim);
}

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Faixa de trabalho salva com sucesso!']);
} else {
    echo json_encode(['success' => false, 'message' => 'Erro ao salvar faixa: ' . $stmt->error]);
}

$stmt->close();
$conn->close();

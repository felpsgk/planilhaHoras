<?php
header('Content-Type: application/json');

// Conexão com o banco
require_once 'conexao.php';

// Recebe dados da URL
$nome  = $_GET['nome'] ?? '';
$email = $_GET['email'] ?? '';
$senha = $_GET['senha'] ?? '';

if (!$nome || !$email || !$senha) {
    echo json_encode(['success' => false, 'message' => 'Parâmetros obrigatórios ausentes.']);
    exit;
}

// Criptografa a senha
$senhaHash = password_hash($senha, PASSWORD_BCRYPT);

// Prepara e executa o insert
$stmt = $conn->prepare("INSERT INTO login_planilhaHoras (nome, email, senha) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $nome, $email, $senhaHash);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Usuário cadastrado com sucesso!']);
} else {
    echo json_encode(['success' => false, 'message' => 'Erro ao inserir usuário: ' . $stmt->error]);
}

$stmt->close();
$conn->close();

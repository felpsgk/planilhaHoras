<?php
// CORS headers (antes de qualquer output)
header("Access-Control-Allow-Origin: *"); // ou substitua * pelo domínio específico
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Preflight response para OPTIONS (evita erro no Flutter)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Continua o script normalmente...
// Conexão com o banco
require_once 'conexao.php';

// Pega os dados do POST
$email = $_POST['email'] ?? '';
$senha = $_POST['senha'] ?? '';

if (!$email || !$senha) {
    echo json_encode(['success' => false, 'message' => 'Campos obrigatórios.']);
    exit;
}

// Prepara a consulta
$stmt = $conn->prepare("SELECT id, nome, email, senha FROM login_planilhaHoras WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'E-mail ou senha incorretos.']);
    exit;
}

$user = $result->fetch_assoc();

// Verifica a senha
if (!password_verify($senha, $user['senha'])) {
    echo json_encode(['success' => false, 'message' => 'E-mail ou senha incorretos.']);
    exit;
}

// Gera token fictício (pode usar JWT depois)
$token = bin2hex(random_bytes(16));

echo json_encode([
    'success' => true,
    'message' => 'Login realizado com sucesso.',
    'user_id' => $user['id'],
    'email' => $user['email'],
    'nome' => $user['nome'],
    'token' => $token
]);

$stmt->close();
$conn->close();

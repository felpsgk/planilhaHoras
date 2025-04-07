<?php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');
require_once 'conexao.php';

$sql = "SELECT id, nome FROM categorias_planilhaHoras ORDER BY nome";
$result = $conn->query($sql);

$categorias = [];
while ($row = $result->fetch_assoc()) {
    $categorias[] = $row;
}

echo json_encode($categorias);
?>

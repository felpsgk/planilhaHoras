<?php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');
require_once 'conexao.php';

$sql = "SELECT id, nome FROM squads_planilhaHoras ORDER BY nome";
$result = $conn->query($sql);

$squads = [];
while ($row = $result->fetch_assoc()) {
    $squads[] = $row;
}

echo json_encode($squads);
?>

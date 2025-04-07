<?php
$servername = "localhost:3306"; 
$username = "felpst09_healthmanageadmin";
$password = "felipepereiramachado";
$dbname = "felpst09_felpsUtils";

// Cria a Conex���o
$conn = new mysqli($servername, $username, $password, $dbname);

// Verifica a Conex���o
if ($conn->connect_error) {
    die("Conex���o falhou: " . $conn->connect_error);
}
?>

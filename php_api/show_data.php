<?php
include "condb.php";

try {

    $stmt = $conn->query("SELECT id, name, phone, email, faculty, image FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($users);
    
} catch (PDOException $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>

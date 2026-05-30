<?php
require 'api/config/database.php';
$db = Database::getInstance()->getConnection();
$logs = $db->query("SELECT id, meal_time, food_name FROM food_logs")->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($logs, JSON_PRETTY_PRINT);

<?php
require_once __DIR__ . '/config/database.php';

try {
    $db = Database::getInstance()->getConnection();

    // Read SQL migration file
    $sql = file_get_contents(__DIR__ . '/../database/migration_add_gender.sql');

    // Execute query
    $db->exec($sql);

    echo "Migration successfully completed: gender column added to users table!\n";
} catch (Exception $e) {
    echo "Migration failed or already run: " . $e->getMessage() . "\n";
}

<?php
require_once __DIR__ . '/config/database.php';

try {
    $db = Database::getInstance()->getConnection();

    // Read SQL migration file
    $sql = file_get_contents(__DIR__ . '/../database/migration_badge_categories.sql');

    // Execute query
    $db->exec($sql);

    echo "Migration successfully completed: category and target_value columns added and seeded!\n";
} catch (Exception $e) {
    echo "Migration failed or already run: " . $e->getMessage() . "\n";
}

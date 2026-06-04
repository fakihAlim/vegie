<?php
// Only allow execution in development environment via CLI
if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    die("Access denied: This script can only be run via CLI.\n");
}

$allowMigrations = false;
$envFile = __DIR__ . '/env.php';
if (file_exists($envFile)) {
    $env = require $envFile;
    $allowMigrations = $env['ALLOW_MIGRATIONS'] ?? false;
}

if (!$allowMigrations) {
    die("Access denied: Migrations/Seeders are disabled. Enable 'ALLOW_MIGRATIONS' in env.php to run.\n");
}

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

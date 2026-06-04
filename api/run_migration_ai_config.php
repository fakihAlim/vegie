<?php
/**
 * Run AI Config Migration
 * LovingHarmony API
 */

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
    $sqlFile = __DIR__ . '/../database/migration_ai_config.sql';
    if (!file_exists($sqlFile)) {
        throw new Exception("Migration SQL file not found at: " . $sqlFile);
    }
    
    $sql = file_get_contents($sqlFile);

    // Execute queries
    $db->exec($sql);
    echo "Database migration successfully executed!\n";

    // Import existing key from env.php if present and not already registered
    $envPath = __DIR__ . '/env.php';
    if (file_exists($envPath)) {
        $env = require $envPath;
        if (!empty($env['GEMINI_API_KEY'])) {
            $existingKey = $env['GEMINI_API_KEY'];
            
            // Check if key already exists in database
            $stmt = $db->prepare("SELECT COUNT(*) FROM ai_gemini_keys WHERE api_key = ?");
            $stmt->execute([$existingKey]);
            if ($stmt->fetchColumn() == 0) {
                $insertStmt = $db->prepare("
                    INSERT INTO ai_gemini_keys (api_key, status, rpm_limit, tpm_limit, rpd_limit)
                    VALUES (?, 'active', 15, 250000, 500)
                ");
                $insertStmt->execute([$existingKey]);
                echo "Successfully imported active GEMINI_API_KEY from env.php into the database.\n";
            } else {
                echo "GEMINI_API_KEY from env.php is already in the database.\n";
            }
        }
    }

    echo "AI Config Migration successfully completed!\n";
} catch (Exception $e) {
    echo "AI Config Migration failed: " . $e->getMessage() . "\n";
    exit(1);
}

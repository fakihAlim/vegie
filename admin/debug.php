<?php
/**
 * Debug / Diagnostik Server
 * Upload file ini ke server, buka di browser, lalu HAPUS setelah selesai.
 */
ini_set('display_errors', 1);
error_reporting(E_ALL);

echo "<h1>🔍 Diagnostik Server LovingHarmony</h1>";
echo "<hr>";

// 1. PHP Version
echo "<h2>1. PHP Version</h2>";
echo "<p>PHP " . phpversion() . "</p>";

// 2. Required Extensions
echo "<h2>2. Ekstensi PHP</h2>";
$required = ['pdo', 'pdo_mysql', 'json', 'session', 'mbstring'];
foreach ($required as $ext) {
    $status = extension_loaded($ext) ? '✅' : '❌ TIDAK ADA';
    echo "<p><b>$ext</b>: $status</p>";
}

// 3. Check env.php
echo "<h2>3. File env.php</h2>";
$envPath = __DIR__ . '/../api/env.php';
echo "<p>Path yang dicari: <code>$envPath</code></p>";
if (file_exists($envPath)) {
    echo "<p>✅ File env.php ditemukan!</p>";
    $env = require $envPath;
    echo "<p>DB_HOST: <code>" . ($env['DB_HOST'] ?? '<i>tidak diset</i>') . "</code></p>";
    echo "<p>DB_NAME: <code>" . ($env['DB_NAME'] ?? '<i>tidak diset</i>') . "</code></p>";
    echo "<p>DB_USER: <code>" . ($env['DB_USER'] ?? '<i>tidak diset</i>') . "</code></p>";
    echo "<p>DB_PASS: <code>" . (isset($env['DB_PASS']) ? str_repeat('*', strlen($env['DB_PASS'])) : '<i>tidak diset</i>') . "</code></p>";
} else {
    echo "<p>❌ File env.php TIDAK ditemukan di path tersebut.</p>";
    echo "<p>Menggunakan default: localhost / lovingharmony / root / (kosong)</p>";
}

// 4. Test Database Connection
echo "<h2>4. Tes Koneksi Database</h2>";
try {
    if (file_exists($envPath)) {
        $env = require $envPath;
        $host = $env['DB_HOST'] ?? 'localhost';
        $dbname = $env['DB_NAME'] ?? 'lovingharmony';
        $user = $env['DB_USER'] ?? 'root';
        $pass = $env['DB_PASS'] ?? '';
    } else {
        $host = 'localhost';
        $dbname = 'lovingharmony';
        $user = 'root';
        $pass = '';
    }

    $dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    echo "<p>✅ Koneksi database BERHASIL!</p>";

    // 5. Check tables
    echo "<h2>5. Tabel Database</h2>";
    $tables = ['admins', 'users', 'food_logs', 'news', 'recipes', 'groups_tbl'];
    foreach ($tables as $table) {
        try {
            $stmt = $pdo->query("SELECT COUNT(*) as c FROM $table");
            $count = $stmt->fetch()['c'];
            echo "<p>✅ <b>$table</b>: $count baris</p>";
        } catch (Exception $e) {
            echo "<p>❌ <b>$table</b>: " . htmlspecialchars($e->getMessage()) . "</p>";
        }
    }

} catch (PDOException $e) {
    echo "<p>❌ Koneksi GAGAL: <code>" . htmlspecialchars($e->getMessage()) . "</code></p>";
}

// 6. Check file structure
echo "<h2>6. Struktur File</h2>";
$files = [
    __DIR__ . '/../api/config/database.php',
    __DIR__ . '/includes/header.php',
    __DIR__ . '/includes/sidebar.php',
    __DIR__ . '/includes/footer.php',
    __DIR__ . '/assets/css/style.css',
];
foreach ($files as $file) {
    $status = file_exists($file) ? '✅' : '❌ TIDAK ADA';
    $basename = str_replace(__DIR__ . '/..', '', $file);
    echo "<p>$status <code>$basename</code></p>";
}

echo "<hr>";
echo "<p style='color:red;'><b>⚠️ PENTING: Hapus file debug.php ini setelah selesai diagnostik!</b></p>";

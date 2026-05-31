<?php
/**
 * Lottie Preset Loader with CORS Headers
 * LovingHarmony Admin Panel
 */
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Check admin auth for security
if (!isset($_SESSION['admin_id'])) {
    http_response_code(403);
    echo json_encode(['error' => 'Unauthorized access']);
    exit;
}

if (isset($_GET['file'])) {
    $file = basename($_GET['file']); // Sanitize against directory traversal
    $filePath = __DIR__ . '/../../../vegie_app/assets/lottie/' . $file;
    
    if (file_exists($filePath) && pathinfo($filePath, PATHINFO_EXTENSION) === 'json') {
        header('Content-Type: application/json');
        header('Access-Control-Allow-Origin: *');
        header('Cache-Control: public, max-age=86400'); // Cache for 1 day
        echo file_get_contents($filePath);
        exit;
    }
}

http_response_code(404);
header('Content-Type: application/json');
echo json_encode(['error' => 'Preset file not found']);

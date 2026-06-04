<?php
/**
 * AI Myth Generator AJAX Endpoint
 * LovingHarmony Admin Panel
 */
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Check admin auth for security
if (!isset($_SESSION['admin_id'])) {
    http_response_code(403);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Unauthorized access']);
    exit;
}

require_once __DIR__ . '/../../../api/helpers/ai_myth_generator.php';

header('Content-Type: application/json');

// Get POST JSON body
$input = json_decode(file_get_contents('php://input'), true);
$mode = $input['mode'] ?? 'auto';
$customPrompt = ($mode === 'custom') ? trim($input['custom_prompt'] ?? '') : '';

try {
    $result = generatePlantBasedMyth($customPrompt);
    if ($result) {
        echo json_encode(['success' => true, 'data' => $result]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Gagal menghubungi AI atau response tidak valid.']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

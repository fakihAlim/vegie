<?php
/**
 * API Response Helpers
 * LovingHarmony API
 */

/**
 * Send a JSON success response
 */
function jsonSuccess($data = null, $message = 'Success', $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Send a JSON error response
 */
function jsonError($message = 'An error occurred', $statusCode = 400, $errors = null) {
    http_response_code($statusCode);
    $response = [
        'success' => false,
        'message' => $message
    ];
    if ($errors !== null) {
        $response['errors'] = $errors;
    }
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Send a paginated JSON response
 */
function jsonPaginated($data, $total, $page, $perPage, $message = 'Success') {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data,
        'pagination' => [
            'total' => (int) $total,
            'page' => (int) $page,
            'per_page' => (int) $perPage,
            'total_pages' => ceil($total / $perPage)
        ]
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Get JSON body from request
 */
function getJsonBody() {
    $body = file_get_contents('php://input');
    $data = json_decode($body, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        return [];
    }
    return $data;
}

/**
 * Validate required fields in data array
 */
function validateRequired($data, $fields) {
    $missing = [];
    foreach ($fields as $field) {
        if (!isset($data[$field]) || (is_string($data[$field]) && trim($data[$field]) === '')) {
            $missing[] = $field;
        }
    }
    if (!empty($missing)) {
        jsonError('Missing required fields: ' . implode(', ', $missing), 422, [
            'missing_fields' => $missing
        ]);
    }
}

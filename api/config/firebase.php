<?php
/**
 * Firebase Cloud Messaging Configuration (FCM V1)
 * LovingHarmony API
 */

// Load the service account JSON
$serviceAccountPath = __DIR__ . '/service-account.json';
if (file_exists($serviceAccountPath)) {
    $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
    define('FCM_V1_URL', "https://fcm.googleapis.com/v1/projects/{$serviceAccount['project_id']}/messages:send");
} else {
    $serviceAccount = null;
}

/**
 * Generates an OAuth2 Access Token for FCM V1
 */
function getFCMV1AccessToken() {
    global $serviceAccount;
    if (!$serviceAccount) return null;

    $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
    $now = time();
    $payload = json_encode([
        'iss' => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => $serviceAccount['token_uri'],
        'exp' => $now + 3600,
        'iat' => $now
    ]);

    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
    $signatureInput = $base64UrlHeader . "." . $base64UrlPayload;

    $privateKey = $serviceAccount['private_key'];
    openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    $jwt = $signatureInput . "." . $base64UrlSignature;

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $serviceAccount['token_uri']);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));

    $result = curl_exec($ch);
    curl_close($ch);
    $response = json_decode($result, true);

    return $response['access_token'] ?? null;
}

/**
 * Send FCM V1 Push Notification
 * 
 * @param array $tokens - Array of FCM device tokens
 * @param string $title - Notification title
 * @param string $body - Notification body
 * @param array $data - Additional data
 * @return array
 */
function sendFCMNotification($tokens, $title, $body, $data = []) {
    $accessToken = getFCMV1AccessToken();
    if (!$accessToken) {
        return ['success' => false, 'message' => 'Failed to generate access token'];
    }

    $results = [];
    $successCount = 0;

    foreach ($tokens as $token) {
        $payload = [
            'message' => [
                'token' => $token,
                'notification' => [
                    'title' => $title,
                    'body' => $body
                ],
                'data' => array_map('strval', $data) // FCM V1 data values must be strings
            ]
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, FCM_V1_URL);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json'
        ]);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode === 200) $successCount++;
        $results[] = json_decode($response, true);
    }

    return [
        'success' => $successCount > 0,
        'success_count' => $successCount,
        'total' => count($tokens),
        'raw_responses' => $results
    ];
}

<?php
/**
 * Simple JWT Implementation (HMAC-SHA256)
 * LovingHarmony API
 * 
 * No external libraries needed - pure PHP implementation
 */

define('JWT_SECRET', 'LovingHarmony_S3cr3t_K3y_2026_Ch4ng3_Th1s!');
define('JWT_EXPIRY', 86400 * 30); // 30 days

/**
 * Base64 URL encode
 */
function base64UrlEncode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

/**
 * Base64 URL decode
 */
function base64UrlDecode($data) {
    return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', 3 - (3 + strlen($data)) % 4));
}

/**
 * Create a JWT token
 * 
 * @param array $payload - Data to encode in the token
 * @return string - JWT token string
 */
function jwtEncode($payload) {
    $header = [
        'alg' => 'HS256',
        'typ' => 'JWT'
    ];

    // Add issued at and expiry
    $payload['iat'] = time();
    $payload['exp'] = time() + JWT_EXPIRY;

    $headerEncoded = base64UrlEncode(json_encode($header));
    $payloadEncoded = base64UrlEncode(json_encode($payload));

    $signature = hash_hmac('sha256', "$headerEncoded.$payloadEncoded", JWT_SECRET, true);
    $signatureEncoded = base64UrlEncode($signature);

    return "$headerEncoded.$payloadEncoded.$signatureEncoded";
}

/**
 * Decode and verify a JWT token
 * 
 * @param string $token - JWT token string
 * @return array|false - Decoded payload or false if invalid
 */
function jwtDecode($token) {
    $parts = explode('.', $token);

    if (count($parts) !== 3) {
        return false;
    }

    list($headerEncoded, $payloadEncoded, $signatureEncoded) = $parts;

    // Verify signature
    $expectedSignature = base64UrlEncode(
        hash_hmac('sha256', "$headerEncoded.$payloadEncoded", JWT_SECRET, true)
    );

    if (!hash_equals($expectedSignature, $signatureEncoded)) {
        return false;
    }

    $payload = json_decode(base64UrlDecode($payloadEncoded), true);

    if (!$payload) {
        return false;
    }

    // Check expiry
    if (isset($payload['exp']) && $payload['exp'] < time()) {
        return false;
    }

    return $payload;
}

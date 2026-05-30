<?php
/**
 * Authentication Middleware
 * LovingHarmony API
 * 
 * Verifies JWT token from Authorization header
 */

require_once __DIR__ . '/../helpers/jwt.php';
require_once __DIR__ . '/../helpers/response.php';

/**
 * Authenticate the request and return user data from token
 * 
 * @return array - User data from JWT payload
 */
function authenticate() {
    $headers = getallheaders();
    $authHeader = null;

    // Check for Authorization header (case-insensitive)
    foreach ($headers as $key => $value) {
        if (strtolower($key) === 'authorization') {
            $authHeader = $value;
            break;
        }
    }

    if (!$authHeader) {
        jsonError('Authorization header is required', 401);
    }

    // Extract Bearer token
    if (!preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
        jsonError('Invalid authorization format. Use: Bearer <token>', 401);
    }

    $token = $matches[1];
    $payload = jwtDecode($token);

    if (!$payload) {
        jsonError('Invalid or expired token', 401);
    }

    if (!isset($payload['user_id'])) {
        jsonError('Invalid token payload', 401);
    }

    return $payload;
}

/**
 * Optional authentication - returns user data if token is present, null otherwise
 * 
 * @return array|null
 */
function optionalAuth() {
    $headers = getallheaders();
    $authHeader = null;

    foreach ($headers as $key => $value) {
        if (strtolower($key) === 'authorization') {
            $authHeader = $value;
            break;
        }
    }

    if (!$authHeader) {
        return null;
    }

    if (!preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
        return null;
    }

    $token = $matches[1];
    $payload = jwtDecode($token);

    return $payload ?: null;
}

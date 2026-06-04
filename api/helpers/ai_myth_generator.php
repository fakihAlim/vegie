<?php
/**
 * AI Myth Generator Helper
 * Vegie App API
 * 
 * Generates plant-based nutrition myths and facts using Google Gemini API.
 */

// Load env config if exists
$envPath = __DIR__ . '/../env.php';
if (file_exists($envPath)) {
    $env = require $envPath;
    if (!defined('GEMINI_API_KEY') && isset($env['GEMINI_API_KEY'])) {
        define('GEMINI_API_KEY', $env['GEMINI_API_KEY']);
    }
}

// Default configuration — can be overridden by env.php
if (!defined('GEMINI_API_KEY')) {
    define('GEMINI_API_KEY', '');
}

/**
 * Generate a plant-based myth or fact using AI.
 * Powered by Google Gemini API.
 * 
 * @param string $adminPrompt - Optional custom prompt from admin
 * @return array|null - Myth data array or null on failure
 */
function generatePlantBasedMyth(string $adminPrompt = ''): ?array {
    if (empty($adminPrompt)) {
        $prompt = 'Kamu adalah ahli gizi dan edukator diet plant-based (nabati). '
            . 'Buatkan 1 data mitos (myth) atau fakta (fact) baru seputar diet vegetarian, vegan, atau makanan nabati yang edukatif dan menarik. '
            . 'Kembalikan HANYA dalam format JSON mentah (tanpa markdown, tanpa penjelasan tambahan) dengan struktur berikut: '
            . '{"title": "Judul mitos atau fakta berupa pernyataan singkat yang sering terdengar", "type": "myth" atau "fact", "description": "Penjelasan ilmiah yang detail dan informatif mengapa hal tersebut merupakan mitos atau fakta"}';
    } else {
        $prompt = 'Kamu adalah ahli gizi dan edukator diet plant-based (nabati). '
            . 'Berdasarkan permintaan/topik berikut: "' . $adminPrompt . '". '
            . 'Buatkan 1 data mitos (myth) atau fakta (fact) seputar diet vegetarian, vegan, atau makanan nabati yang edukatif dan menarik. '
            . 'Kembalikan HANYA dalam format JSON mentah (tanpa markdown, tanpa penjelasan tambahan) dengan struktur berikut: '
            . '{"title": "Judul mitos atau fakta berupa pernyataan singkat yang sering terdengar", "type": "myth" atau "fact", "description": "Penjelasan ilmiah yang detail dan informatif mengapa hal tersebut merupakan mitos atau fakta"}';
    }

    // Generate using Gemini API (cloud AI)
    return generateMythWithGemini($prompt);
}

/**
 * Generate myth using Gemini API (cloud) — Fallback
 * 
 * @param string $prompt
 * @return array|null
 */
function generateMythWithGemini(string $prompt): ?array {
    $startTime = microtime(true);
    $apiKey = defined('GEMINI_API_KEY') && !empty(GEMINI_API_KEY) ? GEMINI_API_KEY : '';
    
    require_once __DIR__ . '/../config/database.php';
    require_once __DIR__ . '/ai_key_manager.php';
    
    $db = Database::getInstance()->getConnection();
    
    if (empty($apiKey)) {
        // Fallback to active keys in database
        $stmtKey = $db->query("SELECT api_key FROM ai_gemini_keys WHERE status = 'active' LIMIT 1");
        $encryptedKey = $stmtKey->fetchColumn() ?: '';
        $apiKey = AiKeyManager::decrypt($encryptedKey);
    }

    $maskedKey = AiKeyManager::maskKey($apiKey);

    if (empty($apiKey)) {
        $reason = "Gemini API key not configured";
        error_log("AI Myth Generator - " . $reason);
        
        // Log failed attempt
        try {
            $stmtLog = $db->prepare("
                INSERT INTO ai_usage_logs (model_used, status, fallback_reason)
                VALUES ('gemini-3.1-flash-lite', 'failed', ?)
            ");
            $stmtLog->execute([$reason]);
        } catch (Exception $e) {
            error_log("AI Myth Generator - Log failed: " . $e->getMessage());
        }
        
        return null;
    }

    $url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=" . $apiKey;

    $payload = json_encode([
        'contents' => [
            [
                'parts' => [
                    ['text' => $prompt],
                ]
            ]
        ]
    ]);

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $payload,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
        CURLOPT_TIMEOUT        => 120,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    $endTime = microtime(true);
    $responseTime = round($endTime - $startTime, 2);

    if ($curlError || $httpCode !== 200) {
        $reason = "Gemini error: HTTP $httpCode, cURL: $curlError, Response: " . substr($response, 0, 300);
        error_log("AI Myth Generator - " . $reason);

        // Log failed attempt
        try {
            $stmtLog = $db->prepare("
                INSERT INTO ai_usage_logs (model_used, api_key_used, response_time, status, fallback_reason)
                VALUES ('gemini-3.1-flash-lite', ?, ?, 'failed', ?)
            ");
            $stmtLog->execute([$maskedKey, $responseTime, $reason]);
        } catch (Exception $e) {
            error_log("AI Myth Generator - Log failed: " . $e->getMessage());
        }

        return null;
    }

    $data = json_decode($response, true);
    $rawText = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    $tokensUsed = $data['usageMetadata']['totalTokenCount'] ?? 0;

    $parsed = parseMythResponse($rawText);
    if ($parsed !== null) {
        $parsed['ai_provider'] = 'Gemini';

        // Log success
        try {
            $stmtLog = $db->prepare("
                INSERT INTO ai_usage_logs (model_used, api_key_used, tokens_used, response_time, status)
                VALUES ('gemini-3.1-flash-lite', ?, ?, ?, 'success')
            ");
            $stmtLog->execute([$maskedKey, $tokensUsed, $responseTime]);
        } catch (Exception $e) {
            error_log("AI Myth Generator - Log failed: " . $e->getMessage());
        }
    } else {
        $reason = "JSON parse failed. Raw: " . substr($rawText, 0, 300);

        // Log failed attempt
        try {
            $stmtLog = $db->prepare("
                INSERT INTO ai_usage_logs (model_used, api_key_used, response_time, status, fallback_reason)
                VALUES ('gemini-3.1-flash-lite', ?, ?, 'failed', ?)
            ");
            $stmtLog->execute([$maskedKey, $responseTime, $reason]);
        } catch (Exception $e) {
            error_log("AI Myth Generator - Log failed: " . $e->getMessage());
        }
    }
    return $parsed;
}

/**
 * Parse AI response text to extract myth JSON data.
 * 
 * @param string $rawText - Raw AI response
 * @return array|null - ['title', 'type', 'description']
 */
function parseMythResponse(string $rawText): ?array {
    if (empty($rawText)) {
        return null;
    }

    // Try to extract JSON from response (handle markdown code blocks)
    $jsonStr = '';
    if (preg_match('/```json\s*([\s\S]*?)\s*```/s', $rawText, $m)) {
        $jsonStr = trim($m[1]);
    } elseif (preg_match('/\{[\s\S]*\}/s', $rawText, $m)) {
        $jsonStr = trim($m[0]);
    } else {
        $jsonStr = trim($rawText);
    }

    $myth = json_decode($jsonStr, true);

    // Validate required keys
    $requiredKeys = ['title', 'type', 'description'];
    if (!is_array($myth)) {
        error_log("AI Myth Generator - JSON parse failed. Raw: " . substr($rawText, 0, 500));
        return null;
    }

    foreach ($requiredKeys as $key) {
        if (!isset($myth[$key]) || trim($myth[$key]) === '') {
            error_log("AI Myth Generator - Missing key '$key'. Raw: " . substr($rawText, 0, 500));
            return null;
        }
    }

    // Normalize type to lowercase
    $type = strtolower(trim($myth['type']));
    if ($type !== 'myth' && $type !== 'fact') {
        $type = 'myth'; // Default fallback
    }

    return [
        'title'       => trim($myth['title']),
        'type'        => $type,
        'description' => trim($myth['description']),
    ];
}

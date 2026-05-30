<?php
/**
 * Nutrition Analyzer Helper
 * Vegie App API
 * 
 * Analyzes food images using AI to extract nutrition data.
 * Priority: Ollama (local) → Gemini API (cloud fallback)
 */

// Load env config if exists
$envPath = __DIR__ . '/../env.php';
if (file_exists($envPath)) {
    $env = require $envPath;
    if (!defined('OLLAMA_BASE_URL') && isset($env['OLLAMA_BASE_URL'])) {
        define('OLLAMA_BASE_URL', $env['OLLAMA_BASE_URL']);
    }
    if (!defined('OLLAMA_MODEL') && isset($env['OLLAMA_MODEL'])) {
        define('OLLAMA_MODEL', $env['OLLAMA_MODEL']);
    }
    if (!defined('GEMINI_API_KEY') && isset($env['GEMINI_API_KEY'])) {
        define('GEMINI_API_KEY', $env['GEMINI_API_KEY']);
    }
}

// Default configuration — can be overridden by env.php
if (!defined('OLLAMA_BASE_URL')) {
    define('OLLAMA_BASE_URL', 'http://127.0.0.1:11434');
}
if (!defined('OLLAMA_MODEL')) {
    define('OLLAMA_MODEL', 'jensonodigie/Jenteck-GPT');
}
if (!defined('GEMINI_API_KEY')) {
    define('GEMINI_API_KEY', '');
}

/**
 * Analyze a food image and return nutrition data.
 * 
 * @param string $imagePath - Full path to the uploaded image file
 * @return array|null - ['food_name', 'calories', 'carbs', 'fat', 'protein'] or null on failure
 */
function analyzeNutrition($imagePath) {
    if (!file_exists($imagePath)) {
        return null;
    }

    // Compress image to base64 for AI processing
    $base64 = prepareImageForAI($imagePath);
    if (!$base64) {
        return null;
    }

    $startTime = microtime(true);

    // Try Ollama first (local), then Gemini (cloud)
    $result = analyzeWithOllama($base64);
    if ($result === null) {
        $result = analyzeWithGemini($base64);
    }

    $endTime = microtime(true);
    $responseTime = round($endTime - $startTime, 2);

    if ($result !== null) {
        $result['ai_response_time'] = $responseTime;
    }

    return $result;
}

/**
 * Compress and encode image to base64 for AI analysis
 * Uses GD Library to resize to max 800px
 * 
 * @param string $sourcePath
 * @return string|null - Base64 encoded JPEG string
 */
function prepareImageForAI($sourcePath) {
    if (!extension_loaded('gd')) {
        // Fallback: just encode the raw file
        return base64_encode(file_get_contents($sourcePath));
    }

    $info = @getimagesize($sourcePath);
    if ($info === false) {
        return null;
    }

    [$width, $height, $type] = $info;

    // Create image resource
    switch ($type) {
        case IMAGETYPE_JPEG:
            $src = @imagecreatefromjpeg($sourcePath);
            break;
        case IMAGETYPE_PNG:
            $src = @imagecreatefrompng($sourcePath);
            break;
        case IMAGETYPE_WEBP:
            $src = @imagecreatefromwebp($sourcePath);
            break;
        default:
            return base64_encode(file_get_contents($sourcePath));
    }

    if (!$src) {
        return base64_encode(file_get_contents($sourcePath));
    }

    // Resize if needed (max 800px)
    $maxSide = 800;
    $ratio = $maxSide / max($width, $height);
    if ($ratio < 1) {
        $newW = (int)($width * $ratio);
        $newH = (int)($height * $ratio);

        $dst = imagecreatetruecolor($newW, $newH);
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $newW, $newH, $width, $height);
        imagedestroy($src);
        $src = $dst;
    }

    // Encode to JPEG in memory
    ob_start();
    imagejpeg($src, null, 85);
    $imageData = ob_get_clean();
    imagedestroy($src);

    return base64_encode($imageData);
}

/**
 * Analyze food image using Ollama (local AI)
 * 
 * @param string $base64 - Base64 encoded image
 * @return array|null
 */
function analyzeWithOllama($base64) {
    $endpoint = rtrim(OLLAMA_BASE_URL, '/') . '/api/generate';

    $prompt = 'You are a nutrition analysis API. Identify the food in this image. '
        . 'Return ONLY a valid raw JSON object with exactly these keys: '
        . '"nama_makanan", "kalori", "karbohidrat", "lemak", "protein". '
        . 'Nutrition values for "karbohidrat", "lemak", "protein" must be numbers in grams (float). '
        . '"kalori" must be a number in kcal (float). '
        . 'Do not include markdown, explanations, or extra text.';

    $payload = json_encode([
        'model'  => OLLAMA_MODEL,
        'prompt' => $prompt,
        'images' => [$base64],
        'stream' => false,
    ]);

    $ch = curl_init($endpoint);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $payload,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
        CURLOPT_TIMEOUT        => 120,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError || $httpCode !== 200) {
        error_log("Ollama error: HTTP $httpCode, cURL: $curlError");
        return null;
    }

    $data = json_decode($response, true);
    $rawText = $data['response'] ?? '';

    $parsed = parseNutritionResponse($rawText);
    if ($parsed !== null) {
        $parsed['ai_provider'] = 'Ollama';
        $parsed['raw_response'] = $rawText;
    }
    return $parsed;
}

/**
 * Analyze food image using Google Gemini API (cloud fallback)
 * 
 * @param string $base64 - Base64 encoded image
 * @return array|null
 */
function analyzeWithGemini($base64) {
    if (empty(GEMINI_API_KEY)) {
        error_log("Gemini API key not configured");
        return null;
    }

    $url = "https://generativelanguage.googleapis.com/v1beta/models/gemma-4-31b-it:generateContent?key=" . GEMINI_API_KEY;

    $prompt = 'You are a nutrition analysis API. Identify the food in this image. '
        . 'Return ONLY a valid raw JSON object with exactly these keys: '
        . '"nama_makanan", "kalori", "karbohidrat", "lemak", "protein". '
        . 'Nutrition values for "karbohidrat", "lemak", "protein" must be numbers in grams (float). '
        . '"kalori" must be a number in kcal (float). '
        . 'Do not include markdown, explanations, or extra text.';

    $payload = json_encode([
        'contents' => [
            [
                'parts' => [
                    ['text' => $prompt],
                    ['inlineData' => ['mimeType' => 'image/jpeg', 'data' => $base64]],
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

    if ($curlError || $httpCode !== 200) {
        error_log("Gemini error: HTTP $httpCode, cURL: $curlError, Response: " . substr($response, 0, 300));
        return null;
    }

    $data = json_decode($response, true);
    $rawText = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';

    $parsed = parseNutritionResponse($rawText);
    if ($parsed !== null) {
        $parsed['ai_provider'] = 'API';
        $parsed['raw_response'] = $rawText;
    }
    return $parsed;
}

/**
 * Parse AI response text to extract nutrition JSON
 * 
 * @param string $rawText - Raw AI response text
 * @return array|null - ['food_name', 'calories', 'carbs', 'fat', 'protein']
 */
function parseNutritionResponse($rawText) {
    if (empty($rawText)) {
        return null;
    }

    // Try to extract JSON from response
    $jsonStr = '';
    if (preg_match('/```json\s*([\s\S]*?)\s*```/s', $rawText, $m)) {
        $jsonStr = trim($m[1]);
    } elseif (preg_match('/\{[\s\S]*\}/s', $rawText, $m)) {
        $jsonStr = trim($m[0]);
    } else {
        $jsonStr = trim($rawText);
    }

    $nutrition = json_decode($jsonStr, true);

    if (!is_array($nutrition) || !isset($nutrition['karbohidrat'], $nutrition['lemak'], $nutrition['protein'])) {
        error_log("AI nutrition parse failed. Raw: " . substr($rawText, 0, 300));
        return null;
    }

    $carbsVal = floatval($nutrition['karbohidrat']);
    $fatVal = floatval($nutrition['lemak']);
    $proteinVal = floatval($nutrition['protein']);
    $caloriesVal = isset($nutrition['kalori']) 
        ? floatval($nutrition['kalori']) 
        : ($carbsVal * 4 + $fatVal * 9 + $proteinVal * 4);

    return [
        'food_name' => $nutrition['nama_makanan'] ?? 'Tidak Dikenali',
        'calories'  => $caloriesVal,
        'carbs'     => $carbsVal,
        'fat'       => $fatVal,
        'protein'   => $proteinVal,
    ];
}

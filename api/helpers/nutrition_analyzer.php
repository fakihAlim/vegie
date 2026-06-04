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
require_once __DIR__ . '/ai_key_manager.php';

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
/**
 * Analyze a food image and return nutrition data.
 * 
 * @param string $imagePath - Full path to the uploaded image file
 * @param string|null $selectedModel - Specific model to use
 * @param string $error - Error message reference
 * @param int|null $userId - Optional ID of the user triggering the request
 * @return array|null - ['food_name', 'calories', 'carbs', 'fat', 'protein'] or null on failure
 */
function analyzeNutrition($imagePath, $selectedModel = null, &$error = '', $userId = null) {
    if (!file_exists($imagePath)) {
        $error = "File gambar tidak ditemukan di path: " . $imagePath;
        return null;
    }

    // Compress image to base64 for AI processing
    $base64 = prepareImageForAI($imagePath);
    if (!$base64) {
        $error = "Gagal memproses/mengompres gambar ke Base64.";
        return null;
    }

    $db = Database::getInstance()->getConnection();

    // 1. Single Model Execution (e.g. testing from admin page)
    if ($selectedModel !== null) {
        $startTime = microtime(true);
        $modelKey = $selectedModel;
        $isGemini = (strpos($modelKey, 'gemini') !== false || strpos($modelKey, 'gemma-4') !== false);
        
        if ($modelKey === 'gemini-3.1-flash-lite' && AiKeyManager::isAdaptiveEnabled($db)) {
            // Adaptive Key Management load balancer
            $bestKey = AiKeyManager::selectBestKey($db);
            if (!$bestKey) {
                $error = "Semua API Key Gemini 3.1 mencapai limit / tidak tersedia.";
                $db->prepare("
                    INSERT INTO ai_usage_logs (user_id, model_used, status, fallback_reason, response_time)
                    VALUES (?, ?, 'failed', ?, 0)
                ")->execute([$userId, $modelKey, $error]);
                return null;
            }
            
            $keySuccess = false;
            $result = null;
            while ($bestKey) {
                $keyError = '';
                $apiKey = $bestKey['api_key'];
                $maskedKey = AiKeyManager::maskKey($apiKey);
                
                $res = analyzeWithGemini($base64, $modelKey, $keyError, $apiKey);
                $endTime = microtime(true);
                $responseTime = round($endTime - $startTime, 2);
                
                if ($res !== null) {
                    $tokens = $res['tokens_used'] ?? 0;
                    AiKeyManager::recordSuccess($db, $bestKey['id'], $tokens);
                    $db->prepare("
                        INSERT INTO ai_usage_logs (user_id, model_used, api_key_used, tokens_used, response_time, status)
                        VALUES (?, ?, ?, ?, ?, 'success')
                    ")->execute([$userId, $modelKey, $maskedKey, $tokens, $responseTime]);
                    
                    $res['ai_response_time'] = $responseTime;
                    $result = $res;
                    $keySuccess = true;
                    break;
                } else {
                    AiKeyManager::recordFailure($db, $bestKey['id'], 'temporarily_unavailable');
                    $db->prepare("
                        INSERT INTO ai_usage_logs (user_id, model_used, api_key_used, tokens_used, response_time, status, fallback_reason)
                        VALUES (?, ?, ?, 0, ?, 'fallback', ?)
                    ")->execute([$userId, $modelKey, $maskedKey, $responseTime, "Key fail: " . $keyError]);
                    
                    $error = $keyError;
                    $bestKey = AiKeyManager::selectBestKey($db); // Fetch next key
                }
            }
            
            if ($keySuccess) {
                return $result;
            } else {
                $error = "Semua API Key Gemini 3.1 gagal digunakan. Detail terakhir: " . $error;
                $db->prepare("
                    INSERT INTO ai_usage_logs (user_id, model_used, status, fallback_reason, response_time)
                    VALUES (?, ?, 'failed', ?, 0)
                ")->execute([$userId, $modelKey, $error]);
                return null;
            }
        } else {
            // Standard non-balanced call (e.g. other models or adaptive management disabled)
            if ($isGemini) {
                $apiKey = defined('GEMINI_API_KEY') && !empty(GEMINI_API_KEY) ? GEMINI_API_KEY : '';
                if (empty($apiKey)) {
                    $stmtKey = $db->query("SELECT api_key FROM ai_gemini_keys WHERE status = 'active' LIMIT 1");
                    $apiKey = $stmtKey->fetchColumn() ?: '';
                }
                
                $result = analyzeWithGemini($base64, $modelKey, $error, $apiKey);
                $endTime = microtime(true);
                $responseTime = round($endTime - $startTime, 2);
                
                if ($result !== null) {
                    $tokens = $result['tokens_used'] ?? 0;
                    $db->prepare("
                        INSERT INTO ai_usage_logs (user_id, model_used, api_key_used, tokens_used, response_time, status)
                        VALUES (?, ?, ?, ?, ?, 'success')
                    ")->execute([$userId, $modelKey, AiKeyManager::maskKey($apiKey), $tokens, $responseTime]);
                    
                    $result['ai_response_time'] = $responseTime;
                    return $result;
                } else {
                    $db->prepare("
                        INSERT INTO ai_usage_logs (user_id, model_used, api_key_used, tokens_used, response_time, status, fallback_reason)
                        VALUES (?, ?, ?, 0, ?, 'failed', ?)
                    ")->execute([$userId, $modelKey, AiKeyManager::maskKey($apiKey), $responseTime, $error]);
                    return null;
                }
            } else {
                // Ollama
                $result = analyzeWithOllama($base64, $modelKey, $error);
                $endTime = microtime(true);
                $responseTime = round($endTime - $startTime, 2);
                
                if ($result !== null) {
                    $db->prepare("
                        INSERT INTO ai_usage_logs (user_id, model_used, tokens_used, response_time, status)
                        VALUES (?, ?, 0, ?, 'success')
                    ")->execute([$userId, $modelKey, $responseTime]);
                    
                    $result['ai_response_time'] = $responseTime;
                    return $result;
                } else {
                    $db->prepare("
                        INSERT INTO ai_usage_logs (user_id, model_used, tokens_used, response_time, status, fallback_reason)
                        VALUES (?, ?, 0, ?, 'failed', ?)
                    ")->execute([$userId, $modelKey, $responseTime, $error]);
                    return null;
                }
            }
        }
    }

    // 2. Default Fallback Chain Execution
    try {
        $stmt = $db->query("SELECT * FROM ai_model_priorities WHERE is_active = 1 ORDER BY priority_order ASC");
        $activeModels = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Exception $e) {
        $activeModels = [];
    }

    // Fallback if priority table is empty/errors
    if (empty($activeModels)) {
        $activeModels = [
            ['model_key' => 'jensonodigie/Jenteck-GPT:latest', 'model_name' => 'Jenteck-GPT Latest (Ollama)'],
            ['model_key' => 'gemini-3.1-flash-lite', 'model_name' => 'Gemini 3.1 Flash Lite']
        ];
    }

    $result = null;
    $fallbackReasons = [];

    foreach ($activeModels as $modelObj) {
        $modelKey = $modelObj['model_key'];
        $modelName = $modelObj['model_name'];
        $modelError = '';
        $startTime = microtime(true);
        
        $isGemini = (strpos($modelKey, 'gemini') !== false || strpos($modelKey, 'gemma-4') !== false);
        
        if ($modelKey === 'gemini-3.1-flash-lite' && AiKeyManager::isAdaptiveEnabled($db)) {
            // Check keys with load balancer
            $keysList = [];
            $bestKey = AiKeyManager::selectBestKey($db, $keysList);
            
            if (!$bestKey) {
                $modelError = "Semua API Key Gemini 3.1 mencapai limit atau tidak tersedia.";
                $fallbackReasons[] = "$modelName: $modelError";
                
                $db->prepare("
                    INSERT INTO ai_usage_logs (user_id, model_used, status, fallback_reason, response_time)
                    VALUES (?, ?, 'fallback', ?, 0)
                ")->execute([$userId, $modelKey, $modelError]);
                continue;
            }
            
            $keySuccess = false;
            while ($bestKey) {
                $keyError = '';
                $apiKey = $bestKey['api_key'];
                $maskedKey = AiKeyManager::maskKey($apiKey);
                
                $res = analyzeWithGemini($base64, $modelKey, $keyError, $apiKey);
                $endTime = microtime(true);
                $respTime = round($endTime - $startTime, 2);
                
                if ($res !== null) {
                    $tokens = $res['tokens_used'] ?? 0;
                    AiKeyManager::recordSuccess($db, $bestKey['id'], $tokens);
                    
                    $db->prepare("
                        INSERT INTO ai_usage_logs (user_id, model_used, api_key_used, tokens_used, response_time, status)
                        VALUES (?, ?, ?, ?, ?, 'success')
                    ")->execute([$userId, $modelKey, $maskedKey, $tokens, $respTime]);
                    
                    $res['ai_response_time'] = $respTime;
                    $result = $res;
                    $keySuccess = true;
                    break;
                } else {
                    AiKeyManager::recordFailure($db, $bestKey['id'], 'temporarily_unavailable');
                    
                    $db->prepare("
                        INSERT INTO ai_usage_logs (user_id, model_used, api_key_used, tokens_used, response_time, status, fallback_reason)
                        VALUES (?, ?, ?, 0, ?, 'fallback', ?)
                    ")->execute([$userId, $modelKey, $maskedKey, $respTime, "Key fail: " . $keyError]);
                    
                    $modelError = $keyError;
                    $bestKey = AiKeyManager::selectBestKey($db); // fetch next key
                }
            }
            
            if ($keySuccess) {
                break;
            } else {
                $fallbackReasons[] = "$modelName: $modelError";
                continue;
            }
        }
        
        // Standard execution for other models (or Gemini 3.1 with balancer disabled)
        if ($isGemini) {
            $apiKey = defined('GEMINI_API_KEY') && !empty(GEMINI_API_KEY) ? GEMINI_API_KEY : '';
            if (empty($apiKey)) {
                $stmtKey = $db->query("SELECT api_key FROM ai_gemini_keys WHERE status = 'active' LIMIT 1");
                $apiKey = $stmtKey->fetchColumn() ?: '';
            }
            
            $res = analyzeWithGemini($base64, $modelKey, $modelError, $apiKey);
            $endTime = microtime(true);
            $respTime = round($endTime - $startTime, 2);
            
            if ($res !== null) {
                $tokens = $res['tokens_used'] ?? 0;
                $db->prepare("
                    INSERT INTO ai_usage_logs (user_id, model_used, api_key_used, tokens_used, response_time, status)
                    VALUES (?, ?, ?, ?, ?, 'success')
                ")->execute([$userId, $modelKey, AiKeyManager::maskKey($apiKey), $tokens, $respTime]);
                
                $res['ai_response_time'] = $respTime;
                $result = $res;
                break;
            } else {
                $db->prepare("
                    INSERT INTO ai_usage_logs (user_id, model_used, api_key_used, tokens_used, response_time, status, fallback_reason)
                    VALUES (?, ?, ?, 0, ?, 'fallback', ?)
                ")->execute([$userId, $modelKey, AiKeyManager::maskKey($apiKey), $respTime, $modelError]);
                
                $fallbackReasons[] = "$modelName: $modelError";
            }
        } else {
            // Ollama
            $res = analyzeWithOllama($base64, $modelKey, $modelError);
            $endTime = microtime(true);
            $respTime = round($endTime - $startTime, 2);
            
            if ($res !== null) {
                $db->prepare("
                    INSERT INTO ai_usage_logs (user_id, model_used, tokens_used, response_time, status)
                    VALUES (?, ?, 0, ?, 'success')
                ")->execute([$userId, $modelKey, $respTime]);
                
                $res['ai_response_time'] = $respTime;
                $result = $res;
                break;
            } else {
                $db->prepare("
                    INSERT INTO ai_usage_logs (user_id, model_used, tokens_used, response_time, status, fallback_reason)
                    VALUES (?, ?, 0, ?, 'fallback', ?)
                ")->execute([$userId, $modelKey, $respTime, $modelError]);
                
                $fallbackReasons[] = "$modelName: $modelError";
            }
        }
    }

    if ($result === null) {
        $finalReason = implode(" | ", $fallbackReasons);
        $error = $finalReason;
        
        $db->prepare("
            INSERT INTO ai_usage_logs (user_id, model_used, status, fallback_reason)
            VALUES (?, 'ALL_MODELS', 'failed', ?)
        ")->execute([$userId, $finalReason]);
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
function analyzeWithOllama($base64, $model = null, &$error = '') {
    $endpoint = rtrim(OLLAMA_BASE_URL, '/') . '/api/generate';

    // $prompt = 'You are a nutrition analysis API. Identify the food in this image. '
    //     . 'If the image contains a composite meal (a plate containing multiple distinct food items/ingredients, e.g., Gado-Gado, Nasi Rames, etc.), '
    //     . 'you MUST identify each individual food item/ingredient, calculate their individual nutrition values, and sum them up for the total. '
    //     . 'Return ONLY a valid raw JSON object with exactly these keys: '
    //     . '"nama_makanan" (string, the name of the dish, or the primary food if single item), '
    //     . '"kalori" (float, total kcal), '
    //     . '"karbohidrat" (float, total carbs in grams), '
    //     . '"lemak" (float, total fat in grams), '
    //     . '"protein" (float, total protein in grams), '
    //     . '"items" (array of objects, representing each detected food item/ingredient in the meal. Each object MUST have these keys: '
    //     . '"nama" (string, name of the item, e.g., "Tahu", "Tempe", "Saus Kacang"), '
    //     . '"kalori" (float, kcal for this item), '
    //     . '"karbohidrat" (float, carbs in grams for this item), '
    //     . '"lemak" (float, fat in grams for this item), '
    //     . '"protein" (float, protein in grams for this item)). '
    //     . 'If there is only one food item in the image (e.g., just an apple), the "items" array should still contain that single item. '
    //     . 'Do not include markdown, explanations, or extra text. Output ONLY the raw JSON object.';

    $prompt = 'You are an expert food recognition and nutrition analysis API. '
    . 'FIRST, determine if the image contains any food or beverage items (including raw ingredients, packaged food, drinks, snacks, cooked meals, etc.). '
    . 'If the image does NOT contain any food or beverage, immediately return ONLY this JSON: '
    . '{"is_food":false,"nama_makanan":"Bukan Makanan","kalori":0,"karbohidrat":0,"lemak":0,"protein":0,"items":[]} '
    . 'If the image DOES contain food or beverage, set "is_food":true and continue with analysis. '
    . 'Analyze the food image and identify all visible food items. '
    . 'Estimate the portion size of each detected food item based on its visual appearance. '
    . 'If the image contains a composite or mixed meal (e.g., Gado-Gado, Nasi Rames, Nasi Campur, Salad, Burger, Sandwich, Bento, etc.), '
    . 'you MUST identify and separate each visible ingredient or food component whenever possible. '
    . 'Calculate nutrition values for each individual item based on the estimated portion size, then sum all items to generate the total nutrition values. '
    . 'Use realistic nutritional estimates based on standard food composition databases. '
    . 'If there is only one food item in the image, the "items" array must still contain that single item. '
    . 'Return ONLY a valid raw JSON object with exactly these keys: '
    . '"is_food" (boolean, true if image contains food/beverage, false if not), '
    . '"nama_makanan" (string, name of the overall dish or meal), '
    . '"kalori" (float, total kcal), '
    . '"karbohidrat" (float, total carbohydrates in grams), '
    . '"lemak" (float, total fat in grams), '
    . '"protein" (float, total protein in grams), '
    . '"items" (array of objects representing each detected food item. Each object MUST contain these keys: '
    . '"nama" (string, food item name), '
    . '"berat_gram" (float, estimated weight in grams), '
    . '"kalori" (float, kcal for this item), '
    . '"karbohidrat" (float, carbohydrates in grams for this item), '
    . '"lemak" (float, fat in grams for this item), '
    . '"protein" (float, protein in grams for this item)). '
    . 'All numeric values must be returned as floats. '
    . 'Do not use null values; use 0 if a value cannot be estimated. '
    . 'The total values for kalori, karbohidrat, lemak, and protein MUST equal the sum of all values in the items array. '
    . 'If the food cannot be identified with reasonable confidence, return: '
    . '{"is_food":true,"nama_makanan":"Tidak Diketahui","kalori":0,"karbohidrat":0,"lemak":0,"protein":0,"items":[]} '
    . 'Do not include markdown, explanations, comments, code fences, or extra text. '
    . 'Output ONLY the raw JSON object.';

    $payload = json_encode([
        'model'  => $model ?? OLLAMA_MODEL,
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
        $error = "Ollama error: HTTP $httpCode, cURL: $curlError. Response: " . substr(strval($response), 0, 300);
        error_log($error);
        return null;
    }

    $data = json_decode($response, true);
    $rawText = $data['response'] ?? '';

    $parsed = parseNutritionResponse($rawText);
    if ($parsed === null) {
        $error = "Ollama JSON parse error. Raw response: " . substr($rawText, 0, 300);
        return null;
    }
    if ($parsed !== null) {
        $parsed['ai_provider'] = 'Ollama (' . ($model ?? OLLAMA_MODEL) . ')';
        $parsed['raw_response'] = json_encode($parsed);
    }
    return $parsed;
}

/**
 * Analyze food image using Google Gemini API (cloud fallback)
 * 
 * @param string $base64 - Base64 encoded image
 * @return array|null
 */
/**
 * Analyze food image using Google Gemini API (cloud fallback)
 * 
 * @param string $base64 - Base64 encoded image
 * @param string $model - Model identifier
 * @param string $error - Error reference
 * @param string|null $apiKey - Explicit API key to use
 * @return array|null
 */
function analyzeWithGemini($base64, $model = 'gemini-3.1-flash-lite', &$error = '', $apiKey = null) {
    $activeKey = $apiKey ?: (defined('GEMINI_API_KEY') ? GEMINI_API_KEY : '');
    if (empty($activeKey)) {
        $error = "Gemini API key not configured";
        error_log($error);
        return null;
    }
    
    $url = "https://generativelanguage.googleapis.com/v1beta/models/" . $model . ":generateContent?key=" . $activeKey;
    
    $prompt = 'You are an expert food recognition and nutrition analysis API. '
    . 'FIRST, determine if the image contains any food or beverage items (including raw ingredients, packaged food, drinks, snacks, cooked meals, etc.). '
    . 'If the image does NOT contain any food or beverage, immediately return ONLY this JSON: '
    . '{"is_food":false,"nama_makanan":"Bukan Makanan","kalori":0,"karbohidrat":0,"lemak":0,"protein":0,"items":[]} '
    . 'If the image DOES contain food or beverage, set "is_food":true and continue with analysis. '
    . 'Analyze the food image and identify all visible food items. '
    . 'Estimate the portion size of each detected food item based on its visual appearance. '
    . 'If the image contains a composite or mixed meal (e.g., Gado-Gado, Nasi Rames, Nasi Campur, Salad, Burger, Sandwich, Bento, etc.), '
    . 'you MUST identify and separate each visible ingredient or food component whenever possible. '
    . 'Calculate nutrition values for each individual item based on the estimated portion size, then sum all items to generate the total nutrition values. '
    . 'Use realistic nutritional estimates based on standard food composition databases. '
    . 'If there is only one food item in the image, the "items" array must still contain that single item. '
    . 'Return ONLY a valid raw JSON object with exactly these keys: '
    . '"is_food" (boolean, true if image contains food/beverage, false if not), '
    . '"nama_makanan" (string, name of the overall dish or meal), '
    . '"kalori" (float, total kcal), '
    . '"karbohidrat" (float, total carbohydrates in grams), '
    . '"lemak" (float, total fat in grams), '
    . '"protein" (float, total protein in grams), '
    . '"items" (array of objects representing each detected food item. Each object MUST contain these keys: '
    . '"nama" (string, food item name), '
    . '"berat_gram" (float, estimated weight in grams), '
    . '"kalori" (float, kcal for this item), '
    . '"karbohidrat" (float, carbohydrates in grams for this item), '
    . '"lemak" (float, fat in grams for this item), '
    . '"protein" (float, protein in grams for this item)). '
    . 'All numeric values must be returned as floats. '
    . 'Do not use null values; use 0 if a value cannot be estimated. '
    . 'The total values for kalori, karbohidrat, lemak, and protein MUST equal the sum of all values in the items array. '
    . 'If the food cannot be identified with reasonable confidence, return: '
    . '{"is_food":true,"nama_makanan":"Tidak Diketahui","kalori":0,"karbohidrat":0,"lemak":0,"protein":0,"items":[]} '
    . 'Do not include markdown, explanations, comments, code fences, or extra text. '
    . 'Output ONLY the raw JSON object.';

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
        $error = "Gemini error: HTTP $httpCode, cURL: $curlError. Response: " . substr(strval($response), 0, 300);
        error_log($error);
        return null;
    }

    $data = json_decode($response, true);
    $rawText = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    
    if (empty($rawText)) {
        $error = "Gemini returned empty text response. JSON response: " . substr(strval($response), 0, 300);
        return null;
    }

    $parsed = parseNutritionResponse($rawText);
    if ($parsed === null) {
        $error = "Gemini JSON parse error. Raw response text: " . substr($rawText, 0, 300);
        return null;
    }
    
    // Extract tokens from Gemini API metadata
    $tokensUsed = $data['usageMetadata']['totalTokenCount'] ?? 0;
    
    if ($parsed !== null) {
        $parsed['ai_provider'] = 'Gemini (' . $model . ')';
        $parsed['raw_response'] = json_encode($parsed);
        $parsed['tokens_used'] = $tokensUsed;
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

    // Check if the image is food. Default to true if key is not present (backward compat).
    $isFood = isset($nutrition['is_food']) ? (bool)$nutrition['is_food'] : true;

    // If AI determined this is not food, return early with the flag
    if (!$isFood) {
        return [
            'is_food'   => false,
            'food_name' => 'Bukan Makanan',
            'calories'  => 0,
            'carbs'     => 0,
            'fat'       => 0,
            'protein'   => 0,
            'items'     => []
        ];
    }

    $carbsVal = floatval($nutrition['karbohidrat']);
    $fatVal = floatval($nutrition['lemak']);
    $proteinVal = floatval($nutrition['protein']);
    $caloriesVal = isset($nutrition['kalori']) 
        ? floatval($nutrition['kalori']) 
        : ($carbsVal * 4 + $fatVal * 9 + $proteinVal * 4);

    $items = [];
    if (isset($nutrition['items']) && is_array($nutrition['items'])) {
        foreach ($nutrition['items'] as $item) {
            if (isset($item['nama'])) {
                $iCarbs = isset($item['karbohidrat']) ? floatval($item['karbohidrat']) : 0.0;
                $iFat = isset($item['lemak']) ? floatval($item['lemak']) : 0.0;
                $iProtein = isset($item['protein']) ? floatval($item['protein']) : 0.0;
                $iCal = isset($item['kalori']) ? floatval($item['kalori']) : ($iCarbs * 4 + $iFat * 9 + $iProtein * 4);
                
                $items[] = [
                    'nama' => strval($item['nama']),
                    'kalori' => $iCal,
                    'karbohidrat' => $iCarbs,
                    'lemak' => $iFat,
                    'protein' => $iProtein
                ];
            }
        }
    }

    return [
        'is_food'   => true,
        'food_name' => $nutrition['nama_makanan'] ?? 'Tidak Dikenali',
        'calories'  => $caloriesVal,
        'carbs'     => $carbsVal,
        'fat'       => $fatVal,
        'protein'   => $proteinVal,
        'items'     => $items
    ];
}

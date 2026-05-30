<?php
/**
 * AI Quiz Generator Helper
 * Vegie App API
 * 
 * Generates plant-based nutrition quiz questions using AI.
 * Priority: Ollama (local) → Gemini API (cloud fallback)
 */

// Load env config if exists (same pattern as nutrition_analyzer.php)
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
 * The quiz generation prompt (reusable across providers)
 */
function getQuizPrompt(): string {
    return 'Kamu adalah ahli gizi dan edukator diet plant-based. '
        . 'Buatkan 1 pertanyaan kuis pilihan ganda tentang manfaat gizi, fakta menarik, atau mitos seputar diet plant-based dan makanan nabati. '
        . 'Pertanyaan harus dalam Bahasa Indonesia dan edukatif. '
        . 'Kembalikan HANYA dalam format JSON mentah (tanpa markdown, tanpa penjelasan tambahan) dengan key berikut: '
        . '"question" (string), "option_a" (string), "option_b" (string), "option_c" (string), "option_d" (string), '
        . '"correct_answer" (salah satu dari: "a", "b", "c", "d"), "explanation" (string penjelasan singkat mengapa jawaban tersebut benar).';
}

/**
 * Generate a plant-based quiz question using AI.
 * Priority: Ollama (local) → Gemini (cloud fallback).
 * 
 * @return array|null - Quiz data array or null on failure
 */
function generatePlantBasedQuiz(): ?array {
    $prompt = getQuizPrompt();

    // Try Ollama first (local AI)
    $result = generateQuizWithOllama($prompt);
    if ($result !== null) {
        return $result;
    }

    // Fallback to Gemini (cloud AI)
    $result = generateQuizWithGemini($prompt);
    return $result;
}

/**
 * Generate quiz using Ollama (local AI) — Primary
 * 
 * @param string $prompt
 * @return array|null
 */
function generateQuizWithOllama(string $prompt): ?array {
    $endpoint = rtrim(OLLAMA_BASE_URL, '/') . '/api/generate';

    $payload = json_encode([
        'model'  => OLLAMA_MODEL,
        'prompt' => $prompt,
        'stream' => false,
    ]);

    $ch = curl_init($endpoint);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $payload,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
        CURLOPT_TIMEOUT        => 120,
        CURLOPT_CONNECTTIMEOUT => 5,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError || $httpCode !== 200) {
        error_log("AI Quiz Generator - Ollama error: HTTP $httpCode, cURL: $curlError");
        return null;
    }

    $data = json_decode($response, true);
    $rawText = $data['response'] ?? '';

    $parsed = parseQuizResponse($rawText);
    if ($parsed !== null) {
        $parsed['ai_provider'] = 'Ollama';
    }
    return $parsed;
}

/**
 * Generate quiz using Gemini API (cloud) — Fallback
 * 
 * @param string $prompt
 * @return array|null
 */
function generateQuizWithGemini(string $prompt): ?array {
    if (empty(GEMINI_API_KEY)) {
        error_log("AI Quiz Generator - Gemini API key not configured");
        return null;
    }

    $url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" . GEMINI_API_KEY;

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

    if ($curlError || $httpCode !== 200) {
        error_log("AI Quiz Generator - Gemini error: HTTP $httpCode, cURL: $curlError, Response: " . substr($response, 0, 300));
        return null;
    }

    $data = json_decode($response, true);
    $rawText = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';

    $parsed = parseQuizResponse($rawText);
    if ($parsed !== null) {
        $parsed['ai_provider'] = 'Gemini';
    }
    return $parsed;
}

/**
 * Parse AI response text to extract quiz JSON data.
 * 
 * @param string $rawText - Raw AI response
 * @return array|null - ['question', 'option_a', 'option_b', 'option_c', 'option_d', 'correct_answer', 'explanation']
 */
function parseQuizResponse(string $rawText): ?array {
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

    $quiz = json_decode($jsonStr, true);

    // Validate required keys
    $requiredKeys = ['question', 'option_a', 'option_b', 'option_c', 'option_d', 'correct_answer'];
    if (!is_array($quiz)) {
        error_log("AI Quiz Generator - JSON parse failed. Raw: " . substr($rawText, 0, 500));
        return null;
    }

    foreach ($requiredKeys as $key) {
        if (!isset($quiz[$key]) || trim($quiz[$key]) === '') {
            error_log("AI Quiz Generator - Missing key '$key'. Raw: " . substr($rawText, 0, 500));
            return null;
        }
    }

    // Normalize correct_answer to lowercase single letter
    $correctAnswer = strtolower(trim($quiz['correct_answer']));
    if (!in_array($correctAnswer, ['a', 'b', 'c', 'd'])) {
        error_log("AI Quiz Generator - Invalid correct_answer: '$correctAnswer'");
        return null;
    }

    return [
        'question'       => trim($quiz['question']),
        'option_a'       => trim($quiz['option_a']),
        'option_b'       => trim($quiz['option_b']),
        'option_c'       => trim($quiz['option_c']),
        'option_d'       => trim($quiz['option_d']),
        'correct_answer' => $correctAnswer,
        'explanation'    => trim($quiz['explanation'] ?? ''),
    ];
}

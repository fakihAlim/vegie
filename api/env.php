<?php
/**
 * Environment Configuration
 * 
 * Generated for Vegie App API.
 */

return [
    'DB_HOST' => 'localhost',
    'DB_NAME' => 'lovingharmony',
    'DB_USER' => 'root',
    'DB_PASS' => '',
    'DB_CHARSET' => 'utf8mb4',

    // AI Nutrition Analyzer Configuration
    // Ollama (Local AI) — Primary
    'OLLAMA_BASE_URL' => 'http://127.0.0.1:11434',
    'OLLAMA_MODEL'    => 'jensonodigie/Jenteck-GPT',

    // Gemini API (Cloud) — Fallback
    'GEMINI_API_KEY'  => 'AIzaSyBHdbSwWekBvO005CpF9a9mZn1-Q7FzZLA',
];

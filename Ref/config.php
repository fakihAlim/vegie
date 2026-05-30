<?php
/**
 * Konfigurasi Global untuk Food Nutrition Analyzer
 * 
 * PENTING: Amankan file ini dan jangan commit ke repositori publik (seperti GitHub).
 * Tambahkan 'config.php' ke dalam file .gitignore Anda.
 */

// API Key untuk Google Gemini (Digunakan jika memakai model Cloud)
define('GEMINI_API_KEY', 'AIzaSyBHdbSwWekBvO005CpF9a9mZn1-Q7FzZLA');

// Konfigurasi untuk Ollama (Digunakan jika memakai model Lokal)
define('OLLAMA_BASE_URL', 'http://127.0.0.1:11434');
define('OLLAMA_MODEL', 'jensonodigie/Jenteck-GPT');

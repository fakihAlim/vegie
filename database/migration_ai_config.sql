-- ============================================
-- Migration: Add AI configurations, model fallback chain, and logging
-- ============================================

USE lovingharmony;

-- 1. Table for General AI Settings
CREATE TABLE IF NOT EXISTS ai_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value TEXT DEFAULT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Seed default adaptive key management flag (enabled by default)
INSERT INTO ai_settings (setting_key, setting_value) 
VALUES ('adaptive_key_management', '1')
ON DUPLICATE KEY UPDATE setting_value = '1';

-- 2. Table for AI Model Priorities
CREATE TABLE IF NOT EXISTS ai_model_priorities (
    id INT PRIMARY KEY AUTO_INCREMENT,
    model_key VARCHAR(100) UNIQUE NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    priority_order INT NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Seed default priority chain
INSERT INTO ai_model_priorities (model_key, model_name, priority_order, is_active) VALUES
('gemini-3.1-flash-lite', 'Gemini 3.1 Flash Lite', 1, 1),
('gemini-3-flash-preview', 'Gemini 3 Flash Preview', 2, 1),
('gemini-2.5-flash', 'Gemini 2.5 Flash', 3, 1),
('jensonodigie/Jenteck-GPT:latest', 'Jenteck-GPT Latest (Ollama)', 4, 1),
('gemma-4-31b', 'Gemma 4 31B (Ollama)', 5, 1)
ON DUPLICATE KEY UPDATE 
    model_name = VALUES(model_name),
    priority_order = VALUES(priority_order),
    is_active = VALUES(is_active);

-- 3. Table for Adaptive Gemini API Keys
CREATE TABLE IF NOT EXISTS ai_gemini_keys (
    id INT PRIMARY KEY AUTO_INCREMENT,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    status ENUM('active', 'near_limit', 'blocked', 'temporarily_unavailable') DEFAULT 'active',
    rpm_limit INT DEFAULT 15,
    tpm_limit INT DEFAULT 250000,
    rpd_limit INT DEFAULT 500,
    rpm_usage INT DEFAULT 0,
    tpm_usage INT DEFAULT 0,
    rpd_usage INT DEFAULT 0,
    last_used_at TIMESTAMP NULL DEFAULT NULL,
    total_requests_today INT DEFAULT 0,
    rpm_window_start TIMESTAMP NULL DEFAULT NULL,
    tpm_window_start TIMESTAMP NULL DEFAULT NULL,
    rpd_window_start DATE NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 4. Table for AI Usage and Fallback Logs
CREATE TABLE IF NOT EXISTS ai_usage_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT DEFAULT NULL,
    model_used VARCHAR(100) NOT NULL,
    api_key_used VARCHAR(255) DEFAULT NULL,
    tokens_used INT DEFAULT 0,
    response_time FLOAT DEFAULT 0.0,
    status ENUM('success', 'failed', 'fallback') NOT NULL,
    fallback_reason TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_model_used (model_used),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

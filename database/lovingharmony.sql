-- ============================================
-- LovingHarmony Database Schema
-- Vegetarian Food Logging Application
-- ============================================

CREATE DATABASE IF NOT EXISTS lovingharmony 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE lovingharmony;

-- ============================================
-- Admin Table
-- ============================================
CREATE TABLE admins (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Default admin: admin / admin123 (change in production!)
INSERT INTO admins (username, password, name) VALUES 
('admin', '$2y$10$b.nFwPOQNrmGCNiDy0cPPebi0CjyQZbCDajXcwyTep3gKJgIn1MZq', 'Super Admin');

-- ============================================
-- Users Table
-- ============================================
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    photo VARCHAR(255) DEFAULT NULL,
    bio TEXT DEFAULT NULL,
    join_date DATE NOT NULL,
    is_onboarding_completed TINYINT(1) DEFAULT 0,
    current_stage VARCHAR(50) DEFAULT NULL,
    ttm_stage ENUM('precontemplation', 'contemplation', 'preparation', 'action', 'maintenance') DEFAULT 'precontemplation',
    ttm_action_start_date DATE DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- Food Logs Table
-- ============================================
CREATE TABLE food_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    photo VARCHAR(255) DEFAULT NULL,
    food_name VARCHAR(200) NOT NULL,
    meal_time DATETIME NOT NULL,
    category ENUM('breakfast','lunch','dinner','snack') NOT NULL,
    nutrition_notes TEXT DEFAULT NULL,
    calories FLOAT DEFAULT NULL,
    carbs FLOAT DEFAULT NULL,
    fat FLOAT DEFAULT NULL,
    protein FLOAT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- News Table
-- ============================================
CREATE TABLE news (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image VARCHAR(255) DEFAULT NULL,
    is_published TINYINT(1) DEFAULT 0,
    published_at DATETIME DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- Recipes Table
-- ============================================
CREATE TABLE recipes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    photo VARCHAR(255) DEFAULT NULL,
    description TEXT DEFAULT NULL,
    calories INT DEFAULT NULL,
    prep_time_minutes INT DEFAULT NULL,
    is_published TINYINT(1) DEFAULT 0,
    published_at DATETIME DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- Recipe Ingredients Table
-- ============================================
CREATE TABLE recipe_ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recipe_id INT NOT NULL,
    ingredient VARCHAR(255) NOT NULL,
    amount VARCHAR(100) DEFAULT NULL,
    sort_order INT DEFAULT 0,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Recipe Steps Table
-- ============================================
CREATE TABLE recipe_steps (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recipe_id INT NOT NULL,
    step_number INT NOT NULL,
    description TEXT NOT NULL,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Groups Table
-- ============================================
CREATE TABLE groups_tbl (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT DEFAULT NULL,
    code VARCHAR(8) UNIQUE NOT NULL,
    created_by INT NOT NULL,
    photo VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Group Members Table
-- ============================================
CREATE TABLE group_members (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('admin','member') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_membership (group_id, user_id),
    FOREIGN KEY (group_id) REFERENCES groups_tbl(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Group Posts Table
-- ============================================
CREATE TABLE group_posts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    type ENUM('text','achievement','quote') DEFAULT 'text',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups_tbl(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- FCM Tokens Table
-- ============================================
CREATE TABLE user_fcm_tokens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    token TEXT NOT NULL,
    device_info VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Notifications Log Table
-- ============================================
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type ENUM('news','recipe','group','system') NOT NULL,
    reference_id INT DEFAULT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- Daily Quotes Table
-- ============================================
CREATE TABLE daily_quotes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    quote_text TEXT NOT NULL,
    author VARCHAR(150) DEFAULT 'Anonim',
    display_date DATE DEFAULT NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Sample quotes (campuran Indonesia & Inggris)
INSERT INTO daily_quotes (quote_text, author, is_active) VALUES
('Makanan yang baik adalah fondasi dari kebahagiaan sejati.', 'Auguste Escoffier', 1),
('The greatest wealth is health.', 'Virgil', 1),
('Tubuhmu adalah kuil. Rawatlah dengan makanan yang penuh kasih.', 'Anonim', 1),
('Let food be thy medicine and medicine be thy food.', 'Hippocrates', 1),
('Setiap gigitan makanan nabati adalah tindakan cinta untuk bumi.', 'Anonim', 1),
('You are what you eat, so don''t be fast, cheap, easy, or fake.', 'Anonim', 1),
('Hidup sehat dimulai dari piring makan kita.', 'Anonim', 1),
('The food you eat can be either the safest and most powerful form of medicine or the slowest form of poison.', 'Ann Wigmore', 1),
('Sayur dan buah adalah hadiah terbaik dari alam.', 'Anonim', 1),
('Take care of your body. It''s the only place you have to live.', 'Jim Rohn', 1);

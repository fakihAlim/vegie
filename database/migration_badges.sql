-- ============================================
-- Migration: Badges System
-- Vegie / LovingHarmony App
-- ============================================

-- 1. Master badge catalog
CREATE TABLE IF NOT EXISTS badges (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    code        VARCHAR(50) UNIQUE NOT NULL COMMENT 'Unique machine key, e.g. explorer',
    name        VARCHAR(100) NOT NULL,
    description TEXT DEFAULT NULL,
    lottie_file VARCHAR(255) DEFAULT NULL COMMENT 'Path relatif ke file JSON Lottie',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Seed master badges (idempotent via INSERT IGNORE)
INSERT IGNORE INTO badges (code, name, description, lottie_file) VALUES
('first_step',  'Langkah Pertama',    'Berhasil mencatat makanan pertama kali.',                        'assets/lottie/flower.json'),
('explorer',    'Sang Penjelajah',    'Membaca 3 artikel berita kesehatan.',                            'assets/lottie/flower (1).json'),
('streak_7',    'Pejuang Konsisten',  'Mencatat makanan selama 7 hari berturut-turut.',                 'assets/lottie/flower (2).json'),
('plant_lover', 'Pecinta Nabati',     'Mencatat 10 log makanan nabati (mendapat +50 poin).',           'assets/lottie/flower (3).json'),
('quiz_ace',    'Juara Kuis',         'Menjawab benar 5 soal kuis secara kumulatif.',                  'assets/lottie/flower (4).json');


-- 2. User–Badge relationship (many-to-many)
CREATE TABLE IF NOT EXISTS user_badges (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    user_id    INT NOT NULL,
    badge_id   INT NOT NULL,
    awarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_user_badge (user_id, badge_id),
    FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Migration: Quiz Feature & Notification Deep Linking
-- Vegie App - LovingHarmony Database
-- Run: mysql -u root lovingharmony < migration_quiz_notification.sql
-- ============================================

-- 1. Create Quizzes Table
CREATE TABLE IF NOT EXISTS quizzes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question TEXT NOT NULL,
    option_a VARCHAR(255) NOT NULL,
    option_b VARCHAR(255) NOT NULL,
    option_c VARCHAR(255) NOT NULL,
    option_d VARCHAR(255) NOT NULL,
    correct_answer ENUM('a','b','c','d') NOT NULL,
    explanation TEXT DEFAULT NULL,
    points INT DEFAULT 50,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Create User Quizzes (Answer Log) Table
CREATE TABLE IF NOT EXISTS user_quizzes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    quiz_id INT NOT NULL,
    is_correct TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 3. Update Notifications table: add 'quiz' to type ENUM
ALTER TABLE notifications 
  MODIFY COLUMN type ENUM('news','recipe','group','system','quiz') NOT NULL;

-- 4. Sample Quiz Data (Plant-Based Nutrition)
INSERT INTO quizzes (question, option_a, option_b, option_c, option_d, correct_answer, explanation, points, is_active) VALUES
(
    'Manakah sumber protein nabati yang memiliki kandungan protein tertinggi per 100 gram?',
    'Tahu',
    'Tempe',
    'Kacang kedelai kering',
    'Kacang merah',
    'c',
    'Kacang kedelai kering mengandung sekitar 36g protein per 100g, menjadikannya sumber protein nabati tertinggi dibandingkan olahan turunannya.',
    50,
    1
),
(
    'Vitamin apa yang paling sulit didapatkan dari diet plant-based murni dan sering memerlukan suplemen?',
    'Vitamin C',
    'Vitamin B12',
    'Vitamin A',
    'Vitamin E',
    'b',
    'Vitamin B12 secara alami hanya ditemukan dalam produk hewani. Orang yang menjalani diet plant-based murni disarankan mengonsumsi suplemen B12 atau makanan yang difortifikasi.',
    50,
    1
),
(
    'Berapa persentase emisi gas rumah kaca global yang dihasilkan oleh industri peternakan menurut FAO?',
    '5%',
    '8%',
    '14.5%',
    '25%',
    'c',
    'Menurut Food and Agriculture Organization (FAO) PBB, industri peternakan menyumbang sekitar 14.5% dari total emisi gas rumah kaca global.',
    50,
    1
),
(
    'Manakah dari makanan berikut yang merupakan sumber zat besi nabati (non-heme iron) terbaik?',
    'Bayam',
    'Wortel',
    'Kentang',
    'Timun',
    'a',
    'Bayam mengandung sekitar 2.7mg zat besi per 100g. Kombinasikan dengan vitamin C untuk meningkatkan penyerapan zat besi non-heme.',
    50,
    1
),
(
    'Apa nama asam lemak omega-3 yang banyak ditemukan dalam biji chia dan biji rami (flaxseed)?',
    'EPA (Eicosapentaenoic Acid)',
    'DHA (Docosahexaenoic Acid)',
    'ALA (Alpha-Linolenic Acid)',
    'AA (Arachidonic Acid)',
    'c',
    'ALA (Alpha-Linolenic Acid) adalah jenis omega-3 yang dominan dalam sumber nabati seperti biji chia, biji rami, dan kenari. Tubuh dapat mengkonversi ALA menjadi EPA dan DHA dalam jumlah kecil.',
    50,
    1
);

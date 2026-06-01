<?php
require_once __DIR__ . '/config/database.php';

$db = Database::getInstance()->getConnection();

try {
    // 1. Create Myth vs Facts table
    $db->exec("
        CREATE TABLE IF NOT EXISTS myth_facts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            type ENUM('myth', 'fact') NOT NULL,
            description TEXT NOT NULL,
            image_url VARCHAR(255) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ");

    // Insert dummy data for Myth vs Facts if empty
    $stmt = $db->query("SELECT COUNT(*) as count FROM myth_facts");
    $row = $stmt->fetch();
    if ($row['count'] == 0) {
        $db->exec("
            INSERT INTO myth_facts (title, type, description) VALUES
            ('Protein Nabati Tidak Lengkap', 'myth', 'Faktanya, dengan mengombinasikan berbagai sumber protein nabati seperti biji-bijian, kacang-kacangan, dan sayuran, Anda bisa mendapatkan semua asam amino esensial yang dibutuhkan tubuh.'),
            ('Sayuran Hijau Kaya Zat Besi', 'fact', 'Bayam, kangkung, dan brokoli merupakan sumber zat besi yang baik. Konsumsi bersama makanan tinggi vitamin C untuk penyerapan optimal.'),
            ('Diet Vegan Pasti Kekurangan Kalsium', 'myth', 'Banyak sumber kalsium nabati seperti susu kedelai yang diperkaya, tahu, tempe, almond, dan sayuran berdaun hijau gelap yang sangat baik untuk tulang.'),
            ('Lemak Nabati Lebih Sehat', 'fact', 'Lemak tak jenuh yang ditemukan dalam alpukat, kacang-kacangan, dan minyak zaitun dapat membantu menurunkan kolesterol jahat (LDL) dan meningkatkan kesehatan jantung.')
        ");
    }

    // 2. Create Quests table
    $db->exec("
        CREATE TABLE IF NOT EXISTS quests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT NOT NULL,
            points_reward INT DEFAULT 10,
            quest_type VARCHAR(50) NOT NULL, /* e.g., 'log_food', 'share_group', 'try_recipe' */
            target_count INT DEFAULT 1,
            is_active TINYINT(1) DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ");

    // Insert dummy quests if empty
    $stmt = $db->query("SELECT COUNT(*) as count FROM quests");
    $row = $stmt->fetch();
    if ($row['count'] == 0) {
        $db->exec("
            INSERT INTO quests (title, description, points_reward, quest_type, target_count) VALUES
            ('Log Makanan 3 Kali', 'Catat sarapan, makan siang, dan makan malam kamu hari ini.', 30, 'log_food', 3),
            ('Bagikan Makanan', 'Bagikan 1 log makananmu ke grup untuk menginspirasi yang lain.', 15, 'share_group', 1),
            ('Coba Resep Baru', 'Lihat dan coba 1 resep dari menu Resep hari ini.', 20, 'try_recipe', 1)
        ");
    }

    // 3. Create User Quests table to track progress
    $db->exec("
        CREATE TABLE IF NOT EXISTS user_quests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            quest_id INT NOT NULL,
            progress_count INT DEFAULT 0,
            is_completed TINYINT(1) DEFAULT 0,
            completed_at DATETIME DEFAULT NULL,
            target_date DATE NOT NULL, /* The date this quest is active for the user */
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (quest_id) REFERENCES quests(id) ON DELETE CASCADE,
            UNIQUE KEY user_quest_date (user_id, quest_id, target_date)
        );
    ");

    echo "Database tables for Myths and Quests created successfully.\n";

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

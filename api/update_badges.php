<?php
require_once __DIR__ . '/config/database.php';

try {
    $db = Database::getInstance()->getConnection();

    $updates = [
        'first_step' => 'assets/lottie/flower.json',
        'explorer' => 'assets/lottie/flower (1).json',
        'streak_7' => 'assets/lottie/flower (2).json',
        'plant_lover' => 'assets/lottie/flower (3).json',
        'quiz_ace' => 'assets/lottie/flower (4).json',
    ];

    $stmt = $db->prepare("UPDATE badges SET lottie_file = ? WHERE code = ?");

    foreach ($updates as $code => $lottieFile) {
        $stmt->execute([$lottieFile, $code]);
        echo "Updated badge '$code' to use Lottie file '$lottieFile'.\n";
    }

    echo "\nAll badges updated successfully in MySQL database.\n";
} catch (Exception $e) {
    echo "Error updating badges: " . $e->getMessage() . "\n";
}

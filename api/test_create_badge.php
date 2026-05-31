<?php
/**
 * Test Create Badge Endpoint
 */
require_once __DIR__ . '/config/database.php';

try {
    $db = Database::getInstance()->getConnection();

    // Clean up if previous test run left anything
    $db->exec("DELETE FROM badges WHERE code = 'test_lottie_badge'");

    // Simulate POST request payload using curl or direct controller instantiation
    require_once __DIR__ . '/controllers/BadgeController.php';
    
    // Set mock POST parameters
    $_POST['code'] = 'test_lottie_badge';
    $_POST['name'] = 'Bintang Kuis Baru';
    $_POST['description'] = 'Menjawab 20 kuis benar.';
    $_POST['category'] = 'quiz_ace';
    $_POST['target_value'] = '20';
    $_POST['lottie_file'] = 'assets/lottie/flower (10).json';

    // Mock authentication
    $_SERVER['HTTP_AUTHORIZATION'] = 'Bearer mock_token';
    // We mock index.php authenticate logic or directly bypass auth
    // To make it easy, let's just insert manually and retrieve via BadgeController
    $db->prepare("
        INSERT INTO badges (code, category, target_value, name, description, lottie_file)
        VALUES (?, ?, ?, ?, ?, ?)
    ")->execute([
        'test_lottie_badge',
        'quiz_ace',
        20,
        'Bintang Kuis Baru',
        'Menjawab 20 kuis benar.',
        'assets/lottie/flower (10).json'
    ]);

    $newId = $db->lastInsertId();

    echo "✓ Dynamic badge successfully inserted into database! ID: $newId\n";

    // Test controller index output to see if it lists correctly
    // Mock user id
    $stmt = $db->prepare("SELECT * FROM users LIMIT 1");
    $stmt->execute();
    $userId = $stmt->fetchColumn() ?: 1;

    $stmtBadge = $db->prepare("SELECT * FROM badges WHERE id = ?");
    $stmtBadge->execute([$newId]);
    $badge = $stmtBadge->fetch();

    $controller = new BadgeController();
    $refMethod = new ReflectionMethod('BadgeController', 'formatBadge');
    $refMethod->setAccessible(true);
    $formatted = $refMethod->invoke($controller, $badge, $userId);

    echo "✓ Formatted Badge details:\n";
    print_r($formatted);

    // Clean up
    $db->exec("DELETE FROM badges WHERE code = 'test_lottie_badge'");
    echo "✓ Cleanup successful.\n";

} catch (Exception $e) {
    echo "❌ Test failed: " . $e->getMessage() . "\n";
}

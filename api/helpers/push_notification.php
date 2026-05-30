<?php
/**
 * Push Notification Helper
 * LovingHarmony API
 */

require_once __DIR__ . '/../config/database.php';

if (!function_exists('sendPushNotification')) {
    function sendPushNotification(string $title, string $body, string $targetType, int $targetId): array {
        $db = Database::getInstance()->getConnection();

        // 1. Log notification to database
        $insertStmt = $db->prepare(
            "INSERT INTO notifications (title, body, type, reference_id) VALUES (?, ?, ?, ?)"
        );
        $insertStmt->execute([$title, $body, $targetType, $targetId]);
        $notificationId = $db->lastInsertId();

        // 2. Fetch all FCM tokens
        $tokenStmt = $db->prepare("SELECT DISTINCT token FROM user_fcm_tokens");
        $tokenStmt->execute();
        $tokens = $tokenStmt->fetchAll(PDO::FETCH_COLUMN);

        $fcmResult = ['success' => false, 'success_count' => 0, 'total' => 0];

        if (!empty($tokens)) {
            // 3. Load Firebase configuration and send push notification
            require_once __DIR__ . '/../config/firebase.php';

            // Build deep linking data payload
            $deepLinkData = [
                'target_type' => $targetType,
                'target_id'   => (string) $targetId,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ];

            $fcmResult = sendFCMNotification($tokens, $title, $body, $deepLinkData);
        }

        return [
            'notification_id' => (int) $notificationId,
            'title'           => $title,
            'body'            => $body,
            'target_type'     => $targetType,
            'target_id'       => $targetId,
            'push_result'     => [
                'tokens_found'  => count($tokens),
                'success_count' => $fcmResult['success_count'] ?? 0,
                'total_sent'    => $fcmResult['total'] ?? 0,
            ]
        ];
    }
}

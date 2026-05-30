<?php
/**
 * Notification Controller
 * LovingHarmony API
 * 
 * Handles: List notifications, Send push notification with deep linking
 */

class NotificationController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/notifications
     * List notifications (paginated) with deep linking fields
     */
    public function index() {
        $auth = authenticate();

        $page = max(1, (int) ($_GET['page'] ?? 1));
        $perPage = min(50, max(1, (int) ($_GET['per_page'] ?? 20)));
        $offset = ($page - 1) * $perPage;

        $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM notifications");
        $countStmt->execute();
        $total = $countStmt->fetch()['total'];

        $stmt = $this->db->prepare(
            "SELECT * FROM notifications ORDER BY sent_at DESC LIMIT ? OFFSET ?"
        );
        $stmt->execute([$perPage, $offset]);
        $notifications = $stmt->fetchAll();

        $formatted = array_map(function ($n) {
            return [
                'id'           => (int) $n['id'],
                'title'        => $n['title'],
                'body'         => $n['body'],
                'type'         => $n['type'],
                'target_type'  => $n['type'],          // Deep linking alias
                'target_id'    => $n['reference_id'] ? (int) $n['reference_id'] : null,
                'reference_id' => $n['reference_id'] ? (int) $n['reference_id'] : null,
                'sent_at'      => $n['sent_at']
            ];
        }, $notifications);

        jsonPaginated($formatted, $total, $page, $perPage);
    }

    /**
     * POST /api/notifications/send
     * Send a push notification to all users with deep linking payload.
     * 
     * Body: {
     *   "title": "Kuis Baru!",
     *   "body": "Ada kuis baru tentang diet plant-based...",
     *   "target_type": "news"|"recipe"|"quiz",
     *   "target_id": 5
     * }
     */
    public function send() {
        $auth = authenticate();

        $data = getJsonBody();
        validateRequired($data, ['title', 'body', 'target_type', 'target_id']);

        $title = trim($data['title']);
        $body = trim($data['body']);
        $targetType = strtolower(trim($data['target_type']));
        $targetId = (int) $data['target_id'];

        // Validate target_type against allowed ENUM values
        $validTypes = ['news', 'recipe', 'group', 'system', 'quiz'];
        if (!in_array($targetType, $validTypes)) {
            jsonError('Invalid target_type. Allowed: ' . implode(', ', $validTypes), 422);
        }

        // 1. Log notification to database
        $insertStmt = $this->db->prepare(
            "INSERT INTO notifications (title, body, type, reference_id) VALUES (?, ?, ?, ?)"
        );
        $insertStmt->execute([$title, $body, $targetType, $targetId]);
        $notificationId = $this->db->lastInsertId();

        // 2. Fetch all FCM tokens
        $tokenStmt = $this->db->prepare("SELECT DISTINCT token FROM user_fcm_tokens");
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

        jsonSuccess([
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
        ], 'Notification sent successfully', 201);
    }
}

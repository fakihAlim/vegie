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

        require_once __DIR__ . '/../helpers/push_notification.php';
        $result = sendPushNotification($title, $body, $targetType, $targetId);

        jsonSuccess($result, 'Notification sent successfully', 201);
    }
}

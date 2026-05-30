<?php
/**
 * Notification Controller
 * LovingHarmony API
 * 
 * Handles: List notifications
 */

class NotificationController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/notifications
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
                'id' => (int) $n['id'],
                'title' => $n['title'],
                'body' => $n['body'],
                'type' => $n['type'],
                'reference_id' => $n['reference_id'] ? (int) $n['reference_id'] : null,
                'sent_at' => $n['sent_at']
            ];
        }, $notifications);

        jsonPaginated($formatted, $total, $page, $perPage);
    }
}

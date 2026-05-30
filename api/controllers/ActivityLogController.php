<?php
/**
 * Activity Log Controller
 * LovingHarmony API
 * 
 * Handles: Storing user activity logs from the mobile application
 */

class ActivityLogController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * POST /api/activity-logs
     * Store a new activity log
     */
    public function store() {
        // Fire-and-forget style. Always return 200 OK to the client.
        try {
            $auth = authenticate();
            $userId = $auth['user_id'];

            $data = getJsonBody();
            $action = $data['action'] ?? null;
            
            if (!$action) {
                jsonError('Action is required', 400);
            }

            // Whitelist of valid actions
            $validActions = [
                'app_open',
                'app_close',
                'screen_view',
                'food_log_add',
                'food_log_view',
                'food_log_delete',
                'food_log_edit',
                'news_view',
                'recipe_view',
                'group_view',
                'group_join',
                'profile_update',
                'sync_manual'
            ];

            if (!in_array($action, $validActions)) {
                jsonError('Invalid action', 400);
            }

            $sessionId = $data['session_id'] ?? null;
            $screen = $data['screen'] ?? null;
            $duration = isset($data['duration']) ? (int)$data['duration'] : null;
            $extraData = isset($data['extra_data']) ? json_encode($data['extra_data']) : null;
            $platform = $data['platform'] ?? null;
            $deviceName = $data['device_name'] ?? null;
            $osVersion = $data['os_version'] ?? null;
            $appVersion = $data['app_version'] ?? null;

            $stmt = $this->db->prepare("
                INSERT INTO user_activity_logs 
                (user_id, session_id, action, screen, duration, extra_data, platform, device_name, os_version, app_version)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");

            $stmt->execute([
                $userId,
                $sessionId,
                $action,
                $screen,
                $duration,
                $extraData,
                $platform,
                $deviceName,
                $osVersion,
                $appVersion
            ]);

            jsonSuccess(null, 'Activity log stored successfully');
        } catch (Exception $e) {
            // Keep fire-and-forget: log the error on the server but return a standard response or custom log.
            // Since this is non-critical, we don't want to crash the client.
            jsonError($e->getMessage(), 500);
        }
    }
}

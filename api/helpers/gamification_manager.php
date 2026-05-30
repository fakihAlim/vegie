<?php
/**
 * Gamification Manager Helper
 * LovingHarmony API
 */

class GamificationManager {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Log earned points in the activity logs database for auditing
     * 
     * @param int $userId
     * @param int $points
     * @param string $reason
     * @return bool
     */
    public function addPoints(int $userId, int $points, string $reason = 'quiz'): bool {
        try {
            $stmt = $this->db->prepare(
                "INSERT INTO user_activity_logs (user_id, action, extra_data) VALUES (?, ?, ?)"
            );
            $extraData = json_encode([
                'points_earned' => $points,
                'reason' => $reason
            ]);
            return $stmt->execute([$userId, 'earn_points', $extraData]);
        } catch (Exception $e) {
            return false;
        }
    }
}

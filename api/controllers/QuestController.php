<?php
/**
 * Quest Controller
 * Handles daily quests logic
 */

class QuestController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/quests
     * Get quests for the authenticated user for today
     */
    public function index() {
        $auth = authenticate();
        $userId = $auth['user_id'];
        $today = date('Y-m-d');

        // First, ensure the user has today's quests assigned
        $this->assignDailyQuests($userId, $today);

        // Fetch user quests for today
        $stmt = $this->db->prepare(
            "SELECT uq.id as user_quest_id, q.id as quest_id, q.title, q.description, q.points_reward, 
                    q.quest_type, q.target_count, uq.progress_count, uq.is_completed
             FROM user_quests uq
             JOIN quests q ON q.id = uq.quest_id
             WHERE uq.user_id = ? AND uq.target_date = ? AND q.is_active = 1"
        );
        $stmt->execute([$userId, $today]);
        $quests = $stmt->fetchAll();

        jsonSuccess($quests, 'Daily quests fetched successfully');
    }

    /**
     * POST /api/quests/{quest_id}/progress
     * Update progress of a specific quest type
     */
    public function updateProgress() {
        $auth = authenticate();
        $userId = $auth['user_id'];
        $today = date('Y-m-d');

        $data = getJsonBody();
        validateRequired($data, ['quest_type']);
        $questType = $data['quest_type'];

        // Find active uncompleted quest of this type for today
        $stmt = $this->db->prepare(
            "SELECT uq.id, uq.progress_count, q.target_count, q.points_reward
             FROM user_quests uq
             JOIN quests q ON q.id = uq.quest_id
             WHERE uq.user_id = ? AND uq.target_date = ? AND q.quest_type = ? AND uq.is_completed = 0
             LIMIT 1"
        );
        $stmt->execute([$userId, $today, $questType]);
        $quest = $stmt->fetch();

        if (!$quest) {
            jsonSuccess(['updated' => false], 'No active uncompleted quest of this type for today');
            return;
        }

        $newProgress = $quest['progress_count'] + 1;
        $isCompleted = ($newProgress >= $quest['target_count']) ? 1 : 0;

        $updateStmt = $this->db->prepare(
            "UPDATE user_quests 
             SET progress_count = ?, is_completed = ?, completed_at = IF(?, NOW(), NULL)
             WHERE id = ?"
        );
        $updateStmt->execute([$newProgress, $isCompleted, $isCompleted, $quest['id']]);

        $newlyUnlocked = [];
        if ($isCompleted) {
            require_once __DIR__ . '/../helpers/gamification_manager.php';
            $gamification = new GamificationManager();
            $gamification->addPoints($userId, $quest['points_reward'], 'quest_completed');
            $newlyUnlocked = $gamification->checkAndAwardBadges($userId);
        }

        jsonSuccess([
            'updated' => true,
            'progress' => $newProgress,
            'is_completed' => (bool)$isCompleted,
            'newly_unlocked_badges' => $newlyUnlocked
        ], $isCompleted ? 'Quest completed! 🎉' : 'Quest progress updated');
    }

    private function assignDailyQuests($userId, $date) {
        // Check if already assigned
        $stmt = $this->db->prepare("SELECT COUNT(*) as count FROM user_quests WHERE user_id = ? AND target_date = ?");
        $stmt->execute([$userId, $date]);
        if ($stmt->fetch()['count'] > 0) {
            return; // Already assigned
        }

        // Fetch 3 random active quests
        $questsStmt = $this->db->prepare("SELECT id FROM quests WHERE is_active = 1 ORDER BY RAND() LIMIT 3");
        $questsStmt->execute();
        $quests = $questsStmt->fetchAll();

        foreach ($quests as $q) {
            $insertStmt = $this->db->prepare("INSERT INTO user_quests (user_id, quest_id, target_date) VALUES (?, ?, ?)");
            $insertStmt->execute([$userId, $q['id'], $date]);
        }
    }
}

<?php
/**
 * TtmEvaluator - Gamified Adaptive Behavioral Engine Helper
 * LovingHarmony API
 */

class TtmEvaluator {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    /**
     * Evaluates initial TTM stage based on user answers, stores to database, and returns the stage.
     * 
     * @param int $userId
     * @param array $answers
     * @return string
     */
    public function evaluateInitialStage(int $userId, array $answers): string {
        $stage = 'precontemplation';
        
        if (isset($answers['stage'])) {
            $stage = strtolower(trim($answers['stage']));
        } elseif (isset($answers['readiness'])) {
            $readiness = strtolower(trim($answers['readiness']));
            switch ($readiness) {
                case 'no_intent':
                case 'none':
                    $stage = 'precontemplation';
                    break;
                case 'thinking':
                case 'maybe':
                    $stage = 'contemplation';
                    break;
                case 'planning':
                case 'soon':
                    $stage = 'preparation';
                    break;
                case 'already_started':
                    $stage = 'action';
                    break;
                case 'long_term':
                    $stage = 'maintenance';
                    break;
            }
        } else {
            // Default evaluation rules from multiple choice questionnaire
            // Q1: Interest in plant-based diet (1-5 scale)
            // Q2: Plan to start (1: >6 months, 2: 1-6 months, 3: <1 month, 4: already started)
            $q2 = isset($answers['q2']) ? (int)$answers['q2'] : 1;

            if ($q2 === 4) {
                $stage = 'action';
            } elseif ($q2 === 3) {
                $stage = 'preparation';
            } elseif ($q2 === 2 || $q2 === 1) {
                $stage = 'contemplation';
            } else {
                $stage = 'precontemplation';
            }
        }

        // Validate that the stage is one of the valid Enum values
        $validStages = ['precontemplation', 'contemplation', 'preparation', 'action', 'maintenance'];
        if (!in_array($stage, $validStages)) {
            $stage = 'precontemplation';
        }

        // Determine action start date if stage is 'action' or 'maintenance'
        $actionStartDate = null;
        if ($stage === 'action') {
            $actionStartDate = date('Y-m-d');
        } elseif ($stage === 'maintenance') {
            // Set action start date to 6 months ago for maintenance stage
            $actionStartDate = date('Y-m-d', strtotime('-6 months'));
        }

        // Save to DB (sync with current_stage in uppercase for backward compatibility)
        $stmt = $this->db->prepare(
            "UPDATE users 
             SET ttm_stage = ?, ttm_action_start_date = ?, current_stage = ?, is_onboarding_completed = 1 
             WHERE id = ?"
        );
        $stmt->execute([$stage, $actionStartDate, strtoupper($stage), $userId]);

        return $stage;
    }

    /**
     * Evaluates automatic stage transitions and feature lock rules based on user logging activity.
     * 
     * @param int $userId
     * @return array
     */
    public function evaluateProgress(int $userId): array {
        // 1. Fetch current stage and action start date
        $stmt = $this->db->prepare("SELECT ttm_stage, ttm_action_start_date FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            return ['stage' => 'precontemplation', 'is_feature_locked' => false];
        }

        $currentStage = $user['ttm_stage'] ?? 'precontemplation';
        $actionStartDate = $user['ttm_action_start_date'];

        // 2. FEATURE LOCK LOGIC:
        // Check if there are any food logs in the last 3 days
        $stmtLogs3Days = $this->db->prepare(
            "SELECT COUNT(*) FROM food_logs 
             WHERE user_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 3 DAY)"
        );
        $stmtLogs3Days->execute([$userId]);
        $hasLogsLast3Days = $stmtLogs3Days->fetchColumn() > 0;

        $isFeatureLocked = false;
        if (in_array($currentStage, ['action', 'maintenance'])) {
            if (!$hasLogsLast3Days) {
                $isFeatureLocked = true;
            }
        }

        // 3. STAGE PROMOTION LOGIC:
        $newStage = $currentStage;
        $newActionStartDate = $actionStartDate;
        $dbUpdated = false;

        if ($currentStage === 'preparation') {
            // Promote from preparation to action if there are > 3 logs in the last 7 days
            $stmtLogs7Days = $this->db->prepare(
                "SELECT COUNT(*) FROM food_logs 
                 WHERE user_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)"
            );
            $stmtLogs7Days->execute([$userId]);
            $logsCount7Days = $stmtLogs7Days->fetchColumn();

            if ($logsCount7Days > 3) {
                $newStage = 'action';
                $newActionStartDate = date('Y-m-d');
                $dbUpdated = true;
            }
        } elseif ($currentStage === 'action') {
            // Promote from action to maintenance if action start date is > 6 months ago
            if ($actionStartDate) {
                $startDate = new DateTime($actionStartDate);
                $sixMonthsAgo = (new DateTime())->modify('-6 months');
                if ($startDate <= $sixMonthsAgo) {
                    $newStage = 'maintenance';
                    $dbUpdated = true;
                }
            }
        }

        // 4. Update DB if stage transition occurred
        if ($dbUpdated) {
            $stmtUpdate = $this->db->prepare(
                "UPDATE users 
                 SET ttm_stage = ?, ttm_action_start_date = ?, current_stage = ? 
                 WHERE id = ?"
            );
            $stmtUpdate->execute([$newStage, $newActionStartDate, strtoupper($newStage), $userId]);
            
            // Re-evaluate feature lock based on new stage
            if (in_array($newStage, ['action', 'maintenance'])) {
                $isFeatureLocked = !$hasLogsLast3Days;
            } else {
                $isFeatureLocked = false;
            }
        }

        return [
            'stage' => $newStage,
            'is_feature_locked' => $isFeatureLocked
        ];
    }
}

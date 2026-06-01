<?php
/**
 * Gamification Manager Helper
 * LovingHarmony API
 *
 * Mengelola:
 *  - Penambahan poin ke activity log
 *  - Pengecekan & pemberian badge berdasarkan milestone perilaku
 */

class GamificationManager {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // -----------------------------------------------------------------------
    // Points
    // -----------------------------------------------------------------------

    /**
     * Log earned points in the activity logs database for auditing.
     */
    public function addPoints(int $userId, int $points, string $reason = 'quiz'): bool {
        try {
            $stmt = $this->db->prepare(
                "INSERT INTO user_activity_logs (user_id, action, extra_data) VALUES (?, ?, ?)"
            );
            $extraData = json_encode([
                'points_earned' => $points,
                'reason'        => $reason,
            ]);
            return $stmt->execute([$userId, 'earn_points', $extraData]);
        } catch (Exception $e) {
            return false;
        }
    }

    // -----------------------------------------------------------------------
    // Badges
    // -----------------------------------------------------------------------

    /**
     * Periksa semua milestone dan berikan badge yang belum dimiliki secara dinamis.
     *
     * @param int $userId
     * @return array  List BadgeModel-like arrays yang BARU diberikan pada panggilan ini.
     */
    public function checkAndAwardBadges(int $userId): array {
        $newlyAwarded = [];

        // Ambil semua badge code yang sudah dimiliki user (untuk skip)
        $stmt = $this->db->prepare("
            SELECT b.code
            FROM user_badges ub
            JOIN badges b ON b.id = ub.badge_id
            WHERE ub.user_id = ?
        ");
        $stmt->execute([$userId]);
        $ownedCodes = $stmt->fetchAll(PDO::FETCH_COLUMN);

        // Ambil semua katalog master badge aktif
        $stmt = $this->db->prepare("SELECT * FROM badges");
        $stmt->execute();
        $allBadges = $stmt->fetchAll();

        foreach ($allBadges as $badge) {
            $code = $badge['code'];
            // Lewati jika sudah punya
            if (in_array($code, $ownedCodes)) continue;

            try {
                $category = $badge['category'] ?? 'plant_lover';
                $target = (int) ($badge['target_value'] ?? 1);

                if ($this->evaluateProgress($userId, $category, $target)) {
                    $awarded = $this->awardBadge($userId, $code);
                    if ($awarded) {
                        $newlyAwarded[] = $awarded;
                    }
                }
            } catch (Exception $e) {
                error_log("Badge check error [$code]: " . $e->getMessage());
            }
        }

        return $newlyAwarded;
    }

    // -----------------------------------------------------------------------
    // Milestone checkers (dynamic and category-based)
    // -----------------------------------------------------------------------

    private function evaluateProgress(int $userId, string $category, int $target): bool {
        switch ($category) {
            case 'plant_lover':
                // total log makanan nabati (points = 50)
                $stmt = $this->db->prepare("SELECT COUNT(*) FROM food_logs WHERE user_id = ? AND points = 50");
                $stmt->execute([$userId]);
                return (int) $stmt->fetchColumn() >= $target;

            case 'explorer':
                // total baca artikel
                $stmt = $this->db->prepare("SELECT COUNT(*) FROM user_activity_logs WHERE user_id = ? AND action = 'news_view'");
                $stmt->execute([$userId]);
                return (int) $stmt->fetchColumn() >= $target;

            case 'streak':
                // total hari streak berturut-turut (reset jika ada log hewani/non-nabati)
                $stmt = $this->db->prepare("
                    SELECT DATE(meal_time) AS log_date, MIN(points) AS min_points
                    FROM food_logs
                    WHERE user_id = ?
                    GROUP BY log_date
                    ORDER BY log_date DESC
                ");
                $stmt->execute([$userId]);
                $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $streak = 0;
                if (!empty($rows)) {
                    $dateMap = [];
                    foreach ($rows as $row) {
                        $dateMap[$row['log_date']] = (int)$row['min_points'];
                    }

                    $todayStr = (new DateTime('today'))->format('Y-m-d');
                    $yesterdayStr = (new DateTime('yesterday'))->format('Y-m-d');

                    if (isset($dateMap[$todayStr]) || isset($dateMap[$yesterdayStr])) {
                        $currentDate = isset($dateMap[$todayStr]) ? new DateTime('today') : new DateTime('yesterday');
                        
                        while (true) {
                            $dateStr = $currentDate->format('Y-m-d');
                            if (isset($dateMap[$dateStr])) {
                                if ($dateMap[$dateStr] < 50) {
                                    break; // Animal-based log resets streak!
                                }
                                $streak++;
                                $currentDate->modify('-1 day');
                            } else {
                                break;
                            }
                        }
                    }
                }
                return $streak >= $target;

            case 'quiz_ace':
                // total jawaban benar kuis
                $stmt = $this->db->prepare("SELECT COUNT(*) FROM user_quizzes WHERE user_id = ? AND is_correct = 1");
                $stmt->execute([$userId]);
                return (int) $stmt->fetchColumn() >= $target;

            default:
                return false;
        }
    }

    // -----------------------------------------------------------------------
    // Award helper
    // -----------------------------------------------------------------------

    /**
     * Simpan badge ke tabel user_badges dan kembalikan data badge-nya.
     * Menggunakan INSERT IGNORE sehingga aman dipanggil berulang kali.
     */
    private function awardBadge(int $userId, string $code): ?array {
        // Cari badge_id
        $stmt = $this->db->prepare("SELECT * FROM badges WHERE code = ?");
        $stmt->execute([$code]);
        $badge = $stmt->fetch();
        if (!$badge) return null;

        // Simpan relasi (idempotent)
        $stmt = $this->db->prepare(
            "INSERT IGNORE INTO user_badges (user_id, badge_id) VALUES (?, ?)"
        );
        $stmt->execute([$userId, $badge['id']]);

        if ($this->db->lastInsertId() == 0) {
            // Sudah ada sebelumnya — tidak benar-benar baru
            return null;
        }

        // Log ke activity
        $this->db->prepare(
            "INSERT INTO user_activity_logs (user_id, action, extra_data) VALUES (?, 'badge_awarded', ?)"
        )->execute([$userId, json_encode(['badge_code' => $code, 'badge_name' => $badge['name']])]);

        return [
            'id'          => (int) $badge['id'],
            'code'        => $badge['code'],
            'name'        => $badge['name'],
            'description' => $badge['description'] ?? '',
            'lottie_file' => $badge['lottie_file'] ?? 'assets/lottie/default.json',
            'is_unlocked' => true,
            'awarded_at'  => date('Y-m-d H:i:s'),
        ];
    }
}

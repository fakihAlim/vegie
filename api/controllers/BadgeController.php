<?php
/**
 * Badge Controller
 * Vegie / LovingHarmony API
 *
 * Endpoints:
 *   GET  /badges           — list semua master badge + status is_unlocked untuk user yang login
 *   GET  /badges/{id}      — detail satu badge
 *   GET  /badges/user/{uid}— (admin) lihat badge milik user tertentu
 */

class BadgeController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // -----------------------------------------------------------------------
    // GET /badges
    // Mengembalikan semua master badge + flag is_unlocked berdasarkan user login
    // -----------------------------------------------------------------------
    public function index() {
        $auth   = authenticate();
        $userId = $auth['user_id'];

        // Auto-check and award badges retroactively upon badge list fetch
        require_once __DIR__ . '/../helpers/gamification_manager.php';
        $gamification = new GamificationManager();
        $gamification->checkAndAwardBadges($userId);

        $stmt = $this->db->prepare("
            SELECT
                b.*,
                IF(ub.id IS NOT NULL, 1, 0) AS is_unlocked,
                ub.awarded_at
            FROM badges b
            LEFT JOIN user_badges ub
                   ON ub.badge_id = b.id AND ub.user_id = ?
            ORDER BY b.id ASC
        ");
        $stmt->execute([$userId]);
        $rows = $stmt->fetchAll();

        $result = array_map(fn($row) => $this->formatBadge($row, $userId), $rows);
        jsonSuccess($result);
    }

    // -----------------------------------------------------------------------
    // GET /badges/{id}
    // -----------------------------------------------------------------------
    public function show($id) {
        $auth   = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare("
            SELECT
                b.*,
                IF(ub.id IS NOT NULL, 1, 0) AS is_unlocked,
                ub.awarded_at
            FROM badges b
            LEFT JOIN user_badges ub
                   ON ub.badge_id = b.id AND ub.user_id = ?
            WHERE b.id = ?
        ");
        $stmt->execute([$userId, $id]);
        $row = $stmt->fetch();

        if (!$row) {
            jsonError('Badge not found', 404);
        }

        jsonSuccess($this->formatBadge($row, $userId));
    }

    // -----------------------------------------------------------------------
    // GET /badges/user/{userId}   ← admin use-case
    // Hanya badge yang SUDAH dimiliki user tersebut
    // -----------------------------------------------------------------------
    public function userBadges($targetUserId) {
        // Siapa pun yang sudah login boleh lihat (bisa ditambah admin check di sini)
        authenticate();

        $stmt = $this->db->prepare("
            SELECT
                b.*,
                ub.awarded_at,
                1 AS is_unlocked
            FROM user_badges ub
            JOIN badges b ON b.id = ub.badge_id
            WHERE ub.user_id = ?
            ORDER BY ub.awarded_at DESC
        ");
        $stmt->execute([$targetUserId]);
        $rows = $stmt->fetchAll();

        $result = array_map(fn($row) => $this->formatBadge($row, (int) $targetUserId), $rows);
        jsonSuccess($result);
    }

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------
    private function formatBadge(array $row, int $userId): array {
        $progress = $this->getBadgeProgress($userId, $row);
        $lottieFile = $row['lottie_file'] ?? 'assets/lottie/default.json';
        if (strpos($lottieFile, 'uploads/') === 0) {
            $lottieFile = getUploadUrl($lottieFile);
        }

        return [
            'id'               => (int) $row['id'],
            'code'             => $row['code'],
            'name'             => $row['name'],
            'description'      => $row['description'] ?? '',
            'lottie_file'      => $lottieFile,
            'is_unlocked'      => (bool) ($row['is_unlocked'] ?? false),
            'awarded_at'       => $row['awarded_at'] ?? null,
            'category'         => $row['category'] ?? 'plant_lover',
            'target_value'     => (int) ($row['target_value'] ?? 1),
            'current_progress' => $progress['current'],
            'target_progress'  => $progress['target'],
            'progress_unit'    => $progress['unit'],
        ];
    }

    private function getBadgeProgress(int $userId, array $badge): array {
        $category = $badge['category'] ?? 'plant_lover';
        $target = (int) ($badge['target_value'] ?? 1);

        switch ($category) {
            case 'plant_lover':
                $stmt = $this->db->prepare("SELECT COUNT(*) FROM food_logs WHERE user_id = ? AND points = 50");
                $stmt->execute([$userId]);
                $current = (int) $stmt->fetchColumn();
                return [
                    'current' => min($current, $target), 
                    'target'  => $target, 
                    'unit'    => ($target === 1 ? 'log' : 'makanan nabati')
                ];

            case 'explorer':
                $stmt = $this->db->prepare("SELECT COUNT(*) FROM user_activity_logs WHERE user_id = ? AND action = 'news_view'");
                $stmt->execute([$userId]);
                $current = (int) $stmt->fetchColumn();
                return [
                    'current' => min($current, $target), 
                    'target'  => $target, 
                    'unit'    => 'artikel'
                ];

            case 'streak':
                $stmt = $this->db->prepare("
                    SELECT DISTINCT DATE(meal_time) AS log_date
                    FROM food_logs
                    WHERE user_id = ?
                    ORDER BY log_date DESC
                ");
                $stmt->execute([$userId]);
                $dates = $stmt->fetchAll(PDO::FETCH_COLUMN);
                
                $streak = 0;
                if (!empty($dates)) {
                    $today = new DateTime();
                    $yesterday = new DateTime('-1 day');
                    $lastLogDate = new DateTime($dates[0]);
                    
                    if ($lastLogDate->format('Y-m-d') === $today->format('Y-m-d') || 
                        $lastLogDate->format('Y-m-d') === $yesterday->format('Y-m-d')) {
                        $streak = 1;
                        for ($i = 0; $i < count($dates) - 1; $i++) {
                            $curr = new DateTime($dates[$i]);
                            $next = new DateTime($dates[$i + 1]);
                            if ($curr->diff($next)->days === 1) {
                                    $streak++;
                            } else {
                                    break;
                            }
                        }
                    }
                }
                return [
                    'current' => min($streak, $target), 
                    'target'  => $target, 
                    'unit'    => 'hari'
                ];

            case 'quiz_ace':
                $stmt = $this->db->prepare("SELECT COUNT(*) FROM user_quizzes WHERE user_id = ? AND is_correct = 1");
                $stmt->execute([$userId]);
                $current = (int) $stmt->fetchColumn();
                return [
                    'current' => min($current, $target), 
                    'target'  => $target, 
                    'unit'    => 'kuis benar'
                ];

            default:
                return [
                    'current' => 0, 
                    'target'  => $target, 
                    'unit'    => ''
                ];
        }
    }

    public function store() {
        // Authenticate user
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Get fields from $_POST (since Lottie files are uploaded via multipart/form-data)
        $code = trim($_POST['code'] ?? '');
        $name = trim($_POST['name'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $category = trim($_POST['category'] ?? '');
        $targetValue = (int) ($_POST['target_value'] ?? 1);
        $presetLottieFile = trim($_POST['lottie_file'] ?? '');

        // Validation
        if (empty($code) || empty($name) || empty($category) || $targetValue <= 0) {
            jsonError('Required fields: code, name, category, target_value (positive integer)', 422);
        }

        // Validate category
        $validCategories = ['explorer', 'streak', 'plant_lover', 'quiz_ace'];
        if (!in_array($category, $validCategories)) {
            jsonError('Invalid category. Allowed: explorer, streak, plant_lover, quiz_ace', 422);
        }

        // Check unique code
        $stmt = $this->db->prepare("SELECT id FROM badges WHERE code = ?");
        $stmt->execute([$code]);
        if ($stmt->fetch()) {
            jsonError("Badge code '$code' already exists", 409);
        }

        // Handle Lottie file upload
        $lottiePath = '';
        if (isset($_FILES['lottie']) && $_FILES['lottie']['error'] === UPLOAD_ERR_OK) {
            $lottiePath = $this->uploadLottieFile($_FILES['lottie']);
            if (!$lottiePath) {
                jsonError('Failed to upload Lottie file', 500);
            }
        } elseif (!empty($presetLottieFile)) {
            $lottiePath = $presetLottieFile;
        } else {
            $lottiePath = 'assets/lottie/default.json';
        }

        // Save new badge
        $stmt = $this->db->prepare("
            INSERT INTO badges (code, category, target_value, name, description, lottie_file)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([$code, $category, $targetValue, $name, $description, $lottiePath]);
        $newId = $this->db->lastInsertId();

        // Retrieve inserted badge details
        $stmt = $this->db->prepare("SELECT *, 0 AS is_unlocked, NULL AS awarded_at FROM badges WHERE id = ?");
        $stmt->execute([$newId]);
        $badgeRow = $stmt->fetch();

        jsonSuccess($this->formatBadge($badgeRow, $userId), 'New badge created successfully!', 201);
    }

    private function uploadLottieFile(array $file): ?string {
        if (!isset($file['tmp_name']) || $file['error'] !== UPLOAD_ERR_OK) {
            return null;
        }

        $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if ($extension !== 'json') {
            jsonError('Invalid file type. Only Lottie JSON files (.json) are allowed', 422);
        }

        // Validate JSON content
        $content = file_get_contents($file['tmp_name']);
        if (json_decode($content) === null) {
            jsonError('Uploaded file contains invalid JSON data', 422);
        }

        $targetDir = __DIR__ . '/../uploads/lotties/';
        if (!is_dir($targetDir)) {
            mkdir($targetDir, 0777, true);
        }

        $filename = uniqid() . '_' . time() . '.json';
        $targetPath = $targetDir . $filename;

        if (move_uploaded_file($file['tmp_name'], $targetPath)) {
            return 'uploads/lotties/' . $filename;
        }

        return null;
    }
}

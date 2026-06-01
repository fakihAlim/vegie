<?php
/**
 * Food Log Controller
 * LovingHarmony API
 * * Handles: CRUD for food logs + bulk sync + AI nutrition analysis
 */

class FoodLogController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/food-logs
     * List food logs for authenticated user
     */
    public function index() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $page = max(1, (int) ($_GET['page'] ?? 1));
        $perPage = min(50, max(1, (int) ($_GET['per_page'] ?? 20)));
        $offset = ($page - 1) * $perPage;
        $category = $_GET['category'] ?? null;
        $date = $_GET['date'] ?? null;

        // Build query with optional filters
        $where = "WHERE user_id = ?";
        $params = [$userId];

        if ($category) {
            $where .= " AND category = ?";
            $params[] = $category;
        }
        if ($date) {
            $where .= " AND DATE(meal_time) = ?";
            $params[] = $date;
        }

        // Get total count
        $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM food_logs $where");
        $countStmt->execute($params);
        $total = $countStmt->fetch()['total'];

        // Get paginated results
        $params[] = $perPage;
        $params[] = $offset;
        $stmt = $this->db->prepare(
            "SELECT * FROM food_logs $where ORDER BY meal_time DESC LIMIT ? OFFSET ?"
        );
        $stmt->execute($params);
        $logs = $stmt->fetchAll();

        // Format results
        $formatted = array_map(function ($log) {
            return $this->formatLog($log);
        }, $logs);

        jsonPaginated($formatted, $total, $page, $perPage);
    }

    /**
     * GET /api/food-logs/{id}
     */
    public function show($id) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare("SELECT * FROM food_logs WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $userId]);
        $log = $stmt->fetch();

        if (!$log) {
            jsonError('Food log not found', 404);
        }

        jsonSuccess($this->formatLog($log));
    }

    /**
     * POST /api/food-logs
     * Create a new food log (supports multipart for photo)
     * Automatically analyzes photo for nutrition data via AI
     */
    public function store() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Get data from POST (multipart form) or JSON body
        $foodName = $_POST['food_name'] ?? null;
        $mealTime = $_POST['meal_time'] ?? null;
        $category = $_POST['category'] ?? null;
        $nutritionNotes = $_POST['nutrition_notes'] ?? null;

        if (!$foodName && !isset($_FILES['photo'])) {
            $data = getJsonBody();
            $foodName = $data['food_name'] ?? null;
            $mealTime = $data['meal_time'] ?? null;
            $category = $data['category'] ?? null;
            $nutritionNotes = $data['nutrition_notes'] ?? null;
        }

        // Validate
        if (!$mealTime || !$category) {
            jsonError('meal_time and category are required', 422);
        }

        $validCategories = ['breakfast', 'lunch', 'dinner', 'snack'];
        if (!in_array($category, $validCategories)) {
            jsonError('Invalid category. Must be: ' . implode(', ', $validCategories), 422);
        }

        // Handle photo upload
        $photoPath = null;
        if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
            $photoPath = uploadImage($_FILES['photo'], 'food_logs');
        }

        // AI Nutrition Analysis
        $aiResult = null;
        if ($photoPath) {
            $fullPhotoPath = __DIR__ . '/../' . $photoPath;
            require_once __DIR__ . '/../helpers/nutrition_analyzer.php';
            $aiResult = analyzeNutrition($fullPhotoPath);
        }

        // Use AI-detected food name if no manual name provided or if placeholder is sent
        $isPlaceholder = !$foodName || in_array(strtolower(trim($foodName)), ['menganalisis...', 'menganalisis', 'analisis', 'analisis...']);
        if ($isPlaceholder && $aiResult) {
            $foodName = $aiResult['food_name'];
        } elseif ($isPlaceholder) {
            $foodName = 'Makanan Tidak Dikenali';
        }

        $calories = $aiResult['calories'] ?? null;
        $carbs = $aiResult['carbs'] ?? null;
        $fat = $aiResult['fat'] ?? null;
        $protein = $aiResult['protein'] ?? null;

        // Calculate points
        $points = $this->calculateFoodLogPoints($foodName, $aiResult ? ($aiResult['items'] ?? null) : null);

        $stmt = $this->db->prepare(
            "INSERT INTO food_logs (user_id, photo, food_name, meal_time, category, nutrition_notes, calories, carbs, fat, protein, points, ai_provider, ai_response_time, raw_response) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );
        $stmt->execute([
            $userId, $photoPath, $foodName, $mealTime, $category, $nutritionNotes, 
            $calories, $carbs, $fat, $protein, $points,
            $aiResult ? ($aiResult['ai_provider'] ?? null) : null,
            $aiResult ? ($aiResult['ai_response_time'] ?? null) : null,
            $aiResult ? ($aiResult['raw_response'] ?? null) : null
        ]);
        $logId = $this->db->lastInsertId();

        $evaluator = new TtmEvaluator($this->db);
        $progress = $evaluator->evaluateProgress($userId);

        // Calculate carbon saved
        $calculator = new CarbonCalculator($this->db);
        $foodItems = [];
        if ($aiResult && is_array($aiResult) && isset($aiResult['items']) && is_array($aiResult['items'])) {
            $foodItems = $aiResult['items'];
        } else {
            $foodItems = [
                [
                    'name' => $foodName,
                    'weight' => 0.15 // Default serving weight 150g = 0.15 kg
                ]
            ];
        }
        $carbonSavedThisMeal = $calculator->calculateAndSaveCarbon($userId, $foodItems);

        // Fetch updated total_carbon_saved
        $userStmt = $this->db->prepare("SELECT total_carbon_saved FROM users WHERE id = ?");
        $userStmt->execute([$userId]);
        $totalCarbonSaved = (float)($userStmt->fetch()['total_carbon_saved'] ?? 0.00);

        // Check & award badges based on behavioral milestones
        $gamification = new GamificationManager();
        $newlyUnlockedBadges = $gamification->checkAndAwardBadges($userId);

        jsonSuccess([
            'id' => (int) $logId,
            'photo' => $photoPath ? getUploadUrl($photoPath) : null,
            'food_name' => $foodName,
            'meal_time' => $mealTime,
            'category' => $category,
            'nutrition_notes' => $nutritionNotes,
            'calories' => $calories,
            'carbs' => $carbs,
            'fat' => $fat,
            'protein' => $protein,
            'points' => (int) $points,
            'ai_provider' => $aiResult['ai_provider'] ?? null,
            'ai_raw_response' => $aiResult['raw_response'] ?? null,
            'raw_response' => $aiResult['raw_response'] ?? null,
            'ai_response_time' => $aiResult['ai_response_time'] ?? null,
            'current_ttm_stage' => $progress['stage'],
            'is_feature_locked' => (bool)$progress['is_feature_locked'],
            'carbon_saved_this_meal' => $carbonSavedThisMeal,
            'total_carbon_saved' => $totalCarbonSaved,
            'newly_unlocked_badges' => $newlyUnlockedBadges,
        ], 'Food log created successfully', 201);

    }

    /**
     * PUT/POST /api/food-logs/{id}/update
     */
    public function update($id) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Check ownership
        $stmt = $this->db->prepare("SELECT * FROM food_logs WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $userId]);
        $log = $stmt->fetch();

        if (!$log) {
            jsonError('Food log not found', 404);
        }

        // Get data
        $foodName = $_POST['food_name'] ?? null;
        $mealTime = $_POST['meal_time'] ?? null;
        $category = $_POST['category'] ?? null;
        $nutritionNotes = $_POST['nutrition_notes'] ?? null;
        $calories = $_POST['calories'] ?? null;
        $carbs = $_POST['carbs'] ?? null;
        $fat = $_POST['fat'] ?? null;
        $protein = $_POST['protein'] ?? null;
        $rawResponse = $_POST['raw_response'] ?? null;

        if (!$foodName) {
            $data = getJsonBody();
            $foodName = $data['food_name'] ?? $log['food_name'];
            $mealTime = $data['meal_time'] ?? $log['meal_time'];
            $category = $data['category'] ?? $log['category'];
            $nutritionNotes = $data['nutrition_notes'] ?? $log['nutrition_notes'];
            $calories = $data['calories'] ?? $log['calories'];
            $carbs = $data['carbs'] ?? $log['carbs'];
            $fat = $data['fat'] ?? $log['fat'];
            $protein = $data['protein'] ?? $log['protein'];
            $rawResponse = $data['raw_response'] ?? $data['ai_raw_response'] ?? $log['raw_response'];
        } else {
            $mealTime = $mealTime ?? $log['meal_time'];
            $category = $category ?? $log['category'];
            $nutritionNotes = $nutritionNotes ?? $log['nutrition_notes'];
            $calories = $calories ?? $log['calories'];
            $carbs = $carbs ?? $log['carbs'];
            $fat = $fat ?? $log['fat'];
            $protein = $protein ?? $log['protein'];
            $rawResponse = $rawResponse ?? $log['raw_response'];
        }

        // Handle photo
        $photoPath = $log['photo'];
        if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
            $newPhotoPath = uploadImage($_FILES['photo'], 'food_logs');
            if ($newPhotoPath) {
                deleteUploadedFile($log['photo']);
                $photoPath = $newPhotoPath;
            }
        }

        $points = null;
        if (isset($_POST['points'])) {
            $points = (int) $_POST['points'];
        } else {
            $data = getJsonBody();
            if (isset($data['points'])) {
                $points = (int) $data['points'];
            }
        }

        if ($points === null) {
            $items = null;
            if (!empty($rawResponse)) {
                $parsedJson = json_decode($rawResponse, true);
                if (is_array($parsedJson) && isset($parsedJson['items'])) {
                    $items = $parsedJson['items'];
                }
            }

            // Recalculate based purely on name if edited
            if (strtolower(trim($foodName)) !== strtolower(trim($log['food_name']))) {
                $items = null;
            }

            $points = $this->calculateFoodLogPoints($foodName, $items);
        }

        $stmt = $this->db->prepare(
            "UPDATE food_logs SET photo = ?, food_name = ?, meal_time = ?, category = ?, nutrition_notes = ?, calories = ?, carbs = ?, fat = ?, protein = ?, points = ?, raw_response = ? WHERE id = ?"
        );
        $stmt->execute([$photoPath, $foodName, $mealTime, $category, $nutritionNotes, $calories, $carbs, $fat, $protein, $points, $rawResponse, $id]);

        // Check & award badges based on behavioral milestones
        $gamification = new GamificationManager();
        $newlyUnlockedBadges = $gamification->checkAndAwardBadges($userId);

        jsonSuccess([
            'id' => (int) $id,
            'photo' => $photoPath ? getUploadUrl($photoPath) : null,
            'food_name' => $foodName,
            'meal_time' => $mealTime,
            'category' => $category,
            'nutrition_notes' => $nutritionNotes,
            'calories' => $calories !== null ? (float) $calories : null,
            'carbs' => $carbs !== null ? (float) $carbs : null,
            'fat' => $fat !== null ? (float) $fat : null,
            'protein' => $protein !== null ? (float) $protein : null,
            'points' => (int) $points,
            'newly_unlocked_badges' => $newlyUnlockedBadges,
        ], 'Food log updated successfully');
    }

    /**
     * POST /api/food-logs/{id}/analyze
     * Re-analyze a food log's photo with AI
     */
    public function analyze($id) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare("SELECT * FROM food_logs WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $userId]);
        $log = $stmt->fetch();

        if (!$log) {
            // Also allow admin to analyze any log (no user_id check)
            $stmt = $this->db->prepare("SELECT * FROM food_logs WHERE id = ?");
            $stmt->execute([$id]);
            $log = $stmt->fetch();
            if (!$log) {
                jsonError('Food log not found', 404);
            }
        }

        if (!$log['photo']) {
            jsonError('No photo to analyze', 422);
        }

        $fullPhotoPath = __DIR__ . '/../' . $log['photo'];
        if (!file_exists($fullPhotoPath)) {
            jsonError('Photo file not found on server', 404);
        }

        require_once __DIR__ . '/../helpers/nutrition_analyzer.php';
        $aiResult = analyzeNutrition($fullPhotoPath);

        if (!$aiResult) {
            jsonError('AI analysis failed. Please try again later.', 500);
        }

        $points = $this->calculateFoodLogPoints($aiResult['food_name'], $aiResult['items'] ?? null);

        // Calculate carbon saved
        $calculator = new CarbonCalculator($this->db);
        $foodItems = [];
        if ($aiResult && is_array($aiResult) && isset($aiResult['items']) && is_array($aiResult['items'])) {
            $foodItems = $aiResult['items'];
        } else {
            $foodItems = [
                [
                    'name' => $aiResult['food_name'],
                    'weight' => 0.15
                ]
            ];
        }
        $carbonSavedThisMeal = $calculator->calculateAndSaveCarbon($userId, $foodItems);

        // Fetch updated total_carbon_saved
        $userStmt = $this->db->prepare("SELECT total_carbon_saved FROM users WHERE id = ?");
        $userStmt->execute([$userId]);
        $totalCarbonSaved = (float)($userStmt->fetch()['total_carbon_saved'] ?? 0.00);

        jsonSuccess([
            'id' => (int) $id,
            'food_name' => $aiResult['food_name'],
            'calories' => $aiResult['calories'],
            'carbs' => $aiResult['carbs'],
            'fat' => $aiResult['fat'],
            'protein' => $aiResult['protein'],
            'points' => (int) $points,
            'ai_provider' => $aiResult['ai_provider'] ?? null,
            'ai_raw_response' => $aiResult['raw_response'] ?? null,
            'raw_response' => $aiResult['raw_response'] ?? null,
            'ai_response_time' => $aiResult['ai_response_time'] ?? null,
            'carbon_saved_this_meal' => $carbonSavedThisMeal,
            'total_carbon_saved' => $totalCarbonSaved,
        ], 'Nutrition analysis completed');
    }

    /**
     * DELETE /api/food-logs/{id}
     */
    public function delete($id) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare("SELECT photo FROM food_logs WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $userId]);
        $log = $stmt->fetch();

        if (!$log) {
            jsonError('Food log not found', 404);
        }

        // Delete photo file
        if ($log['photo']) {
            deleteUploadedFile($log['photo']);
        }

        $stmt = $this->db->prepare("DELETE FROM food_logs WHERE id = ?");
        $stmt->execute([$id]);

        jsonSuccess(null, 'Food log deleted successfully');
    }

    /**
     * POST /api/food-logs/sync
     * Bulk sync food logs from offline storage
     */
    public function sync() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $data = getJsonBody();
        if (!isset($data['logs']) || !is_array($data['logs'])) {
            jsonError('logs array is required', 422);
        }

        $synced = [];
        $errors = [];

        foreach ($data['logs'] as $index => $log) {
            try {
                if (empty($log['food_name']) || empty($log['meal_time']) || empty($log['category'])) {
                    $errors[] = "Log #$index: missing required fields";
                    continue;
                }

                $stmt = $this->db->prepare(
                    "INSERT INTO food_logs (user_id, food_name, meal_time, category, nutrition_notes) 
                     VALUES (?, ?, ?, ?, ?)"
                );
                $stmt->execute([
                    $userId,
                    $log['food_name'],
                    $log['meal_time'],
                    $log['category'],
                    $log['nutrition_notes'] ?? null
                ]);

                $logId = $this->db->lastInsertId();

                // Calculate carbon saved for offline logs during sync
                $calculator = new CarbonCalculator($this->db);
                $foodItems = [
                    [
                        'name' => $log['food_name'],
                        'weight' => 0.15
                    ]
                ];
                $calculator->calculateAndSaveCarbon($userId, $foodItems);

                $synced[] = [
                    'local_id' => $log['local_id'] ?? $index,
                    'server_id' => (int) $logId
                ];
            } catch (Exception $e) {
                $errors[] = "Log #$index: " . $e->getMessage();
            }
        }

        jsonSuccess([
            'synced_count' => count($synced),
            'error_count' => count($errors),
            'synced' => $synced,
            'errors' => $errors
        ], 'Sync completed');
    }

    /**
     * GET /api/food-logs/streak
     * Calculate the current consecutive-day streak for the authenticated user
     */
    public function streak() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Get dates with food logs and their minimum points, ordered descending
        $stmt = $this->db->prepare("
            SELECT DATE(meal_time) AS log_date, MIN(points) AS min_points
            FROM food_logs
            WHERE user_id = ?
            GROUP BY log_date
            ORDER BY log_date DESC
        ");
        $stmt->execute([$userId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (empty($rows)) {
            jsonSuccess(['streak' => 0, 'dates' => []]);
            return;
        }

        $dateMap = [];
        $dates = [];
        foreach ($rows as $row) {
            $dateMap[$row['log_date']] = (int)$row['min_points'];
            $dates[] = $row['log_date'];
        }

        $todayStr = (new DateTime('today'))->format('Y-m-d');
        $yesterdayStr = (new DateTime('yesterday'))->format('Y-m-d');

        $streak = 0;
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

        jsonSuccess([
            'streak' => $streak,
            'dates' => $dates
        ]);
    }

    /**
     * POST /api/food-logs/{id}/share
     */
    public function share($id) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Check ownership
        $stmt = $this->db->prepare("SELECT * FROM food_logs WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $userId]);
        $log = $stmt->fetch();

        if (!$log) {
            jsonError('Food log not found', 404);
        }

        // Toggle share status
        $newShareStatus = $log['is_shared'] ? 0 : 1;

        $stmt = $this->db->prepare("UPDATE food_logs SET is_shared = ? WHERE id = ?");
        $stmt->execute([$newShareStatus, $id]);

        jsonSuccess([
            'id' => (int) $id,
            'is_shared' => (bool) $newShareStatus
        ], $newShareStatus ? 'Food log shared to Discover successfully' : 'Food log removed from Discover');
    }

    /**
     * Calculate points for a food log:
     * purely plant-based (nabati) = 50 pts, contains animal products (hewani) = -20 pts.
     * OPTIMIZED VER.
     */
    private function calculateFoodLogPoints($foodName, $items) {
        $namesToCheck = [];
        
        if (!empty($foodName)) {
            $namesToCheck[] = strtolower(trim($foodName));
        }
        
        if (is_array($items)) {
            foreach ($items as $item) {
                if (isset($item['nama'])) {
                    $namesToCheck[] = strtolower(trim($item['nama']));
                }
            }
        }
        
        // Hapus nama ganda untuk menghemat iterasi
        $namesToCheck = array_unique($namesToCheck);
        
        if (empty($namesToCheck)) {
            return 50; 
        }

        // 1. CEK LOKAL (IN-MEMORY) TERLEBIH DAHULU
        // Ini akan sangat memangkas proses dan query ke DB.
        $hewaniKeywords = [
            'ayam', 'daging', 'sapi', 'ikan', 'telur', 'susu', 'babi', 'kambing', 'udang', 
            'cumi', 'kepiting', 'keju', 'mentega', 'egg', 'chicken', 'beef', 'fish', 'pork', 
            'milk', 'cheese', 'butter'
        ];
        
        foreach ($namesToCheck as $name) {
            foreach ($hewaniKeywords as $kw) {
                if (strpos($name, $kw) !== false) {
                    return -20; // Langsung potong poin jika ketemu keyword
                }
            }
        }

        // 2. CEK DATABASE (SATU KALI QUERY SAJA)
        $conditions = [];
        $params = [];
        
        foreach ($namesToCheck as $name) {
            // Jika di-desain baru, ini cocok diganti dengan MATCH() AGAINST().
            // Karena ini optimalisasi kode eksisting tanpa ubah skema DB:
            $conditions[] = "(LOWER(food_name) LIKE CONCAT('%', ?, '%') OR ? LIKE CONCAT('%', LOWER(food_name), '%'))";
            $params[] = $name;
            $params[] = $name;
        }

        $whereClause = implode(' OR ', $conditions);

        // Hanya cari data dengan kategori 'protein hewani' agar proses sorting dilakukan di tingkat SQL
        $sql = "
            SELECT 1 FROM emission_factors 
            WHERE LOWER(category) = 'protein hewani' 
              AND ($whereClause)
            LIMIT 1
        ";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        
        // Cek apakah ada record yang matching
        if ($stmt->fetchColumn()) {
            return -20;
        }
        
        // Jika tidak ada di lokal dan database, berarti murni nabati
        return 50;
    }

    /**
     * Format a food log record for API response
     */
    private function formatLog($log) {
        return [
            'id' => (int) $log['id'],
            'photo' => $log['photo'] ? getUploadUrl($log['photo']) : null,
            'food_name' => $log['food_name'],
            'meal_time' => $log['meal_time'],
            'category' => $log['category'],
            'nutrition_notes' => $log['nutrition_notes'],
            'calories' => $log['calories'] !== null ? (float) $log['calories'] : null,
            'carbs' => $log['carbs'] !== null ? (float) $log['carbs'] : null,
            'fat' => $log['fat'] !== null ? (float) $log['fat'] : null,
            'protein' => $log['protein'] !== null ? (float) $log['protein'] : null,
            'points' => isset($log['points']) ? (int) $log['points'] : 0,
            'is_shared' => isset($log['is_shared']) ? (bool) $log['is_shared'] : false,
            'created_at' => $log['created_at'],
            'raw_response' => $log['raw_response'] ?? null,
        ];
    }
}
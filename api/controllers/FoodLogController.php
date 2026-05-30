<?php
/**
 * Food Log Controller
 * LovingHarmony API
 * 
 * Handles: CRUD for food logs + bulk sync + AI nutrition analysis
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

        $stmt = $this->db->prepare(
            "INSERT INTO food_logs (user_id, photo, food_name, meal_time, category, nutrition_notes, calories, carbs, fat, protein, ai_provider, ai_response_time, raw_response) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );
        $stmt->execute([
            $userId, $photoPath, $foodName, $mealTime, $category, $nutritionNotes, 
            $calories, $carbs, $fat, $protein,
            $aiResult ? ($aiResult['ai_provider'] ?? null) : null,
            $aiResult ? ($aiResult['ai_response_time'] ?? null) : null,
            $aiResult ? ($aiResult['raw_response'] ?? null) : null
        ]);
        $logId = $this->db->lastInsertId();

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
            'ai_provider' => $aiResult['ai_provider'] ?? null,
            'ai_raw_response' => $aiResult['raw_response'] ?? null,
            'ai_response_time' => $aiResult['ai_response_time'] ?? null,
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
        } else {
            $mealTime = $mealTime ?? $log['meal_time'];
            $category = $category ?? $log['category'];
            $nutritionNotes = $nutritionNotes ?? $log['nutrition_notes'];
            $calories = $calories ?? $log['calories'];
            $carbs = $carbs ?? $log['carbs'];
            $fat = $fat ?? $log['fat'];
            $protein = $protein ?? $log['protein'];
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

        $stmt = $this->db->prepare(
            "UPDATE food_logs SET photo = ?, food_name = ?, meal_time = ?, category = ?, nutrition_notes = ?, calories = ?, carbs = ?, fat = ?, protein = ? WHERE id = ?"
        );
        $stmt->execute([$photoPath, $foodName, $mealTime, $category, $nutritionNotes, $calories, $carbs, $fat, $protein, $id]);

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

        // Update database
        $stmt = $this->db->prepare(
            "UPDATE food_logs SET food_name = ?, calories = ?, carbs = ?, fat = ?, protein = ?, ai_provider = ?, ai_response_time = ?, raw_response = ? WHERE id = ?"
        );
        $stmt->execute([
            $aiResult['food_name'],
            $aiResult['calories'],
            $aiResult['carbs'],
            $aiResult['fat'],
            $aiResult['protein'],
            $aiResult['ai_provider'] ?? null,
            $aiResult['ai_response_time'] ?? null,
            $aiResult['raw_response'] ?? null,
            $id,
        ]);

        jsonSuccess([
            'id' => (int) $id,
            'food_name' => $aiResult['food_name'],
            'calories' => $aiResult['calories'],
            'carbs' => $aiResult['carbs'],
            'fat' => $aiResult['fat'],
            'protein' => $aiResult['protein'],
            'ai_provider' => $aiResult['ai_provider'] ?? null,
            'ai_raw_response' => $aiResult['raw_response'] ?? null,
            'ai_response_time' => $aiResult['ai_response_time'] ?? null,
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

                $synced[] = [
                    'local_id' => $log['local_id'] ?? $index,
                    'server_id' => (int) $this->db->lastInsertId()
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

        // Get distinct dates with food logs, ordered descending
        $stmt = $this->db->prepare(
            "SELECT DISTINCT DATE(meal_time) as log_date 
             FROM food_logs 
             WHERE user_id = ? 
             ORDER BY log_date DESC"
        );
        $stmt->execute([$userId]);
        $dates = $stmt->fetchAll(PDO::FETCH_COLUMN);

        if (empty($dates)) {
            jsonSuccess(['streak' => 0, 'dates' => []]);
            return;
        }

        $today = new DateTime('today');
        $yesterday = new DateTime('yesterday');
        $firstLogDate = new DateTime($dates[0]);

        // Streak must start from today or yesterday
        if ($firstLogDate != $today && $firstLogDate != $yesterday) {
            jsonSuccess(['streak' => 0, 'dates' => $dates]);
            return;
        }

        $streak = 1;
        for ($i = 1; $i < count($dates); $i++) {
            $current = new DateTime($dates[$i - 1]);
            $previous = new DateTime($dates[$i]);
            $diff = $current->diff($previous)->days;

            if ($diff === 1) {
                $streak++;
            } else {
                break;
            }
        }

        jsonSuccess([
            'streak' => $streak,
            'dates' => $dates
        ]);
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
            'created_at' => $log['created_at'],
        ];
    }
}

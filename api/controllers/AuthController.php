<?php
/**
 * Auth Controller
 * LovingHarmony API
 * 
 * Handles: Register, Login, Profile, FCM Token
 */

class AuthController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * POST /api/auth/register
     */
    public function register() {
        $data = getJsonBody();
        validateRequired($data, ['name', 'email', 'password']);

        $name = trim($data['name']);
        $email = strtolower(trim($data['email']));
        $password = $data['password'];

        // Validate email format
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            jsonError('Invalid email format', 422);
        }

        // Validate password length
        if (strlen($password) < 6) {
            jsonError('Password must be at least 6 characters', 422);
        }

        // Check if email already exists
        $stmt = $this->db->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->execute([$email]);
        if ($stmt->fetch()) {
            jsonError('Email already registered', 409);
        }

        // Hash password and create user
        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        $joinDate = date('Y-m-d');

        $stmt = $this->db->prepare(
            "INSERT INTO users (name, email, password, join_date) VALUES (?, ?, ?, ?)"
        );
        $stmt->execute([$name, $email, $hashedPassword, $joinDate]);
        $userId = $this->db->lastInsertId();

        // Generate JWT token
        $token = jwtEncode([
            'user_id' => (int) $userId,
            'email' => $email,
            'name' => $name
        ]);

        $evaluator = new TtmEvaluator($this->db);
        $progress = $evaluator->evaluateProgress($userId);

        jsonSuccess([
            'token' => $token,
            'user' => [
                'id' => (int) $userId,
                'name' => $name,
                'email' => $email,
                'photo' => null,
                'bio' => null,
                'age' => null,
                'weight' => null,
                'height' => null,
                'total_carbon_saved' => 0.00,
                'join_date' => $joinDate,
                'is_onboarding_completed' => false,
                'ttm_stage' => $progress['stage'],
                'is_feature_locked' => (bool)$progress['is_feature_locked'],
                'total_points' => 0
            ]
        ], 'Registration successful', 201);
    }

    /**
     * POST /api/auth/login
     */
    public function login() {
        $data = getJsonBody();
        validateRequired($data, ['email', 'password']);

        $email = strtolower(trim($data['email']));
        $password = $data['password'];

        // Find user
        $stmt = $this->db->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password'])) {
            jsonError('Invalid email or password', 401);
        }

        // Generate JWT token
        $token = jwtEncode([
            'user_id' => (int) $user['id'],
            'email' => $user['email'],
            'name' => $user['name']
        ]);

        $evaluator = new TtmEvaluator($this->db);
        $progress = $evaluator->evaluateProgress($user['id']);

        jsonSuccess([
            'token' => $token,
            'user' => [
                'id' => (int) $user['id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'photo' => $user['photo'] ? (strpos($user['photo'], 'uploads/') === 0 ? getUploadUrl($user['photo']) : $user['photo']) : null,
                'bio' => $user['bio'],
                'age' => $user['age'] !== null ? (int)$user['age'] : null,
                'weight' => $user['weight'] !== null ? (float)$user['weight'] : null,
                'height' => $user['height'] !== null ? (float)$user['height'] : null,
                'total_carbon_saved' => $user['total_carbon_saved'] !== null ? (float)$user['total_carbon_saved'] : 0.00,
                'join_date' => $user['join_date'],
                'is_onboarding_completed' => (bool)$user['is_onboarding_completed'],
                'ttm_stage' => $progress['stage'],
                'is_feature_locked' => (bool)$progress['is_feature_locked'],
                'total_points' => $this->getUserTotalPoints($user['id'])
            ]
        ], 'Login successful');
    }

    /**
     * GET /api/auth/profile
     */
    public function getProfile() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare(
            "SELECT id, name, email, photo, bio, age, weight, height, total_carbon_saved, join_date, is_onboarding_completed, created_at FROM users WHERE id = ?"
        );
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        if (!$user) {
            jsonError('User not found', 404);
        }

        // Get stats
        $stmt = $this->db->prepare("SELECT COUNT(*) as total_logs FROM food_logs WHERE user_id = ?");
        $stmt->execute([$userId]);
        $stats = $stmt->fetch();

        $stmt = $this->db->prepare("SELECT COUNT(*) as total_groups FROM group_members WHERE user_id = ?");
        $stmt->execute([$userId]);
        $groupStats = $stmt->fetch();

        $evaluator = new TtmEvaluator($this->db);
        $progress = $evaluator->evaluateProgress($userId);

        jsonSuccess([
            'id' => (int) $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'photo' => $user['photo'] ? (strpos($user['photo'], 'uploads/') === 0 ? getUploadUrl($user['photo']) : $user['photo']) : null,
            'bio' => $user['bio'],
            'age' => $user['age'] !== null ? (int)$user['age'] : null,
            'weight' => $user['weight'] !== null ? (float)$user['weight'] : null,
            'height' => $user['height'] !== null ? (float)$user['height'] : null,
            'total_carbon_saved' => $user['total_carbon_saved'] !== null ? (float)$user['total_carbon_saved'] : 0.00,
            'join_date' => $user['join_date'],
            'is_onboarding_completed' => (bool)$user['is_onboarding_completed'],
            'ttm_stage' => $progress['stage'],
            'is_feature_locked' => (bool)$progress['is_feature_locked'],
            'total_points' => $this->getUserTotalPoints($user['id']),
            'stats' => [
                'total_logs' => (int) $stats['total_logs'],
                'total_groups' => (int) $groupStats['total_groups']
            ]
        ]);
    }

    /**
     * PUT/POST /api/auth/profile
     */
    public function updateProfile() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Handle both JSON body and form-data (for photo upload)
        $name = $_POST['name'] ?? null;
        $bio = $_POST['bio'] ?? null;
        $age = $_POST['age'] ?? null;
        $weight = $_POST['weight'] ?? null;
        $height = $_POST['height'] ?? null;
        $presetPhoto = $_POST['photo'] ?? null;
        $photoPath = null;

        // If no POST data, try JSON body
        if (!$name && !$age && !$weight && !$height && !$presetPhoto) {
            $data = getJsonBody();
            $name = $data['name'] ?? null;
            $bio = $data['bio'] ?? null;
            $age = $data['age'] ?? null;
            $weight = $data['weight'] ?? null;
            $height = $data['height'] ?? null;
            $presetPhoto = $data['photo'] ?? null;
        }

        // Handle photo upload
        if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
            $photoPath = uploadImage($_FILES['photo'], 'profiles');
            if (!$photoPath) {
                jsonError('Failed to upload profile photo', 500);
            }

            // Delete old photo
            $stmt = $this->db->prepare("SELECT photo FROM users WHERE id = ?");
            $stmt->execute([$userId]);
            $oldUser = $stmt->fetch();
            if ($oldUser && $oldUser['photo'] && strpos($oldUser['photo'], 'uploads/') === 0) {
                deleteUploadedFile($oldUser['photo']);
            }
        } elseif ($presetPhoto !== null) {
            $photoPath = trim($presetPhoto);
        }

        // Build update query dynamically
        $updates = [];
        $params = [];

        if ($name !== null) {
            $updates[] = "name = ?";
            $params[] = trim($name);
        }
        if ($bio !== null) {
            $updates[] = "bio = ?";
            $params[] = trim($bio);
        }
        if ($age !== null) {
            $updates[] = "age = ?";
            $params[] = (int)$age;
        }
        if ($weight !== null) {
            $updates[] = "weight = ?";
            $params[] = (float)$weight;
        }
        if ($height !== null) {
            $updates[] = "height = ?";
            $params[] = (float)$height;
        }
        if ($photoPath !== null) {
            $updates[] = "photo = ?";
            $params[] = $photoPath;
        }

        if (empty($updates)) {
            jsonError('No data to update', 422);
        }

        $params[] = $userId;
        $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        // Return updated profile
        $stmt = $this->db->prepare(
            "SELECT id, name, email, photo, bio, age, weight, height, total_carbon_saved, join_date, is_onboarding_completed FROM users WHERE id = ?"
        );
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        $evaluator = new TtmEvaluator($this->db);
        $progress = $evaluator->evaluateProgress($userId);

        jsonSuccess([
            'id' => (int) $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'photo' => $user['photo'] ? (strpos($user['photo'], 'uploads/') === 0 ? getUploadUrl($user['photo']) : $user['photo']) : null,
            'bio' => $user['bio'],
            'age' => $user['age'] !== null ? (int)$user['age'] : null,
            'weight' => $user['weight'] !== null ? (float)$user['weight'] : null,
            'height' => $user['height'] !== null ? (float)$user['height'] : null,
            'total_carbon_saved' => $user['total_carbon_saved'] !== null ? (float)$user['total_carbon_saved'] : 0.00,
            'join_date' => $user['join_date'],
            'is_onboarding_completed' => (bool)$user['is_onboarding_completed'],
            'ttm_stage' => $progress['stage'],
            'is_feature_locked' => (bool)$progress['is_feature_locked'],
            'total_points' => $this->getUserTotalPoints($user['id'])
        ], 'Profile updated successfully');
    }

    /**
     * POST /api/auth/fcm-token
     */
    public function registerFcmToken() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $data = getJsonBody();
        validateRequired($data, ['token']);

        $token = $data['token'];
        $deviceInfo = $data['device_info'] ?? null;

        // Upsert: update if token exists for this user, insert otherwise
        $stmt = $this->db->prepare(
            "SELECT id FROM user_fcm_tokens WHERE user_id = ? AND token = ?"
        );
        $stmt->execute([$userId, $token]);

        if ($stmt->fetch()) {
            // Update existing
            $stmt = $this->db->prepare(
                "UPDATE user_fcm_tokens SET updated_at = NOW() WHERE user_id = ? AND token = ?"
            );
            $stmt->execute([$userId, $token]);
        } else {
            // Insert new
            $stmt = $this->db->prepare(
                "INSERT INTO user_fcm_tokens (user_id, token, device_info) VALUES (?, ?, ?)"
            );
            $stmt->execute([$userId, $token, $deviceInfo]);
        }

        jsonSuccess(null, 'FCM token registered successfully');
    }

    /**
     * POST /api/auth/onboarding
     */
    public function onboarding() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $data = getJsonBody();
        validateRequired($data, ['stage']);
        
        $stage = strtoupper(trim($data['stage']));
        $validStages = ['PRECONTEMPLATION', 'CONTEMPLATION', 'PREPARATION', 'ACTION', 'MAINTENANCE'];
        
        if (!in_array($stage, $validStages)) {
            jsonError('Invalid stage', 422);
        }

        $age = isset($data['age']) ? (int)$data['age'] : null;
        $weight = isset($data['weight']) ? (float)$data['weight'] : null;
        $height = isset($data['height']) ? (float)$data['height'] : null;
        $photo = isset($data['photo']) ? trim($data['photo']) : null;

        $ttmStage = strtolower($stage);
        $actionStartDate = null;
        if ($ttmStage === 'action') {
            $actionStartDate = date('Y-m-d');
        } elseif ($ttmStage === 'maintenance') {
            $actionStartDate = date('Y-m-d', strtotime('-6 months'));
        }

        $stmt = $this->db->prepare(
            "UPDATE users SET 
                is_onboarding_completed = 1, 
                current_stage = ?, 
                ttm_stage = ?,
                ttm_action_start_date = ?,
                age = ?, 
                weight = ?, 
                height = ?, 
                photo = ? 
             WHERE id = ?"
        );
        $stmt->execute([$stage, $ttmStage, $actionStartDate, $age, $weight, $height, $photo, $userId]);

        jsonSuccess(null, 'Onboarding completed successfully');
    }

    private function getUserTotalPoints($userId) {
        // Points from Quizzes
        $stmt = $this->db->prepare(
            "SELECT COALESCE(SUM(q.points), 0) as total_points
             FROM user_quizzes uq
             JOIN quizzes q ON uq.quiz_id = q.id
             WHERE uq.user_id = ? AND uq.is_correct = 1"
        );
        $stmt->execute([$userId]);
        $quizPoints = (int) ($stmt->fetch()['total_points'] ?? 0);

        // Points from Food Logs
        $stmt = $this->db->prepare(
            "SELECT COALESCE(SUM(points), 0) as total_points
             FROM food_logs
             WHERE user_id = ?"
        );
        $stmt->execute([$userId]);
        $foodLogPoints = (int) ($stmt->fetch()['total_points'] ?? 0);

        return $quizPoints + $foodLogPoints;
    }
}

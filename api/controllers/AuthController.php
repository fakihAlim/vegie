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
                'photo' => $user['photo'] ? getUploadUrl($user['photo']) : null,
                'bio' => $user['bio'],
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
            "SELECT id, name, email, photo, bio, join_date, is_onboarding_completed, created_at FROM users WHERE id = ?"
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
            'photo' => $user['photo'] ? getUploadUrl($user['photo']) : null,
            'bio' => $user['bio'],
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
        $photoPath = null;

        // If no POST data, try JSON body
        if (!$name) {
            $data = getJsonBody();
            $name = $data['name'] ?? null;
            $bio = $data['bio'] ?? null;
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
            if ($oldUser && $oldUser['photo']) {
                deleteUploadedFile($oldUser['photo']);
            }
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
        if ($photoPath) {
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
            "SELECT id, name, email, photo, bio, join_date, is_onboarding_completed FROM users WHERE id = ?"
        );
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        $evaluator = new TtmEvaluator($this->db);
        $progress = $evaluator->evaluateProgress($userId);

        jsonSuccess([
            'id' => (int) $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'photo' => $user['photo'] ? getUploadUrl($user['photo']) : null,
            'bio' => $user['bio'],
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

        $stmt = $this->db->prepare(
            "UPDATE users SET is_onboarding_completed = 1, current_stage = ? WHERE id = ?"
        );
        $stmt->execute([$stage, $userId]);

        jsonSuccess(null, 'Onboarding completed successfully');
    }

    private function getUserTotalPoints($userId) {
        $stmt = $this->db->prepare(
            "SELECT COALESCE(SUM(q.points), 0) as total_points
             FROM user_quizzes uq
             JOIN quizzes q ON uq.quiz_id = q.id
             WHERE uq.user_id = ? AND uq.is_correct = 1"
        );
        $stmt->execute([$userId]);
        $data = $stmt->fetch();
        return (int) ($data['total_points'] ?? 0);
    }
}

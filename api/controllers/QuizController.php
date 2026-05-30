<?php
/**
 * Quiz Controller
 * LovingHarmony API
 * 
 * Handles: List quizzes, Show quiz, Answer quiz, Generate AI quiz
 */

class QuizController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/quizzes
     * List all active quizzes (paginated) with user answer status
     */
    public function index() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $page = max(1, (int) ($_GET['page'] ?? 1));
        $perPage = min(50, max(1, (int) ($_GET['per_page'] ?? 20)));
        $offset = ($page - 1) * $perPage;

        // Count total active quizzes
        $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM quizzes WHERE is_active = 1");
        $countStmt->execute();
        $total = $countStmt->fetch()['total'];

        // Fetch quizzes with user answer status via LEFT JOIN
        $stmt = $this->db->prepare(
            "SELECT q.*, 
                    uq.id AS user_quiz_id, 
                    uq.is_correct AS user_answer_correct
             FROM quizzes q
             LEFT JOIN user_quizzes uq ON uq.quiz_id = q.id AND uq.user_id = ?
             WHERE q.is_active = 1
             ORDER BY q.created_at DESC
             LIMIT ? OFFSET ?"
        );
        $stmt->execute([$userId, $perPage, $offset]);
        $quizzes = $stmt->fetchAll();

        $formatted = array_map(function ($q) {
            return [
                'id'               => (int) $q['id'],
                'question'         => $q['question'],
                'option_a'         => $q['option_a'],
                'option_b'         => $q['option_b'],
                'option_c'         => $q['option_c'],
                'option_d'         => $q['option_d'],
                'points'           => (int) $q['points'],
                'already_answered' => $q['user_quiz_id'] !== null,
                'was_correct'      => $q['user_quiz_id'] !== null ? (bool) $q['user_answer_correct'] : null,
                'created_at'       => $q['created_at'],
            ];
        }, $quizzes);

        jsonPaginated($formatted, $total, $page, $perPage);
    }

    /**
     * GET /api/quizzes/{id}
     * Show a single quiz detail
     */
    public function show(int|string $id) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare(
            "SELECT q.*, 
                    uq.id AS user_quiz_id, 
                    uq.is_correct AS user_answer_correct
             FROM quizzes q
             LEFT JOIN user_quizzes uq ON uq.quiz_id = q.id AND uq.user_id = ?
             WHERE q.id = ? AND q.is_active = 1"
        );
        $stmt->execute([$userId, (int) $id]);
        $quiz = $stmt->fetch();

        if (!$quiz) {
            jsonError('Quiz not found', 404);
        }

        $alreadyAnswered = $quiz['user_quiz_id'] !== null;

        $response = [
            'id'               => (int) $quiz['id'],
            'question'         => $quiz['question'],
            'option_a'         => $quiz['option_a'],
            'option_b'         => $quiz['option_b'],
            'option_c'         => $quiz['option_c'],
            'option_d'         => $quiz['option_d'],
            'points'           => (int) $quiz['points'],
            'already_answered' => $alreadyAnswered,
            'was_correct'      => $alreadyAnswered ? (bool) $quiz['user_answer_correct'] : null,
            'created_at'       => $quiz['created_at'],
        ];

        // Only reveal correct answer & explanation if user already answered
        if ($alreadyAnswered) {
            $response['correct_answer'] = $quiz['correct_answer'];
            $response['explanation'] = $quiz['explanation'];
        }

        jsonSuccess($response);
    }

    /**
     * POST /api/quizzes/{id}/answer
     * User submits their answer for a quiz (Legacy route)
     */
    public function answer(int|string $id) {
        $this->submitAnswer($id);
    }

    /**
     * POST /api/quizzes/{id}/submit
     * User submits their answer for a quiz, checks correctness, logs answer, and adds gamification points
     */
    public function submitAnswer(int|string $id) {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $data = getJsonBody();
        validateRequired($data, ['answer']);

        $userAnswer = strtolower(trim($data['answer']));
        if (!in_array($userAnswer, ['a', 'b', 'c', 'd'])) {
            jsonError('Answer must be one of: a, b, c, d', 422);
        }

        // Fetch quiz
        $stmt = $this->db->prepare("SELECT * FROM quizzes WHERE id = ? AND is_active = 1");
        $stmt->execute([(int) $id]);
        $quiz = $stmt->fetch();

        if (!$quiz) {
            jsonError('Quiz not found', 404);
        }

        // Check if already answered
        $checkStmt = $this->db->prepare(
            "SELECT id FROM user_quizzes WHERE user_id = ? AND quiz_id = ?"
        );
        $checkStmt->execute([$userId, (int) $id]);
        if ($checkStmt->fetch()) {
            jsonError('Kamu sudah menjawab kuis ini sebelumnya', 409);
        }

        // Evaluate answer
        $isCorrect = ($userAnswer === $quiz['correct_answer']) ? 1 : 0;
        $pointsEarned = $isCorrect ? (int) $quiz['points'] : 0;

        // Insert user answer
        $insertStmt = $this->db->prepare(
            "INSERT INTO user_quizzes (user_id, quiz_id, is_correct) VALUES (?, ?, ?)"
        );
        $insertStmt->execute([$userId, (int) $id, $isCorrect]);

        // Add points via GamificationManager
        if ($pointsEarned > 0) {
            require_once __DIR__ . '/../helpers/gamification_manager.php';
            $gamification = new GamificationManager();
            $gamification->addPoints($userId, $pointsEarned, 'quiz_answer');
        }

        jsonSuccess([
            'quiz_id'        => (int) $id,
            'user_answer'    => $userAnswer,
            'correct_answer' => $quiz['correct_answer'],
            'is_correct'     => (bool) $isCorrect,
            'points_earned'  => $pointsEarned,
            'explanation'    => $quiz['explanation'],
        ], $isCorrect ? 'Jawaban benar! 🎉' : 'Jawaban salah. Coba lagi di kuis berikutnya! 💪');
    }

    /**
     * POST /api/quizzes/generate
     * Generate a new quiz question using AI (Ollama → Gemini fallback)
     */
    public function generate() {
        $auth = authenticate();

        // Load AI Quiz Generator
        require_once __DIR__ . '/../helpers/ai_quiz_generator.php';

        $quizData = generatePlantBasedQuiz();

        if ($quizData === null) {
            jsonError('Gagal membuat kuis dari AI. Silakan coba lagi nanti.', 503);
        }

        // Insert into database
        $stmt = $this->db->prepare(
            "INSERT INTO quizzes (question, option_a, option_b, option_c, option_d, correct_answer, explanation, points, is_active)
             VALUES (?, ?, ?, ?, ?, ?, ?, 50, 1)"
        );
        $stmt->execute([
            $quizData['question'],
            $quizData['option_a'],
            $quizData['option_b'],
            $quizData['option_c'],
            $quizData['option_d'],
            $quizData['correct_answer'],
            $quizData['explanation'],
        ]);

        $quizId = $this->db->lastInsertId();

        jsonSuccess([
            'id'          => (int) $quizId,
            'question'    => $quizData['question'],
            'option_a'    => $quizData['option_a'],
            'option_b'    => $quizData['option_b'],
            'option_c'    => $quizData['option_c'],
            'option_d'    => $quizData['option_d'],
            'points'      => 50,
            'ai_provider' => $quizData['ai_provider'] ?? 'unknown',
            'created_at'  => date('Y-m-d H:i:s'),
        ], 'Kuis baru berhasil dibuat oleh AI! 🤖', 201);
    }

    /**
     * GET /api/quizzes/stats
     * Get quiz statistics for the authenticated user
     */
    public function stats() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        // Total answered
        $totalStmt = $this->db->prepare(
            "SELECT COUNT(*) as total_answered, 
                    SUM(is_correct) as total_correct
             FROM user_quizzes WHERE user_id = ?"
        );
        $totalStmt->execute([$userId]);
        $stats = $totalStmt->fetch();

        // Total points earned
        $pointsStmt = $this->db->prepare(
            "SELECT COALESCE(SUM(q.points), 0) as total_points
             FROM user_quizzes uq
             JOIN quizzes q ON q.id = uq.quiz_id
             WHERE uq.user_id = ? AND uq.is_correct = 1"
        );
        $pointsStmt->execute([$userId]);
        $pointsData = $pointsStmt->fetch();

        // Total available quizzes
        $availableStmt = $this->db->prepare(
            "SELECT COUNT(*) as total FROM quizzes WHERE is_active = 1"
        );
        $availableStmt->execute();
        $available = $availableStmt->fetch();

        jsonSuccess([
            'total_quizzes'   => (int) $available['total'],
            'total_answered'  => (int) $stats['total_answered'],
            'total_correct'   => (int) ($stats['total_correct'] ?? 0),
            'total_wrong'     => (int) $stats['total_answered'] - (int) ($stats['total_correct'] ?? 0),
            'accuracy'        => $stats['total_answered'] > 0 
                ? round(($stats['total_correct'] / $stats['total_answered']) * 100, 1) 
                : 0,
            'total_points'    => (int) $pointsData['total_points'],
        ]);
    }

    /**
     * POST /api/quizzes/daily-generate
     * Generate a new daily quiz using AI (Ollama with Gemini fallback) and send push notification
     */
    public function generateDailyAIQuiz() {
        // Authenticate admin/cron
        $auth = authenticate();

        // Load AI Quiz Generator
        require_once __DIR__ . '/../helpers/ai_quiz_generator.php';

        $quizData = generatePlantBasedQuiz();

        if ($quizData === null) {
            jsonError('Gagal membuat kuis dari AI. Silakan coba lagi nanti.', 503);
        }

        // Insert into database
        $stmt = $this->db->prepare(
            "INSERT INTO quizzes (question, option_a, option_b, option_c, option_d, correct_answer, explanation, points, is_active)
             VALUES (?, ?, ?, ?, ?, ?, ?, 50, 1)"
        );
        $stmt->execute([
            $quizData['question'],
            $quizData['option_a'],
            $quizData['option_b'],
            $quizData['option_c'],
            $quizData['option_d'],
            $quizData['correct_answer'],
            $quizData['explanation'],
        ]);

        $quizId = (int) $this->db->lastInsertId();

        // Trigger push notification for new quiz
        require_once __DIR__ . '/../helpers/push_notification.php';
        sendPushNotification('Kuis Baru!', 'Uji pengetahuanmu tentang nutrisi hari ini.', 'quiz', $quizId);

        jsonSuccess([
            'id'          => $quizId,
            'question'    => $quizData['question'],
            'option_a'    => $quizData['option_a'],
            'option_b'    => $quizData['option_b'],
            'option_c'    => $quizData['option_c'],
            'option_d'    => $quizData['option_d'],
            'points'      => 50,
            'ai_provider' => $quizData['ai_provider'] ?? 'unknown',
            'created_at'  => date('Y-m-d H:i:s'),
        ], 'Kuis baru berhasil dibuat oleh AI dan notifikasi telah dikirim! 🤖', 201);
    }

    /**
     * GET /api/quizzes/daily
     * Get one active daily quiz that has NOT been answered by the requesting user
     */
    public function getDailyQuiz() {
        $auth = authenticate();
        $userId = $auth['user_id'];

        $stmt = $this->db->prepare(
            "SELECT q.* 
             FROM quizzes q
             LEFT JOIN user_quizzes uq ON uq.quiz_id = q.id AND uq.user_id = ?
             WHERE q.is_active = 1 AND uq.id IS NULL
             ORDER BY q.created_at DESC
             LIMIT 1"
        );
        $stmt->execute([$userId]);
        $quiz = $stmt->fetch();

        if (!$quiz) {
            jsonError('Tidak ada kuis baru untuk hari ini. Kamu sudah menjawab semua kuis! 🎉', 404);
        }

        jsonSuccess([
            'id'          => (int) $quiz['id'],
            'question'    => $quiz['question'],
            'option_a'    => $quiz['option_a'],
            'option_b'    => $quiz['option_b'],
            'option_c'    => $quiz['option_c'],
            'option_d'    => $quiz['option_d'],
            'points'      => (int) $quiz['points'],
            'created_at'  => $quiz['created_at']
        ], 'Kuis harian berhasil diambil');
    }
}

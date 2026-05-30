<?php
/**
 * Recipe Controller
 * LovingHarmony API
 * 
 * Handles: List and detail of published recipes
 */

class RecipeController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/recipes
     */
    public function index() {
        $page = max(1, (int) ($_GET['page'] ?? 1));
        $perPage = min(50, max(1, (int) ($_GET['per_page'] ?? 10)));
        $offset = ($page - 1) * $perPage;
        $search = $_GET['search'] ?? null;

        $where = "WHERE is_published = 1";
        $params = [];

        if ($search) {
            $where .= " AND (title LIKE ? OR description LIKE ?)";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        // Count
        $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM recipes $where");
        $countStmt->execute($params);
        $total = $countStmt->fetch()['total'];

        // Fetch
        $params[] = $perPage;
        $params[] = $offset;
        $stmt = $this->db->prepare(
            "SELECT id, title, photo, description, calories, prep_time_minutes, published_at 
             FROM recipes $where ORDER BY published_at DESC LIMIT ? OFFSET ?"
        );
        $stmt->execute($params);
        $recipes = $stmt->fetchAll();

        $formatted = array_map(function ($item) {
            return [
                'id' => (int) $item['id'],
                'title' => $item['title'],
                'photo' => $item['photo'] ? getUploadUrl($item['photo']) : null,
                'description' => $item['description'],
                'calories' => $item['calories'] ? (int) $item['calories'] : null,
                'prep_time_minutes' => $item['prep_time_minutes'] ? (int) $item['prep_time_minutes'] : null,
                'published_at' => $item['published_at']
            ];
        }, $recipes);

        jsonPaginated($formatted, $total, $page, $perPage);
    }

    /**
     * GET /api/recipes/{id}
     */
    public function show($id) {
        $stmt = $this->db->prepare(
            "SELECT * FROM recipes WHERE id = ? AND is_published = 1"
        );
        $stmt->execute([$id]);
        $recipe = $stmt->fetch();

        if (!$recipe) {
            jsonError('Recipe not found', 404);
        }

        // Get ingredients
        $stmt = $this->db->prepare(
            "SELECT ingredient, amount FROM recipe_ingredients WHERE recipe_id = ? ORDER BY sort_order"
        );
        $stmt->execute([$id]);
        $ingredients = $stmt->fetchAll();

        // Get steps
        $stmt = $this->db->prepare(
            "SELECT step_number, description FROM recipe_steps WHERE recipe_id = ? ORDER BY step_number"
        );
        $stmt->execute([$id]);
        $steps = $stmt->fetchAll();

        jsonSuccess([
            'id' => (int) $recipe['id'],
            'title' => $recipe['title'],
            'photo' => $recipe['photo'] ? getUploadUrl($recipe['photo']) : null,
            'description' => $recipe['description'],
            'calories' => $recipe['calories'] ? (int) $recipe['calories'] : null,
            'prep_time_minutes' => $recipe['prep_time_minutes'] ? (int) $recipe['prep_time_minutes'] : null,
            'ingredients' => $ingredients,
            'steps' => $steps,
            'published_at' => $recipe['published_at']
        ]);
    }

    /**
     * POST /api/recipes
     * Create a new recipe (Admin) and trigger push notification
     */
    public function create() {
        $auth = authenticate();

        $data = getJsonBody();
        validateRequired($data, ['title', 'description']);

        $title = trim($data['title']);
        $description = trim($data['description']);
        $photo = $data['photo'] ?? null;
        $calories = isset($data['calories']) ? (int) $data['calories'] : null;
        $prepTime = isset($data['prep_time_minutes']) ? (int) $data['prep_time_minutes'] : null;
        $isPublished = isset($data['is_published']) ? (int) $data['is_published'] : 1;
        $publishedAt = $data['published_at'] ?? date('Y-m-d H:i:s');

        $ingredients = $data['ingredients'] ?? []; // Expected format: [ [ingredient, amount], ... ]
        $steps = $data['steps'] ?? []; // Expected format: [ step_desc, ... ]

        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare(
                "INSERT INTO recipes (title, description, photo, calories, prep_time_minutes, is_published, published_at) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)"
            );
            $stmt->execute([$title, $description, $photo, $calories, $prepTime, $isPublished, $publishedAt]);
            $recipeId = (int) $this->db->lastInsertId();

            // Insert ingredients
            if (!empty($ingredients) && is_array($ingredients)) {
                $stmtIng = $this->db->prepare(
                    "INSERT INTO recipe_ingredients (recipe_id, ingredient, amount, sort_order) 
                     VALUES (?, ?, ?, ?)"
                );
                $sortOrder = 1;
                foreach ($ingredients as $ing) {
                    $ingName = $ing[0] ?? $ing['ingredient'] ?? '';
                    $amount = $ing[1] ?? $ing['amount'] ?? '';
                    if (!empty($ingName)) {
                        $stmtIng->execute([$recipeId, $ingName, $amount, $sortOrder++]);
                    }
                }
            }

            // Insert steps
            if (!empty($steps) && is_array($steps)) {
                $stmtStep = $this->db->prepare(
                    "INSERT INTO recipe_steps (recipe_id, step_number, description) 
                     VALUES (?, ?, ?)"
                );
                $stepNumber = 1;
                foreach ($steps as $desc) {
                    if (!empty(trim($desc))) {
                        $stmtStep->execute([$recipeId, $stepNumber++, trim($desc)]);
                    }
                }
            }

            $this->db->commit();

            // Trigger push notification if published
            if ($isPublished) {
                require_once __DIR__ . '/../helpers/push_notification.php';
                sendPushNotification('Resep Baru', $title, 'recipe', $recipeId);
            }

            jsonSuccess([
                'id' => $recipeId,
                'title' => $title,
                'description' => $description,
                'photo' => $photo ? getUploadUrl($photo) : null,
                'calories' => $calories,
                'prep_time_minutes' => $prepTime,
                'is_published' => (bool) $isPublished,
                'published_at' => $publishedAt,
                'ingredients' => $ingredients,
                'steps' => $steps
            ], 'Resep berhasil dibuat!', 201);

        } catch (Exception $e) {
            $this->db->rollBack();
            jsonError('Gagal membuat resep: ' . $e->getMessage(), 500);
        }
    }
}

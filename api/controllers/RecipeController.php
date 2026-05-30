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
}

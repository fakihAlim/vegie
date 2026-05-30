<?php
/**
 * News Controller
 * LovingHarmony API
 * 
 * Handles: List and detail of published news articles
 */

class NewsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/news
     */
    public function index() {
        $page = max(1, (int) ($_GET['page'] ?? 1));
        $perPage = min(50, max(1, (int) ($_GET['per_page'] ?? 10)));
        $offset = ($page - 1) * $perPage;
        $search = $_GET['search'] ?? null;

        $where = "WHERE is_published = 1";
        $params = [];

        if ($search) {
            $where .= " AND (title LIKE ? OR content LIKE ?)";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        // Count
        $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM news $where");
        $countStmt->execute($params);
        $total = $countStmt->fetch()['total'];

        // Fetch
        $params[] = $perPage;
        $params[] = $offset;
        $stmt = $this->db->prepare(
            "SELECT id, title, LEFT(content, 200) as excerpt, image, published_at, created_at 
             FROM news $where ORDER BY published_at DESC LIMIT ? OFFSET ?"
        );
        $stmt->execute($params);
        $news = $stmt->fetchAll();

        $formatted = array_map(function ($item) {
            return [
                'id' => (int) $item['id'],
                'title' => $item['title'],
                'excerpt' => $item['excerpt'] . '...',
                'image' => $item['image'] ? getUploadUrl($item['image']) : null,
                'published_at' => $item['published_at']
            ];
        }, $news);

        jsonPaginated($formatted, $total, $page, $perPage);
    }

    /**
     * GET /api/news/{id}
     */
    public function show($id) {
        $stmt = $this->db->prepare(
            "SELECT * FROM news WHERE id = ? AND is_published = 1"
        );
        $stmt->execute([$id]);
        $news = $stmt->fetch();

        if (!$news) {
            jsonError('News not found', 404);
        }

        jsonSuccess([
            'id' => (int) $news['id'],
            'title' => $news['title'],
            'content' => $news['content'],
            'image' => $news['image'] ? getUploadUrl($news['image']) : null,
            'published_at' => $news['published_at'],
            'created_at' => $news['created_at']
        ]);
    }
}

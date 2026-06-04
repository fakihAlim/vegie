<?php
/**
 * MythFact Controller
 * Handles fetching Myth vs Fact items
 */

class MythFactController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/myths
     * Get a list of myths and facts
     */
    public function index() {
        require_once __DIR__ . '/../helpers/upload.php';

        $stmt = $this->db->prepare("SELECT * FROM myth_facts ORDER BY RAND() LIMIT 10");
        $stmt->execute();
        $myths = $stmt->fetchAll();

        $formatted = array_map(function ($item) {
            $imageUrl = $item['image_url'];
            if ($imageUrl && strpos($imageUrl, 'http') !== 0) {
                $imageUrl = getUploadUrl($imageUrl);
            }
            return [
                'id' => (int) $item['id'],
                'title' => $item['title'],
                'type' => $item['type'],
                'description' => $item['description'],
                'image_url' => $imageUrl,
                'created_at' => $item['created_at']
            ];
        }, $myths);

        jsonSuccess($formatted, 'Myths and facts fetched successfully');
    }
}

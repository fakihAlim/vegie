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
        $stmt = $this->db->prepare("SELECT * FROM myth_facts ORDER BY RAND() LIMIT 10");
        $stmt->execute();
        $myths = $stmt->fetchAll();

        jsonSuccess($myths, 'Myths and facts fetched successfully');
    }
}

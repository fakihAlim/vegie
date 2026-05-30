<?php
/**
 * Quote Controller
 * LovingHarmony API
 * 
 * Handles: Daily motivational quotes
 */

class QuoteController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/quotes/today
     * Get today's daily quote
     * 
     * Logic:
     * 1. If a quote has display_date = today, use that
     * 2. Otherwise, pick a random active quote
     */
    public function today() {
        $today = date('Y-m-d');

        // First try: exact match for today's date
        $stmt = $this->db->prepare(
            "SELECT id, quote_text, author FROM daily_quotes 
             WHERE display_date = ? AND is_active = 1 
             LIMIT 1"
        );
        $stmt->execute([$today]);
        $quote = $stmt->fetch();

        // Fallback: deterministic "random" based on day of year (so it stays same all day)
        if (!$quote) {
            $dayOfYear = (int) date('z'); // 0-365
            $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM daily_quotes WHERE is_active = 1");
            $countStmt->execute();
            $total = (int) $countStmt->fetch()['total'];

            if ($total === 0) {
                jsonSuccess([
                    'quote_text' => 'Setiap hari adalah kesempatan baru untuk hidup lebih sehat.',
                    'author' => 'LovingHarmony'
                ], 'Default quote');
                return;
            }

            $offset = $dayOfYear % $total;
            $stmt = $this->db->prepare(
                "SELECT id, quote_text, author FROM daily_quotes 
                 WHERE is_active = 1 
                 ORDER BY id ASC 
                 LIMIT 1 OFFSET ?"
            );
            $stmt->execute([$offset]);
            $quote = $stmt->fetch();
        }

        jsonSuccess([
            'quote_text' => $quote['quote_text'],
            'author' => $quote['author']
        ], 'Quote of the day');
    }

    /**
     * GET /api/quotes
     * List all quotes (for admin)
     */
    public function index() {
        $page = max(1, (int) ($_GET['page'] ?? 1));
        $perPage = min(50, max(1, (int) ($_GET['per_page'] ?? 20)));
        $offset = ($page - 1) * $perPage;

        $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM daily_quotes");
        $countStmt->execute();
        $total = $countStmt->fetch()['total'];

        $stmt = $this->db->prepare(
            "SELECT * FROM daily_quotes ORDER BY created_at DESC LIMIT ? OFFSET ?"
        );
        $stmt->execute([$perPage, $offset]);
        $quotes = $stmt->fetchAll();

        $formatted = array_map(function ($q) {
            return [
                'id' => (int) $q['id'],
                'quote_text' => $q['quote_text'],
                'author' => $q['author'],
                'display_date' => $q['display_date'],
                'is_active' => (bool) $q['is_active'],
                'created_at' => $q['created_at']
            ];
        }, $quotes);

        jsonPaginated($formatted, $total, $page, $perPage);
    }

    /**
     * POST /api/quotes
     * Create a new quote
     */
    public function store() {
        $data = getJsonBody();
        if (empty($data)) {
            $data = $_POST;
        }
        
        validateRequired($data, ['quote_text']);

        $stmt = $this->db->prepare(
            "INSERT INTO daily_quotes (quote_text, author, display_date, is_active) VALUES (?, ?, ?, ?)"
        );
        $stmt->execute([
            $data['quote_text'],
            $data['author'] ?? 'Anonim',
            !empty($data['display_date']) ? $data['display_date'] : null,
            isset($data['is_active']) ? (int) $data['is_active'] : 1
        ]);

        $id = $this->db->lastInsertId();

        jsonSuccess([
            'id' => (int) $id,
            'quote_text' => $data['quote_text'],
            'author' => $data['author'] ?? 'Anonim',
            'display_date' => $data['display_date'] ?? null,
            'is_active' => isset($data['is_active']) ? (bool) $data['is_active'] : true
        ], 'Quote created successfully', 201);
    }

    /**
     * PUT /api/quotes/{id}
     * Update a quote
     */
    public function update($id) {
        // Check exists
        $stmt = $this->db->prepare("SELECT * FROM daily_quotes WHERE id = ?");
        $stmt->execute([$id]);
        $quote = $stmt->fetch();

        if (!$quote) {
            jsonError('Quote not found', 404);
        }

        $data = getJsonBody();
        if (empty($data)) {
            $data = $_POST;
        }

        $quoteText = $data['quote_text'] ?? $quote['quote_text'];
        $author = $data['author'] ?? $quote['author'];
        $displayDate = array_key_exists('display_date', $data) ? ($data['display_date'] ?: null) : $quote['display_date'];
        $isActive = isset($data['is_active']) ? (int) $data['is_active'] : $quote['is_active'];

        $stmt = $this->db->prepare(
            "UPDATE daily_quotes SET quote_text = ?, author = ?, display_date = ?, is_active = ? WHERE id = ?"
        );
        $stmt->execute([$quoteText, $author, $displayDate, $isActive, $id]);

        jsonSuccess([
            'id' => (int) $id,
            'quote_text' => $quoteText,
            'author' => $author,
            'display_date' => $displayDate,
            'is_active' => (bool) $isActive
        ], 'Quote updated successfully');
    }

    /**
     * DELETE /api/quotes/{id}
     * Delete a quote
     */
    public function delete($id) {
        $stmt = $this->db->prepare("SELECT id FROM daily_quotes WHERE id = ?");
        $stmt->execute([$id]);
        if (!$stmt->fetch()) {
            jsonError('Quote not found', 404);
        }

        $stmt = $this->db->prepare("DELETE FROM daily_quotes WHERE id = ?");
        $stmt->execute([$id]);

        jsonSuccess(null, 'Quote deleted successfully');
    }
}

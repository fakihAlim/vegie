<?php
/**
 * AI Settings Controller
 * LovingHarmony API
 */

require_once __DIR__ . '/../helpers/ai_key_manager.php';

class AiSettingsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * POST/GET /api/ai-settings/reset-stats
     * Resets daily usage statistics for all adaptive API Keys.
     */
    public function resetDailyStats() {
        try {
            $success = AiKeyManager::resetAllDailyStats($this->db);
            
            if ($success) {
                jsonSuccess(null, 'Statistik harian API Key berhasil di-reset.');
            } else {
                jsonError('Gagal me-reset statistik harian API Key.', 500);
            }
        } catch (Exception $e) {
            jsonError('Terjadi kesalahan: ' . $e->getMessage(), 500);
        }
    }
}

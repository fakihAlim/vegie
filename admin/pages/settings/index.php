<?php
/**
 * AI Configurations & API Key Management Dashboard
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Konfigurasi AI & Load Balancer';
require_once __DIR__ . '/../../includes/header.php';
require_once __DIR__ . '/../../../api/helpers/ai_key_manager.php';

$db = Database::getInstance()->getConnection();

// 1. Handle Reset Statistics
if (isset($_POST['reset_stats'])) {
    try {
        $success = AiKeyManager::resetAllDailyStats($db);
        if ($success) {
            $_SESSION['flash_success'] = 'Statistik harian untuk semua API Key berhasil di-reset ke nol!';
        } else {
            $_SESSION['flash_error'] = 'Gagal me-reset statistik harian.';
        }
    } catch (Exception $e) {
        $_SESSION['flash_error'] = 'Error: ' . $e->getMessage();
    }
    header('Location: index.php');
    exit;
}

// 2. Handle Save Settings (Model priorities + API keys)
if (isset($_POST['save_settings'])) {
    try {
        $db->beginTransaction();

        // Save Adaptive Key Management Flag
        $adaptiveVal = isset($_POST['adaptive_key_management']) ? '1' : '0';
        $stmt = $db->prepare("
            INSERT INTO ai_settings (setting_key, setting_value) 
            VALUES ('adaptive_key_management', ?)
            ON DUPLICATE KEY UPDATE setting_value = ?
        ");
        $stmt->execute([$adaptiveVal, $adaptiveVal]);

        // Process Dynamic API Keys
        $submittedKeys = $_POST['api_keys'] ?? [];
        $submittedIds = $_POST['key_ids'] ?? [];
        $keepIds = [];

        foreach ($submittedKeys as $index => $keyInput) {
            $keyInput = trim($keyInput);
            $keyId = isset($submittedIds[$index]) ? (int)$submittedIds[$index] : 0;

            if (!empty($keyInput)) {
                if ($keyId > 0) {
                    $keepIds[] = $keyId;
                    
                    // Fetch current stored key from database
                    $existStmt = $db->prepare("SELECT api_key FROM ai_gemini_keys WHERE id = ?");
                    $existStmt->execute([$keyId]);
                    $storedKeyRaw = $existStmt->fetchColumn();
                    
                    // Case A: User edited the API key (no asterisks in submission)
                    if (strpos($keyInput, '***') === false) {
                        $encryptedKey = AiKeyManager::encrypt($keyInput);
                        $updateStmt = $db->prepare("
                            UPDATE ai_gemini_keys 
                            SET api_key = ?, status = 'active', rpm_usage = 0, tpm_usage = 0, rpd_usage = 0, total_requests_today = 0
                            WHERE id = ?
                        ");
                        $updateStmt->execute([$encryptedKey, $keyId]);
                    } 
                    // Case B: User did not edit the key (contains asterisks), but it is plaintext in the DB
                    else {
                        $decrypted = AiKeyManager::decrypt($storedKeyRaw);
                        if ($decrypted === $storedKeyRaw) {
                            // Decrypted equals raw, meaning it's plaintext. Let's encrypt it!
                            $encryptedKey = AiKeyManager::encrypt($storedKeyRaw);
                            $updateStmt = $db->prepare("UPDATE ai_gemini_keys SET api_key = ? WHERE id = ?");
                            $updateStmt->execute([$encryptedKey, $keyId]);
                        }
                    }
                } else {
                    // New key insert
                    if (strpos($keyInput, '***') === false) {
                        $encryptedKey = AiKeyManager::encrypt($keyInput);
                        $insertStmt = $db->prepare("
                            INSERT INTO ai_gemini_keys (api_key, status, rpm_limit, tpm_limit, rpd_limit)
                            VALUES (?, 'active', 15, 250000, 500)
                        ");
                        $insertStmt->execute([$encryptedKey]);
                        $keepIds[] = $db->lastInsertId();
                    }
                }
            }
        }

        // Delete keys that were removed in the UI
        if (!empty($keepIds)) {
            $inClause = implode(',', array_fill(0, count($keepIds), '?'));
            $deleteStmt = $db->prepare("DELETE FROM ai_gemini_keys WHERE id NOT IN ($inClause)");
            $deleteStmt->execute($keepIds);
        } else {
            $db->query("DELETE FROM ai_gemini_keys");
        }

        // Process Model priorities fallback order
        $modelOrder = $_POST['model_order'] ?? '';
        if (!empty($modelOrder)) {
            $orderList = explode(',', $modelOrder);
            $activeModels = $_POST['model_active'] ?? []; // Array of model_keys that are checked/active
            
            foreach ($orderList as $index => $modelKey) {
                $priority = $index + 1;
                $isActive = in_array($modelKey, $activeModels) ? 1 : 0;
                
                $updateModelStmt = $db->prepare("
                    UPDATE ai_model_priorities 
                    SET priority_order = ?, is_active = ? 
                    WHERE model_key = ?
                ");
                $updateModelStmt->execute([$priority, $isActive, $modelKey]);
            }
        }

        $db->commit();
        $_SESSION['flash_success'] = 'Konfigurasi AI dan prioritas fallback model berhasil disimpan!';
    } catch (Exception $e) {
        $db->rollBack();
        $_SESSION['flash_error'] = 'Gagal menyimpan konfigurasi: ' . $e->getMessage();
    }
    header('Location: index.php');
    exit;
}

// 3. Fetch Settings & Models Priority List
$adaptiveEnabled = AiKeyManager::isAdaptiveEnabled($db);

// Fetch current keys from DB
$keysList = AiKeyManager::getActiveKeys($db); // Also refreshes expired windows automatically!

// Fetch models order
$modelStmt = $db->query("SELECT * FROM ai_model_priorities ORDER BY priority_order ASC");
$models = $modelStmt->fetchAll(PDO::FETCH_ASSOC);

// Progress bar color selector function
function getBarColorClass($pct) {
    if ($pct >= 100) return 'bar-danger';
    if ($pct > 90) return 'bar-warning';
    return 'bar-active';
}
?>

<style>
    .settings-container {
        display: grid;
        grid-template-columns: 1.2fr 0.8fr;
        gap: 24px;
    }
    @media (max-width: 1024px) {
        .settings-container {
            grid-template-columns: 1fr;
        }
    }

    /* Drag & Drop Reordering Styles */
    .priority-list {
        display: flex;
        flex-direction: column;
        gap: 12px;
        margin-top: 16px;
    }
    .priority-item {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius-sm);
        padding: 12px 16px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        cursor: grab;
        transition: var(--transition);
        user-select: none;
        box-shadow: var(--shadow-sm);
    }
    .priority-item:active {
        cursor: grabbing;
    }
    .priority-item.over {
        border: 2px dashed var(--primary);
        background: var(--accent-lighter);
        transform: scale(0.99);
    }
    .priority-item-left {
        display: flex;
        align-items: center;
        gap: 12px;
    }
    .drag-handle {
        color: var(--text-muted);
        cursor: grab;
        font-size: 18px;
    }
    .priority-badge {
        width: 24px;
        height: 24px;
        border-radius: 50%;
        background: var(--primary-dark);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
        font-weight: bold;
    }
    .priority-item-actions {
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .btn-arrow {
        background: var(--border-light);
        border: 1px solid var(--border);
        border-radius: 4px;
        width: 28px;
        height: 28px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: var(--transition);
        color: var(--text-secondary);
    }
    .btn-arrow:hover {
        background: var(--accent-light);
        color: var(--primary-dark);
    }

    /* Form Styles */
    .switch-container {
        display: flex;
        align-items: center;
        justify-content: space-between;
        background: var(--accent-lighter);
        border: 1px solid var(--accent-light);
        border-radius: var(--radius);
        padding: 16px;
        margin-bottom: 24px;
    }
    .form-switch {
        position: relative;
        display: inline-block;
        width: 50px;
        height: 26px;
    }
    .form-switch input {
        opacity: 0;
        width: 0;
        height: 0;
    }
    .slider {
        position: absolute;
        cursor: pointer;
        top: 0; left: 0; right: 0; bottom: 0;
        background-color: var(--text-muted);
        transition: .4s;
        border-radius: 34px;
    }
    .slider:before {
        position: absolute;
        content: "";
        height: 18px;
        width: 18px;
        left: 4px;
        bottom: 4px;
        background-color: white;
        transition: .4s;
        border-radius: 50%;
    }
    input:checked + .slider {
        background-color: var(--primary);
    }
    input:checked + .slider:before {
        transform: translateX(24px);
    }

    /* Key Management Fields */
    .key-input-group {
        display: flex;
        flex-direction: column;
        gap: 16px;
        margin-bottom: 24px;
    }
    .key-field {
        position: relative;
    }
    .key-field label {
        font-weight: 600;
        font-size: 13px;
        color: var(--text-secondary);
        display: block;
        margin-bottom: 6px;
    }

    /* Usage Monitoring Grid */
    .monitoring-grid {
        display: flex;
        flex-direction: column;
        gap: 20px;
        margin-top: 16px;
    }
    .monitor-card {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        padding: 20px;
        box-shadow: var(--shadow-sm);
        transition: var(--transition);
        position: relative;
        overflow: hidden;
    }
    .monitor-card:hover {
        box-shadow: var(--shadow-md);
    }
    .monitor-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 16px;
        padding-bottom: 12px;
        border-bottom: 1px solid var(--border-light);
    }
    .monitor-title {
        font-weight: bold;
        font-size: 15px;
        color: var(--text-primary);
        font-family: 'Poppins', sans-serif;
    }
    .usage-item {
        margin-bottom: 12px;
    }
    .usage-label-row {
        display: flex;
        justify-content: space-between;
        font-size: 12px;
        color: var(--text-secondary);
        margin-bottom: 4px;
    }
    .usage-progress {
        background: var(--border-light);
        border-radius: 999px;
        height: 8px;
        overflow: hidden;
    }
    .usage-bar {
        height: 100%;
        border-radius: 999px;
        transition: width 0.5s ease-in-out;
    }
    .bar-active { background: var(--success); }
    .bar-warning { background: var(--warning); }
    .bar-danger { background: var(--error); }
</style>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">⚙️ Konfigurasi Model AI & Load Balancer</span>
            <div class="user-menu" style="display: flex; gap: 12px;">
                <a href="logs.php" class="btn btn-secondary btn-sm">
                    <i class="bi bi-journal-text"></i> Lihat Log Aktivitas AI
                </a>
            </div>
        </div>

        <div class="content-area">
            <!-- Flash Alert Notifications -->
            <?php if (isset($_SESSION['flash_success'])): ?>
                <div class="alert alert-success" style="margin-bottom: 24px;">
                    <i class="bi bi-check-circle-fill"></i>
                    <div><?= $_SESSION['flash_success']; unset($_SESSION['flash_success']); ?></div>
                </div>
            <?php endif; ?>

            <?php if (isset($_SESSION['flash_error'])): ?>
                <div class="alert alert-error" style="margin-bottom: 24px;">
                    <i class="bi bi-exclamation-triangle-fill"></i>
                    <div><?= $_SESSION['flash_error']; unset($_SESSION['flash_error']); ?></div>
                </div>
            <?php endif; ?>

            <form method="POST" action="" id="settingsForm">
                <div class="settings-container">
                    <!-- Left Column: Settings Configuration -->
                    <div>
                        <!-- Section: Fallback Model Priorities -->
                        <div class="card mb-3">
                            <div class="card-header">
                                <h3><i class="bi bi-shuffle" style="color: var(--primary); margin-right: 8px;"></i> Urutan Prioritas Model AI (Fallback Chain)</h3>
                                <span class="text-muted" style="font-size: 12px;">Seret baris atau gunakan tombol panah untuk mengatur prioritas</span>
                            </div>
                            <div class="card-body">
                                <p class="text-muted" style="font-size: 13px; margin-bottom: 16px;">
                                    Saat aplikasi meminta analisis nutrisi, sistem akan mencoba memanggil model pertama. Jika gagal, timeout, atau quota habis, sistem akan secara otomatis melompat ke model berikutnya sesuai urutan prioritas di bawah ini.
                                </p>
                                
                                <div class="priority-list" id="priorityListContainer">
                                    <?php foreach ($models as $idx => $model): ?>
                                        <div class="priority-item" draggable="true" data-key="<?= htmlspecialchars($model['model_key']) ?>">
                                            <div class="priority-item-left">
                                                <span class="drag-handle"><i class="bi bi-grip-vertical"></i></span>
                                                <span class="priority-badge"><?= $idx + 1 ?></span>
                                                <div>
                                                    <strong><?= htmlspecialchars($model['model_name']) ?></strong>
                                                    <div style="font-size: 11px; color: var(--text-secondary); margin-top: 2px;">
                                                        Identifier: <code><?= htmlspecialchars($model['model_key']) ?></code>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="priority-item-actions" onclick="event.stopPropagation();">
                                                <label style="display: flex; align-items: center; gap: 6px; margin-right: 12px; cursor: pointer; font-size: 13px;">
                                                    <input type="checkbox" name="model_active[]" value="<?= htmlspecialchars($model['model_key']) ?>" <?= $model['is_active'] ? 'checked' : '' ?> style="cursor: pointer; width: 16px; height: 16px;">
                                                    Aktif
                                                </label>
                                                <button type="button" class="btn-arrow btn-up" title="Naikkan"><i class="bi bi-chevron-up"></i></button>
                                                <button type="button" class="btn-arrow btn-down" title="Turunkan"><i class="bi bi-chevron-down"></i></button>
                                            </div>
                                        </div>
                                    <?php endforeach; ?>
                                </div>
                                <input type="hidden" name="model_order" id="modelOrderInput" value="<?= implode(',', array_column($models, 'model_key')) ?>">
                            </div>
                        </div>

                        <!-- Section: Adaptive Gemini API Key Management -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="bi bi-key-fill" style="color: var(--primary); margin-right: 8px;"></i> Adaptive Gemini API Key Management</h3>
                            </div>
                            <div class="card-body">
                                <div class="switch-container">
                                    <div>
                                        <strong>Opsi "Adaptive API Key Management"</strong>
                                        <p class="text-muted" style="font-size: 12px; margin-top: 4px; margin-bottom: 0;">
                                            Khusus untuk model Gemini 3.1 Flash Lite. Balancer pintar akan mendistribusikan penggunaan di antara key yang tersedia berdasarkan persentase limit terendah.
                                        </p>
                                    </div>
                                    <label class="form-switch">
                                        <input type="checkbox" name="adaptive_key_management" value="1" <?= $adaptiveEnabled ? 'checked' : '' ?>>
                                        <span class="slider"></span>
                                    </label>
                                </div>

                                <h4 style="font-size: 14px; margin-bottom: 12px; color: var(--text-primary);">Google API Keys</h4>
                                <div class="key-input-group" id="keysContainer">
                                    <?php 
                                    // If no keys in list, ensure we display at least one empty field
                                    $displayList = !empty($keysList) ? $keysList : [['id' => 0, 'api_key' => '']];
                                    foreach ($displayList as $keyObj): 
                                        $maskedVal = $keyObj['id'] > 0 ? AiKeyManager::maskKey($keyObj['api_key']) : '';
                                        $keyId = $keyObj['id'];
                                    ?>
                                        <div class="key-field-row" style="display: flex; gap: 8px; align-items: flex-end; margin-bottom: 12px;">
                                            <div class="key-field" style="flex: 1;">
                                                <div class="input-group">
                                                    <span class="input-icon"><i class="bi bi-shield-lock"></i></span>
                                                    <input type="text" name="api_keys[]" value="<?= htmlspecialchars($maskedVal) ?>" placeholder="Masukkan Google API Key (AIzaSy...)" class="form-control" autocomplete="off" style="font-family: monospace;">
                                                    <input type="hidden" name="key_ids[]" value="<?= $keyId ?>">
                                                </div>
                                            </div>
                                            <button type="button" class="btn btn-danger" style="padding: 10px 14px; border-radius: 8px; height: 46px;" onclick="removeKeyRow(this)">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </div>
                                    <?php endforeach; ?>
                                </div>
                                <button type="button" class="btn btn-secondary btn-sm" id="btnAddKey" style="margin-top: 8px; display: inline-flex; align-items: center; gap: 6px;">
                                    <i class="bi bi-plus-circle"></i> Tambah API Key
                                </button>
                            </div>
                        </div>

                        <!-- Action Submit Button -->
                        <div style="margin-top: 24px;">
                            <button type="submit" name="save_settings" value="1" class="btn btn-primary btn-lg btn-block" style="border-radius: var(--radius);">
                                <i class="bi bi-cloud-check-fill"></i> Simpan Semua Konfigurasi
                            </button>
                        </div>
                    </div>

                    <!-- Right Column: Live Usage Monitoring Dashboard -->
                    <div>
                        <div class="card" style="position: sticky; top: 90px;">
                            <div class="card-header">
                                <h3><i class="bi bi-activity" style="color: var(--primary); margin-right: 8px;"></i> Live API Key Monitor</h3>
                                <button type="button" onclick="confirmReset()" class="btn btn-secondary btn-sm" style="padding: 4px 10px; font-size: 11px;">
                                    <i class="bi bi-arrow-counterclockwise"></i> Reset Statistik
                                </button>
                            </div>
                            <div class="card-body">
                                <p class="text-muted" style="font-size: 12px; margin-bottom: 16px;">
                                    Monitoring penggunaan limit dari masing-masing API Key secara real-time. Jika key menyentuh 100%, sistem akan menolak menggunakannya sampai menit/hari berikutnya dimulai.
                                </p>

                                <div class="monitoring-grid">
                                    <?php 
                                    $hasKeys = false;
                                    foreach ($keysList as $keyObj): 
                                        $hasKeys = true;
                                        
                                        $maskedKey = AiKeyManager::maskKey($keyObj['api_key']);
                                        
                                        // Calculate percentage usages
                                        $rpmPct = min(100, round(($keyObj['rpm_usage'] / $keyObj['rpm_limit']) * 100, 1));
                                        $tpmPct = min(100, round(($keyObj['tpm_usage'] / $keyObj['tpm_limit']) * 100, 1));
                                        $rpdPct = min(100, round(($keyObj['rpd_usage'] / $keyObj['rpd_limit']) * 100, 1));
                                        
                                        // Set status badge colors
                                        $statusClass = 'badge-success';
                                        $statusLabel = 'ACTIVE';
                                        if ($keyObj['status'] === 'temporarily_unavailable' || $keyObj['status'] === 'blocked') {
                                            $statusClass = 'badge-danger';
                                            $statusLabel = 'BLOCKED / EXHAUSTED';
                                        } elseif ($keyObj['status'] === 'near_limit' || $rpmPct > 90 || $tpmPct > 90 || $rpdPct > 90) {
                                            $statusClass = 'badge-warning';
                                            $statusLabel = 'NEAR LIMIT';
                                        }

                                         // Progress bar color class is resolved via global function
                                    ?>
                                        <div class="monitor-card">
                                            <div class="monitor-header">
                                                <span class="monitor-title"><i class="bi bi-key"></i> Key: <code><?= htmlspecialchars($maskedKey) ?></code></span>
                                                <span class="badge <?= $statusClass ?>" style="font-size: 10px; font-weight: bold;"><?= $statusLabel ?></span>
                                            </div>
                                            
                                            <!-- RPM Bar -->
                                            <div class="usage-item">
                                                <div class="usage-label-row">
                                                    <span>Requests Per Minute (RPM)</span>
                                                    <strong><?= $keyObj['rpm_usage'] ?> / <?= $keyObj['rpm_limit'] ?> (<?= $rpmPct ?>%)</strong>
                                                </div>
                                                <div class="usage-progress">
                                                    <div class="usage-bar <?= getBarColorClass($rpmPct) ?>" style="width: <?= $rpmPct ?>%"></div>
                                                </div>
                                            </div>

                                            <!-- TPM Bar -->
                                            <div class="usage-item">
                                                <div class="usage-label-row">
                                                    <span>Tokens Per Minute (TPM)</span>
                                                    <strong><?= number_format($keyObj['tpm_usage']) ?> / <?= number_format($keyObj['tpm_limit']) ?> (<?= $tpmPct ?>%)</strong>
                                                </div>
                                                <div class="usage-progress">
                                                    <div class="usage-bar <?= getBarColorClass($tpmPct) ?>" style="width: <?= $tpmPct ?>%"></div>
                                                </div>
                                            </div>

                                            <!-- RPD Bar -->
                                            <div class="usage-item" style="margin-bottom: 16px;">
                                                <div class="usage-label-row">
                                                    <span>Requests Per Day (RPD)</span>
                                                    <strong><?= $keyObj['rpd_usage'] ?> / <?= $keyObj['rpd_limit'] ?> (<?= $rpdPct ?>%)</strong>
                                                </div>
                                                <div class="usage-progress">
                                                    <div class="usage-bar <?= getBarColorClass($rpdPct) ?>" style="width: <?= $rpdPct ?>%"></div>
                                                </div>
                                            </div>

                                            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; font-size: 11px; padding-top: 10px; border-top: 1px dashed var(--border);">
                                                <div>
                                                    <span class="text-muted">Requests Today:</span> <strong style="color: var(--primary-dark);"><?= $keyObj['total_requests_today'] ?> req</strong>
                                                </div>
                                                <div class="text-right">
                                                    <span class="text-muted">Last Used:</span> <strong><?= $keyObj['last_used_at'] ? date('H:i:s', strtotime($keyObj['last_used_at'])) : 'Never' ?></strong>
                                                </div>
                                            </div>
                                        </div>
                                    <?php endforeach; ?>

                                    <?php if (!$hasKeys): ?>
                                        <div class="empty-state" style="padding: 24px;">
                                            <div class="empty-icon" style="font-size: 32px;">🔑</div>
                                            <p style="font-size: 13px;">Belum ada Google API Key terdaftar. Masukkan di formulir sebelah kiri untuk memulai load balancer.</p>
                                        </div>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </main>
</div>

<!-- Hidden Form for resetting statistics -->
<form method="POST" action="" id="resetStatsForm" style="display: none;">
    <input type="hidden" name="reset_stats" value="1">
</form>

<script>
    // Drag and Drop Logic
    const listItems = document.querySelectorAll('.priority-item');
    const container = document.getElementById('priorityListContainer');
    let dragSrcEl = null;

    function initDragAndDrop() {
        listItems.forEach(item => {
            item.addEventListener('dragstart', handleDragStart, false);
            item.addEventListener('dragenter', handleDragEnter, false);
            item.addEventListener('dragover', handleDragOver, false);
            item.addEventListener('dragleave', handleDragLeave, false);
            item.addEventListener('drop', handleDrop, false);
            item.addEventListener('dragend', handleDragEnd, false);
        });
    }

    function handleDragStart(e) {
        this.style.opacity = '0.4';
        dragSrcEl = this;
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/html', this.innerHTML);
    }

    function handleDragOver(e) {
        if (e.preventDefault) {
            e.preventDefault();
        }
        e.dataTransfer.dropEffect = 'move';
        return false;
    }

    function handleDragEnter(e) {
        this.classList.add('over');
    }

    function handleDragLeave(e) {
        this.classList.remove('over');
    }

    function handleDrop(e) {
        if (e.stopPropagation) {
            e.stopPropagation();
        }
        
        if (dragSrcEl !== this) {
            let parent = this.parentNode;
            let children = Array.from(parent.children);
            let srcIndex = children.indexOf(dragSrcEl);
            let destIndex = children.indexOf(this);
            
            if (srcIndex < destIndex) {
                parent.insertBefore(dragSrcEl, this.nextSibling);
            } else {
                parent.insertBefore(dragSrcEl, this);
            }
            
            recalculateBadges();
            updateHiddenInput();
        }
        return false;
    }

    function handleDragEnd(e) {
        this.style.opacity = '1';
        listItems.forEach(item => {
            item.classList.remove('over');
        });
    }

    // Up / Down Button Logic
    document.querySelectorAll('.btn-up').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            const row = this.closest('.priority-item');
            const prev = row.previousElementSibling;
            if (prev) {
                row.parentNode.insertBefore(row, prev);
                recalculateBadges();
                updateHiddenInput();
            }
        });
    });

    document.querySelectorAll('.btn-down').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            const row = this.closest('.priority-item');
            const next = row.nextElementSibling;
            if (next) {
                row.parentNode.insertBefore(next, row);
                recalculateBadges();
                updateHiddenInput();
            }
        });
    });

    function recalculateBadges() {
        const badges = document.querySelectorAll('.priority-badge');
        badges.forEach((badge, index) => {
            badge.innerText = index + 1;
        });
    }

    function updateHiddenInput() {
        const items = document.querySelectorAll('.priority-item');
        const keys = Array.from(items).map(item => item.getAttribute('data-key'));
        document.getElementById('modelOrderInput').value = keys.join(',');
    }

    function confirmReset() {
        if (confirm('Apakah Anda yakin ingin mereset statistik penggunaan seluruh API Key hari ini? Tindakan ini akan mengaktifkan kembali semua key yang terblokir.')) {
            document.getElementById('resetStatsForm').submit();
        }
    }

    // Dynamic API Keys Handling
    document.getElementById('btnAddKey').addEventListener('click', function() {
        const container = document.getElementById('keysContainer');
        const row = document.createElement('div');
        row.className = 'key-field-row';
        row.style.display = 'flex';
        row.style.gap = '8px';
        row.style.alignItems = 'flex-end';
        row.style.marginBottom = '12px';
        
        row.innerHTML = `
            <div class="key-field" style="flex: 1;">
                <div class="input-group">
                    <span class="input-icon"><i class="bi bi-shield-lock"></i></span>
                    <input type="text" name="api_keys[]" value="" placeholder="Masukkan Google API Key (AIzaSy...)" class="form-control" autocomplete="off" style="font-family: monospace;">
                    <input type="hidden" name="key_ids[]" value="0">
                </div>
            </div>
            <button type="button" class="btn btn-danger" style="padding: 10px 14px; border-radius: 8px; height: 46px;" onclick="removeKeyRow(this)">
                <i class="bi bi-trash"></i>
            </button>
        `;
        container.appendChild(row);
    });

    function removeKeyRow(button) {
        const row = button.closest('.key-field-row');
        row.remove();
        
        const container = document.getElementById('keysContainer');
        if (container.children.length === 0) {
            document.getElementById('btnAddKey').click();
        }
    }

    // Init onload
    initDragAndDrop();
</script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

<?php
/**
 * AI Activity Logs
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Log Aktivitas AI';
require_once __DIR__ . '/../../includes/header.php';
require_once __DIR__ . '/../../../api/helpers/ai_key_manager.php';

$db = Database::getInstance()->getConnection();

// --- 1. Filtering & Pagination Config ---
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 20;
$offset = ($page - 1) * $limit;

$startDate = $_GET['start_date'] ?? '';
$endDate = $_GET['end_date'] ?? '';
$model = $_GET['model'] ?? '';
$status = $_GET['status'] ?? '';

// Build Query
$whereClauses = [];
$params = [];

if (!empty($startDate)) {
    $whereClauses[] = "DATE(l.created_at) >= ?";
    $params[] = $startDate;
}
if (!empty($endDate)) {
    $whereClauses[] = "DATE(l.created_at) <= ?";
    $params[] = $endDate;
}
if (!empty($model)) {
    $whereClauses[] = "l.model_used = ?";
    $params[] = $model;
}
if (!empty($status)) {
    $whereClauses[] = "l.status = ?";
    $params[] = $status;
}

$whereSql = "";
if (!empty($whereClauses)) {
    $whereSql = "WHERE " . implode(" AND ", $whereClauses);
}

// Fetch Count for Pagination
$countQuery = "
    SELECT COUNT(*) as count 
    FROM ai_usage_logs l
    $whereSql
";
$stmt = $db->prepare($countQuery);
$stmt->execute($params);
$totalRecords = $stmt->fetch()['count'];
$totalPages = ceil($totalRecords / $limit);

// Fetch Paginated Logs
$logsQuery = "
    SELECT l.*, u.name as user_name, u.email as user_email
    FROM ai_usage_logs l
    LEFT JOIN users u ON l.user_id = u.id
    $whereSql
    ORDER BY l.created_at DESC
    LIMIT ? OFFSET ?
";

// Execute query with offset/limit
$stmt = $db->prepare($logsQuery);
$execParams = array_merge($params, [$limit, $offset]);
$stmt->execute($execParams);
$logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Fetch Unique Models for filter dropdown
$modelsQuery = "SELECT DISTINCT model_used FROM ai_usage_logs ORDER BY model_used ASC";
$modelsList = $db->query($modelsQuery)->fetchAll(PDO::FETCH_COLUMN);
?>

<style>
    .filter-card {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        padding: 20px;
        margin-bottom: 24px;
        box-shadow: var(--shadow-sm);
    }
    .filter-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)) 120px;
        gap: 16px;
        align-items: flex-end;
    }
    @media (max-width: 768px) {
        .filter-grid {
            grid-template-columns: 1fr;
            align-items: stretch;
        }
    }
    
    .fallback-cell {
        max-width: 250px;
        word-wrap: break-word;
        font-size: 12px;
        color: var(--text-secondary);
        font-family: monospace;
    }

    /* Pagination Styles */
    .pagination-container {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-top: 24px;
        padding-top: 16px;
        border-top: 1px solid var(--border);
    }
    .pagination-list {
        display: flex;
        gap: 6px;
        list-style: none;
    }
    .page-link {
        padding: 8px 14px;
        border: 1px solid var(--border);
        background: var(--surface);
        color: var(--text-primary);
        border-radius: 6px;
        font-size: 13px;
        font-weight: 500;
        transition: var(--transition);
    }
    .page-link:hover {
        background: var(--accent-light);
        color: var(--primary-dark);
    }
    .pagination-item.active .page-link {
        background: var(--primary);
        color: white;
        border-color: var(--primary);
    }
</style>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">📊 Log Aktivitas Pemanggilan AI</span>
            <div class="user-menu" style="display: flex; gap: 12px;">
                <a href="index.php" class="btn btn-secondary btn-sm">
                    <i class="bi bi-gear-fill"></i> Konfigurasi AI & Keys
                </a>
            </div>
        </div>

        <div class="content-area">
            <!-- Filter Bar Card -->
            <div class="filter-card">
                <form method="GET" action="">
                    <div class="filter-grid">
                        <div class="form-group" style="margin-bottom: 0;">
                            <label style="font-size: 11px; font-weight: 600; color: var(--text-secondary);">Dari Tanggal</label>
                            <input type="date" name="start_date" value="<?= htmlspecialchars($startDate) ?>" class="form-control" style="padding: 8px 12px; font-size: 13px;">
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <label style="font-size: 11px; font-weight: 600; color: var(--text-secondary);">Sampai Tanggal</label>
                            <input type="date" name="end_date" value="<?= htmlspecialchars($endDate) ?>" class="form-control" style="padding: 8px 12px; font-size: 13px;">
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <label style="font-size: 11px; font-weight: 600; color: var(--text-secondary);">Model AI</label>
                            <select name="model" class="form-control" style="padding: 8px 12px; font-size: 13px;">
                                <option value="">Semua Model</option>
                                <?php foreach ($modelsList as $m): ?>
                                    <option value="<?= htmlspecialchars($m) ?>" <?= $model === $m ? 'selected' : '' ?>><?= htmlspecialchars($m) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <label style="font-size: 11px; font-weight: 600; color: var(--text-secondary);">Status</label>
                            <select name="status" class="form-control" style="padding: 8px 12px; font-size: 13px;">
                                <option value="">Semua Status</option>
                                <option value="success" <?= $status === 'success' ? 'selected' : '' ?>>Success</option>
                                <option value="fallback" <?= $status === 'fallback' ? 'selected' : '' ?>>Fallback</option>
                                <option value="failed" <?= $status === 'failed' ? 'selected' : '' ?>>Failed</option>
                            </select>
                        </div>
                        <div style="display: flex; gap: 8px;">
                            <button type="submit" class="btn btn-primary" style="flex: 1; padding: 10px; border-radius: 6px; font-size: 13px;">
                                <i class="bi bi-filter"></i> Filter
                            </button>
                            <a href="logs.php" class="btn btn-secondary" style="padding: 10px; border-radius: 6px;" title="Reset Filter">
                                <i class="bi bi-x-circle"></i>
                            </a>
                        </div>
                    </div>
                </form>
            </div>

            <!-- Logs Table -->
            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($logs)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">📁</div>
                            <p>Tidak ada log aktivitas AI yang sesuai dengan kriteria filter.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>Waktu</th>
                                        <th>User</th>
                                        <th>Model</th>
                                        <th>API Key</th>
                                        <th class="text-center">Token</th>
                                        <th class="text-center">Waktu Respons</th>
                                        <th class="text-center">Status</th>
                                        <th>Alasan Fallback / Gagal</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($logs as $log): 
                                        $statusClass = 'badge-success';
                                        $statusLabel = 'SUCCESS';
                                        if ($log['status'] === 'failed') {
                                            $statusClass = 'badge-danger';
                                            $statusLabel = 'FAILED';
                                        } elseif ($log['status'] === 'fallback') {
                                            $statusClass = 'badge-warning';
                                            $statusLabel = 'FALLBACK';
                                        }
                                    ?>
                                        <tr>
                                            <td style="font-size: 13px; font-weight: 500; white-space: nowrap;">
                                                <?= date('d M Y H:i:s', strtotime($log['created_at'])) ?>
                                            </td>
                                            <td style="font-size: 13px;">
                                                <?php if ($log['user_id']): ?>
                                                    <strong><?= htmlspecialchars($log['user_name']) ?></strong><br>
                                                    <span class="text-muted" style="font-size: 11px;"><?= htmlspecialchars($log['user_email']) ?></span>
                                                <?php else: ?>
                                                    <span class="text-muted" style="font-style: italic;">Sistem / Admin</span>
                                                <?php endif; ?>
                                            </td>
                                            <td style="font-size: 13px; font-weight: bold; color: var(--primary-dark);">
                                                <code><?= htmlspecialchars($log['model_used']) ?></code>
                                            </td>
                                            <td style="font-size: 13px; font-family: monospace;">
                                                <?= $log['api_key_used'] ? htmlspecialchars($log['api_key_used']) : '<span class="text-muted">-</span>' ?>
                                            </td>
                                            <td class="text-center" style="font-weight: bold; color: #1e3a5f;">
                                                <?= $log['tokens_used'] > 0 ? number_format($log['tokens_used']) : '<span class="text-muted">-</span>' ?>
                                            </td>
                                            <td class="text-center" style="font-weight: 600;">
                                                <?= $log['response_time'] > 0 ? $log['response_time'] . ' s' : '<span class="text-muted">-</span>' ?>
                                            </td>
                                            <td class="text-center">
                                                <span class="badge <?= $statusClass ?>" style="font-size: 11px; font-weight: bold;"><?= $statusLabel ?></span>
                                            </td>
                                            <td class="fallback-cell">
                                                <?php if (!empty($log['fallback_reason'])): ?>
                                                    <div style="cursor: pointer; max-height: 48px; overflow: hidden; text-overflow: ellipsis;" onclick="alert(this.innerText)" title="Klik untuk membaca selengkapnya">
                                                        <?= htmlspecialchars($log['fallback_reason']) ?>
                                                    </div>
                                                <?php else: ?>
                                                    <span class="text-muted" style="font-style: italic;">-</span>
                                                <?php endif; ?>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php endif; ?>
                </div>
            </div>

            <!-- Pagination Row -->
            <?php if ($totalPages > 1): ?>
                <div class="pagination-container">
                    <span class="text-muted" style="font-size: 13px;">
                        Menampilkan <?= min($totalRecords, $offset + 1) ?> - <?= min($totalRecords, $offset + $limit) ?> dari total <strong><?= $totalRecords ?></strong> log.
                    </span>
                    <ul class="pagination-list">
                        <!-- Previous Page -->
                        <?php if ($page > 1): ?>
                            <li class="pagination-item">
                                <a href="?page=<?= $page - 1 ?>&start_date=<?= urlencode($startDate) ?>&end_date=<?= urlencode($endDate) ?>&model=<?= urlencode($model) ?>&status=<?= urlencode($status) ?>" class="page-link">&laquo; Prev</a>
                            </li>
                        <?php endif; ?>

                        <!-- Page Numbers -->
                        <?php
                        $startPage = max(1, $page - 2);
                        $endPage = min($totalPages, $page + 2);
                        for ($i = $startPage; $i <= $endPage; $i++):
                        ?>
                            <li class="pagination-item <?= $page === $i ? 'active' : '' ?>">
                                <a href="?page=<?= $i ?>&start_date=<?= urlencode($startDate) ?>&end_date=<?= urlencode($endDate) ?>&model=<?= urlencode($model) ?>&status=<?= urlencode($status) ?>" class="page-link"><?= $i ?></a>
                            </li>
                        <?php endfor; ?>

                        <!-- Next Page -->
                        <?php if ($page < $totalPages): ?>
                            <li class="pagination-item">
                                <a href="?page=<?= $page + 1 ?>&start_date=<?= urlencode($startDate) ?>&end_date=<?= urlencode($endDate) ?>&model=<?= urlencode($model) ?>&status=<?= urlencode($status) ?>" class="page-link">Next &raquo;</a>
                            </li>
                        <?php endif; ?>
                    </ul>
                </div>
            <?php endif; ?>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

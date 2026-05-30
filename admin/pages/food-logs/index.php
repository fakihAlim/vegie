<?php
/**
 * Food Logs Management - List
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Food Logs';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Filters
$filterUser = $_GET['user'] ?? '';
$filterCategory = $_GET['category'] ?? '';
$filterDate = $_GET['date'] ?? '';

$where = "1=1";
$params = [];

if ($filterUser) {
    $where .= " AND u.name LIKE ?";
    $params[] = "%$filterUser%";
}
if ($filterCategory) {
    $where .= " AND fl.category = ?";
    $params[] = $filterCategory;
}
if ($filterDate) {
    $where .= " AND DATE(fl.meal_time) = ?";
    $params[] = $filterDate;
}

$stmt = $db->prepare(
    "SELECT fl.*, u.name as user_name 
     FROM food_logs fl 
     INNER JOIN users u ON fl.user_id = u.id 
     WHERE $where
     ORDER BY fl.created_at DESC 
     LIMIT 100"
);
$stmt->execute($params);
$logs = $stmt->fetchAll();

// Stats
$stmtTotal = $db->query("SELECT COUNT(*) as total FROM food_logs");
$totalLogs = $stmtTotal->fetch()['total'];

$stmtAnalyzed = $db->query("SELECT COUNT(*) as total FROM food_logs WHERE calories IS NOT NULL");
$analyzedLogs = $stmtAnalyzed->fetch()['total'];
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">📊 Food Logs</span>
            <div class="user-menu">
                <span class="text-muted">Total: <strong><?= number_format($totalLogs) ?></strong> logs</span>
                &nbsp;|&nbsp;
                <span class="text-muted">Analyzed: <strong><?= number_format($analyzedLogs) ?></strong></span>
            </div>
        </div>

        <div class="content-area">
            <!-- Filters -->
            <div class="card" style="margin-bottom: 20px;">
                <div class="card-body">
                    <form method="GET" style="display: flex; gap: 12px; align-items: flex-end; flex-wrap: wrap;">
                        <div style="flex: 1; min-width: 150px;">
                            <label style="display: block; font-size: 12px; font-weight: 600; margin-bottom: 4px; color: var(--text-muted);">User</label>
                            <input type="text" name="user" value="<?= htmlspecialchars($filterUser) ?>" placeholder="Cari nama user..." 
                                   style="width: 100%; padding: 8px 12px; border: 1px solid var(--border); border-radius: 8px; font-size: 14px;">
                        </div>
                        <div style="min-width: 140px;">
                            <label style="display: block; font-size: 12px; font-weight: 600; margin-bottom: 4px; color: var(--text-muted);">Kategori</label>
                            <select name="category" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border); border-radius: 8px; font-size: 14px;">
                                <option value="">Semua</option>
                                <option value="breakfast" <?= $filterCategory === 'breakfast' ? 'selected' : '' ?>>Breakfast</option>
                                <option value="lunch" <?= $filterCategory === 'lunch' ? 'selected' : '' ?>>Lunch</option>
                                <option value="dinner" <?= $filterCategory === 'dinner' ? 'selected' : '' ?>>Dinner</option>
                                <option value="snack" <?= $filterCategory === 'snack' ? 'selected' : '' ?>>Snack</option>
                            </select>
                        </div>
                        <div style="min-width: 140px;">
                            <label style="display: block; font-size: 12px; font-weight: 600; margin-bottom: 4px; color: var(--text-muted);">Tanggal</label>
                            <input type="date" name="date" value="<?= htmlspecialchars($filterDate) ?>" 
                                   style="width: 100%; padding: 8px 12px; border: 1px solid var(--border); border-radius: 8px; font-size: 14px;">
                        </div>
                        <div>
                            <button type="submit" class="btn btn-primary btn-sm"><i class="bi bi-search"></i> Filter</button>
                            <a href="index.php" class="btn btn-sm btn-secondary">Reset</a>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Food Logs Table -->
            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($logs)): ?>
                        <div class="empty-state" style="padding: 40px;">
                            <div class="empty-icon">🍽️</div>
                            <p>Tidak ada food log yang ditemukan</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Foto</th>
                                        <th>User</th>
                                        <th>Makanan</th>
                                        <th>Kategori</th>
                                        <th>Kalori</th>
                                        <th>Nutrisi</th>
                                        <th>AI Info</th>
                                        <th>Waktu</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($logs as $i => $log): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <?php if ($log['photo']): ?>
                                                    <img src="../../../api/<?= htmlspecialchars($log['photo']) ?>" 
                                                         class="thumbnail" alt="Food" style="width: 50px; height: 50px; object-fit: cover; border-radius: 8px; cursor: pointer;"
                                                         onclick="window.open('../../../api/<?= htmlspecialchars($log['photo']) ?>', '_blank')">
                                                <?php else: ?>
                                                    <div style="width: 50px; height: 50px; background: var(--accent-light); display: flex; align-items: center; justify-content: center; border-radius: 8px;">
                                                        <i class="bi bi-image" style="color: var(--text-muted);"></i>
                                                    </div>
                                                <?php endif; ?>
                                            </td>
                                            <td><?= htmlspecialchars($log['user_name']) ?></td>
                                            <td><strong><?= htmlspecialchars($log['food_name']) ?></strong></td>
                                            <td>
                                                <?php
                                                $catColors = ['breakfast' => '#f59e0b', 'lunch' => '#10b981', 'dinner' => '#3b82f6', 'snack' => '#8b5cf6'];
                                                $catColor = $catColors[$log['category']] ?? '#6b7280';
                                                ?>
                                                <span style="background: <?= $catColor ?>15; color: <?= $catColor ?>; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: 600; text-transform: uppercase;">
                                                    <?= ucfirst($log['category']) ?>
                                                </span>
                                            </td>
                                            <td>
                                                <?php if ($log['calories'] !== null): ?>
                                                    <strong style="color: #2563eb;"><?= number_format($log['calories'], 0) ?></strong> <small>kcal</small>
                                                <?php else: ?>
                                                    <span class="text-muted">—</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <?php if ($log['carbs'] !== null): ?>
                                                    <small>K:<?= number_format($log['carbs'], 1) ?>g L:<?= number_format($log['fat'], 1) ?>g P:<?= number_format($log['protein'], 1) ?>g</small>
                                                <?php else: ?>
                                                    <span class="badge badge-warning" style="font-size: 10px;">Belum Dianalisis</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <?php if (!empty($log['ai_provider'])): ?>
                                                    <span class="badge badge-info" style="font-size: 10px; background-color: #6366f1; color: white; border: none; padding: 4px 8px; border-radius: 6px;">
                                                        <?= htmlspecialchars($log['ai_provider']) ?>
                                                    </span>
                                                    <?php if ($log['ai_response_time']): ?>
                                                        <br><small class="text-muted"><?= htmlspecialchars($log['ai_response_time']) ?>s</small>
                                                    <?php endif; ?>
                                                <?php else: ?>
                                                    <span class="text-muted">—</span>
                                                <?php endif; ?>
                                            </td>
                                            <td class="text-muted"><?= date('d M H:i', strtotime($log['meal_time'])) ?></td>
                                            <td>
                                                <div class="actions">
                                                    <a href="detail.php?id=<?= $log['id'] ?>" class="btn btn-sm btn-primary" title="Detail">
                                                        <i class="bi bi-eye"></i>
                                                    </a>
                                                </div>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

<?php
/**
 * Admin Dashboard
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Dashboard';
require_once 'includes/header.php';

$db = Database::getInstance()->getConnection();

// Fetch stats
$stats = [];

try {
    $stmt = $db->query("SELECT COUNT(*) as count FROM users");
    $stats['users'] = $stmt->fetch()['count'];

    $stmt = $db->query("SELECT COUNT(*) as count FROM food_logs");
    $stats['food_logs'] = $stmt->fetch()['count'];

    $stmt = $db->query("SELECT COUNT(*) as count FROM news WHERE is_published = 1");
    $stats['news'] = $stmt->fetch()['count'];

    $stmt = $db->query("SELECT COUNT(*) as count FROM recipes WHERE is_published = 1");
    $stats['recipes'] = $stmt->fetch()['count'];

    $stmt = $db->query("SELECT COUNT(*) as count FROM groups_tbl");
    $stats['groups'] = $stmt->fetch()['count'];

    // Recent users
    $stmt = $db->query("SELECT * FROM users ORDER BY created_at DESC LIMIT 5");
    $recentUsers = $stmt->fetchAll();

    // Recent food logs
    $stmt = $db->query(
        "SELECT fl.*, u.name as user_name 
         FROM food_logs fl 
         INNER JOIN users u ON fl.user_id = u.id 
         ORDER BY fl.created_at DESC LIMIT 5"
    );
    $recentLogs = $stmt->fetchAll();
} catch (PDOException $e) {
    die("<h1>Database Error</h1><p>Terjadi kesalahan pada database saat memuat dashboard. Pesan Error:</p><code>" . htmlspecialchars($e->getMessage()) . "</code><p>Pastikan semua tabel (users, food_logs, news, recipes, groups_tbl) sudah di-import dengan benar ke database server Anda.</p>");
} catch (Exception $e) {
    die("<h1>System Error</h1><p>" . htmlspecialchars($e->getMessage()) . "</p>");
}
?>

<div class="app-layout">
    <?php require_once 'includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <div>
                <button class="btn btn-sm" onclick="toggleSidebar()" style="display:none; margin-right: 12px;">
                    <i class="bi bi-list"></i>
                </button>
                <span class="page-title">Dashboard</span>
            </div>
            <div class="user-menu">
                <span class="text-muted">Halo,</span>
                <strong><?= htmlspecialchars($_SESSION['admin_name']) ?></strong>
                <div class="user-avatar">
                    <?= strtoupper(substr($_SESSION['admin_name'], 0, 1)) ?>
                </div>
            </div>
        </div>

        <div class="content-area">
            <!-- Stats Grid -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon users">
                        <i class="bi bi-people-fill"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><?= number_format($stats['users']) ?></div>
                        <div class="stat-label">Total Users</div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon logs">
                        <i class="bi bi-journal-check"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><?= number_format($stats['food_logs']) ?></div>
                        <div class="stat-label">Food Logs</div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon news">
                        <i class="bi bi-newspaper"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><?= number_format($stats['news']) ?></div>
                        <div class="stat-label">Berita Published</div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon recipes">
                        <i class="bi bi-book"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><?= number_format($stats['recipes']) ?></div>
                        <div class="stat-label">Resep Published</div>
                    </div>
                </div>
            </div>

            <!-- Recent Activity -->
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px;">
                <!-- Recent Users -->
                <div class="card">
                    <div class="card-header">
                        <h3><i class="bi bi-people" style="margin-right: 8px; color: var(--primary);"></i> User Terbaru</h3>
                        <a href="pages/users/index.php" class="btn btn-sm btn-secondary">Lihat Semua</a>
                    </div>
                    <div class="card-body" style="padding: 0;">
                        <?php if (empty($recentUsers)): ?>
                            <div class="empty-state" style="padding: 32px;">
                                <div class="empty-icon">👤</div>
                                <p>Belum ada user terdaftar</p>
                            </div>
                        <?php else: ?>
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>Nama</th>
                                        <th>Email</th>
                                        <th>Bergabung</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($recentUsers as $user): ?>
                                        <tr>
                                            <td><strong><?= htmlspecialchars($user['name']) ?></strong></td>
                                            <td class="text-muted"><?= htmlspecialchars($user['email']) ?></td>
                                            <td class="text-muted"><?= date('d M Y', strtotime($user['join_date'])) ?></td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        <?php endif; ?>
                    </div>
                </div>

                <!-- Recent Food Logs -->
                <div class="card">
                    <div class="card-header">
                        <h3><i class="bi bi-journal-check" style="margin-right: 8px; color: var(--primary);"></i> Log Terbaru</h3>
                    </div>
                    <div class="card-body" style="padding: 0;">
                        <?php if (empty($recentLogs)): ?>
                            <div class="empty-state" style="padding: 32px;">
                                <div class="empty-icon">🍽️</div>
                                <p>Belum ada food log</p>
                            </div>
                        <?php else: ?>
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>User</th>
                                        <th>Makanan</th>
                                        <th>Kategori</th>
                                        <th>Waktu</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($recentLogs as $log): ?>
                                        <tr>
                                            <td><?= htmlspecialchars($log['user_name']) ?></td>
                                            <td><strong><?= htmlspecialchars($log['food_name']) ?></strong></td>
                                            <td>
                                                <span class="badge badge-success">
                                                    <?= ucfirst($log['category']) ?>
                                                </span>
                                            </td>
                                            <td class="text-muted"><?= date('d M H:i', strtotime($log['meal_time'])) ?></td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        <?php endif; ?>
                    </div>
                </div>
            </div>

            <!-- Quick Info -->
            <div class="card mt-3">
                <div class="card-body">
                    <div style="display: flex; align-items: center; gap: 16px;">
                        <div style="font-size: 32px;">🌿</div>
                        <div>
                            <h3 style="margin-bottom: 4px;">Selamat datang di LovingHarmony Admin Panel</h3>
                            <p class="text-muted">
                                Kelola berita, resep, dan konten vegetarian untuk pengguna aplikasi LovingHarmony. 
                                Gunakan menu sidebar untuk navigasi ke berbagai fitur.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<?php require_once 'includes/footer.php'; ?>

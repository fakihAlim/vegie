<?php
/**
 * Badges Management - List
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola Lencana';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Determine base URL position
$scriptName = $_SERVER['SCRIPT_NAME'];
$adminPos = strpos($scriptName, '/admin/');
if ($adminPos !== false) {
    $baseUrl = substr($scriptName, 0, $adminPos + 7);
} else {
    $baseUrl = '/admin/';
}
$rootUrl = substr($baseUrl, 0, -6); // Get root of Vegie folder (e.g. /Vegie/)

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    
    // Fetch badge details first to delete custom uploaded files
    $stmt = $db->prepare("SELECT lottie_file FROM badges WHERE id = ?");
    $stmt->execute([$id]);
    $badge = $stmt->fetch();
    
    if ($badge) {
        $lottieFile = $badge['lottie_file'];
        if (strpos($lottieFile, 'uploads/lotties/') === 0) {
            $fullPath = __DIR__ . '/../../../api/' . $lottieFile;
            if (file_exists($fullPath)) {
                @unlink($fullPath);
            }
        }
        
        $stmt = $db->prepare("DELETE FROM badges WHERE id = ?");
        $stmt->execute([$id]);
        $_SESSION['flash_success'] = 'Lencana berhasil dihapus';
    } else {
        $_SESSION['flash_error'] = 'Lencana tidak ditemukan';
    }
    header('Location: index.php');
    exit;
}

// Fetch all badges
$stmt = $db->query("SELECT * FROM badges ORDER BY id ASC");
$badgesList = $stmt->fetchAll();
?>

<!-- Include Lottie Player CDN for premium visual previews -->
<script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js"></script>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🏆 Kelola Lencana</span>
            <div class="user-menu">
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Lencana
                </a>
            </div>
        </div>

        <div class="content-area">
            <!-- Flash Alert Messages -->
            <?php if (isset($_SESSION['flash_success'])): ?>
                <div class="alert alert-success" style="margin-bottom: 20px; padding: 12px 20px; border-radius: 8px; background: #e8f5e9; color: #2e7d32; border: 1px solid #c8e6c9;">
                    <i class="bi bi-check-circle-fill"></i>
                    <div><?= $_SESSION['flash_success']; unset($_SESSION['flash_success']); ?></div>
                </div>
            <?php endif; ?>
            <?php if (isset($_SESSION['flash_error'])): ?>
                <div class="alert alert-danger" style="margin-bottom: 20px; padding: 12px 20px; border-radius: 8px; background: #ffebee; color: #c62828; border: 1px solid #ffcdd2;">
                    <i class="bi bi-exclamation-triangle-fill"></i>
                    <div><?= $_SESSION['flash_error']; unset($_SESSION['flash_error']); ?></div>
                </div>
            <?php endif; ?>

            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($badgesList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">🏆</div>
                            <p>Belum ada lencana terdaftar. Klik "Tambah Lencana" untuk membuat yang pertama.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th style="width: 50px;" class="text-center">#</th>
                                        <th style="width: 100px;" class="text-center">Animasi</th>
                                        <th>Detail Lencana</th>
                                        <th>Kategori Pemicu</th>
                                        <th class="text-center">Target Threshold</th>
                                        <th>File Lottie</th>
                                        <th style="width: 120px;">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($badgesList as $i => $badge): 
                                        $lottieFile = $badge['lottie_file'];
                                        // Determine web URL of Lottie file for player
                                        if (strpos($lottieFile, 'uploads/') === 0) {
                                            $lottieUrl = $rootUrl . 'api/' . $lottieFile;
                                        } else {
                                            $lottieUrl = $rootUrl . 'vegie_app/' . $lottieFile;
                                        }
                                        
                                        // Map category code to human-readable terms & customized badge styles
                                        $category = $badge['category'] ?? 'plant_lover';
                                        $categoryLabel = '';
                                        $badgeClass = '';
                                        
                                        switch ($category) {
                                            case 'plant_lover':
                                                $categoryLabel = '🌿 Pecinta Nabati';
                                                $badgeClass = 'badge-success';
                                                break;
                                            case 'explorer':
                                                $categoryLabel = '📖 Sang Penjelajah';
                                                $badgeClass = 'badge-info';
                                                break;
                                            case 'streak':
                                                $categoryLabel = '🔥 Pejuang Konsisten';
                                                $badgeClass = 'badge-warning';
                                                break;
                                            case 'quiz_ace':
                                                $categoryLabel = '🎓 Juara Kuis';
                                                $badgeClass = 'badge-danger';
                                                break;
                                            default:
                                                $categoryLabel = $category;
                                                $badgeClass = 'badge-secondary';
                                        }
                                    ?>
                                        <tr>
                                            <td class="text-center"><?= $i + 1 ?></td>
                                            <td class="text-center">
                                                <div style="background: rgba(45, 106, 79, 0.04); border-radius: 50%; padding: 8px; width: 64px; height: 64px; display: inline-flex; align-items: center; justify-content: center; box-shadow: inset 0 2px 6px rgba(0,0,0,0.03); border: 1px solid rgba(45, 106, 79, 0.1);">
                                                    <lottie-player 
                                                        src="<?= htmlspecialchars($lottieUrl) ?>" 
                                                        background="transparent" 
                                                        speed="1" 
                                                        style="width: 52px; height: 52px;" 
                                                        loop 
                                                        autoplay>
                                                    </lottie-player>
                                                </div>
                                            </td>
                                            <td>
                                                <div style="font-weight: 600; font-size: 15px; color: var(--primary-dark);">
                                                    <?= htmlspecialchars($badge['name']) ?>
                                                </div>
                                                <div style="font-size: 11px; font-family: monospace; color: var(--text-muted); margin-bottom: 4px;">
                                                    Code Key: <span style="background: var(--border-light); padding: 1px 4px; border-radius: 4px;"><?= htmlspecialchars($badge['code']) ?></span>
                                                </div>
                                                <div class="text-muted" style="font-size: 13px; line-height: 1.4;">
                                                    <?= htmlspecialchars($badge['description'] ?? 'Tidak ada deskripsi.') ?>
                                                </div>
                                            </td>
                                            <td>
                                                <span class="badge <?= $badgeClass ?>" style="padding: 6px 12px; font-weight: 600; font-size: 12px; letter-spacing: 0.2px;">
                                                    <?= $categoryLabel ?>
                                                </span>
                                            </td>
                                            <td class="text-center" style="font-weight: bold; font-size: 15px; color: var(--primary);">
                                                <?= number_format($badge['target_value']) ?> 
                                                <span style="font-size: 12px; font-weight: normal; color: var(--text-secondary);">
                                                    <?php 
                                                    switch ($category) {
                                                        case 'plant_lover': echo 'log nabati'; break;
                                                        case 'explorer': echo 'artikel'; break;
                                                        case 'streak': echo 'hari'; break;
                                                        case 'quiz_ace': echo 'soal benar'; break;
                                                        default: echo 'target';
                                                    }
                                                    ?>
                                                </span>
                                            </td>
                                            <td>
                                                <div style="max-width: 180px; word-wrap: break-word; font-size: 12px; color: var(--text-secondary); font-family: monospace; line-height: 1.3;">
                                                    <?= htmlspecialchars($badge['lottie_file']) ?>
                                                </div>
                                            </td>
                                            <td>
                                                <div class="actions">
                                                    <a href="edit.php?id=<?= $badge['id'] ?>" class="btn btn-sm btn-secondary" title="Edit Lencana" style="padding: 8px 10px;">
                                                        <i class="bi bi-pencil-fill"></i>
                                                    </a>
                                                    <button onclick="confirmDelete('?delete=<?= $badge['id'] ?>', '<?= addslashes($badge['name']) ?>')" 
                                                            class="btn btn-sm btn-danger" title="Hapus Lencana" style="padding: 8px 10px;">
                                                        <i class="bi bi-trash-fill"></i>
                                                    </button>
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

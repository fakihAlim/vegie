<?php
/**
 * Recipes Management - List
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola Resep';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    $stmt = $db->prepare("SELECT photo FROM recipes WHERE id = ?");
    $stmt->execute([$id]);
    $recipe = $stmt->fetch();
    
    if ($recipe) {
        if ($recipe['photo']) {
            $filePath = __DIR__ . '/../../../api/' . $recipe['photo'];
            if (file_exists($filePath)) unlink($filePath);
        }
        $stmt = $db->prepare("DELETE FROM recipes WHERE id = ?");
        $stmt->execute([$id]);
        $_SESSION['flash_success'] = 'Resep berhasil dihapus';
    }
    header('Location: index.php');
    exit;
}

// Handle publish/unpublish toggle
if (isset($_GET['toggle'])) {
    $id = (int) $_GET['toggle'];
    $stmt = $db->prepare("SELECT is_published FROM recipes WHERE id = ?");
    $stmt->execute([$id]);
    $recipe = $stmt->fetch();
    
    if ($recipe) {
        $newStatus = $recipe['is_published'] ? 0 : 1;
        $publishedAt = $newStatus ? date('Y-m-d H:i:s') : null;
        $stmt = $db->prepare("UPDATE recipes SET is_published = ?, published_at = ? WHERE id = ?");
        $stmt->execute([$newStatus, $publishedAt, $id]);
        $_SESSION['flash_success'] = $newStatus ? 'Resep dipublish' : 'Resep di-unpublish';
    }
    header('Location: index.php');
    exit;
}

// Fetch all recipes
$stmt = $db->query("SELECT * FROM recipes ORDER BY created_at DESC");
$recipeList = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🥗 Kelola Resep</span>
            <div class="user-menu">
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Resep
                </a>
            </div>
        </div>

        <div class="content-area">
            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($recipeList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">🥗</div>
                            <p>Belum ada resep. Klik "Tambah Resep" untuk membuat yang pertama.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Foto</th>
                                        <th>Judul</th>
                                        <th>Kalori</th>
                                        <th>Waktu Masak</th>
                                        <th>Status</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($recipeList as $i => $recipe): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <?php if ($recipe['photo']): ?>
                                                    <img src="../../../api/<?= htmlspecialchars($recipe['photo']) ?>" 
                                                         class="thumbnail" alt="Recipe">
                                                <?php else: ?>
                                                    <div class="thumbnail" style="background: var(--accent-light); display: flex; align-items: center; justify-content: center;">
                                                        <i class="bi bi-image" style="color: var(--text-muted);"></i>
                                                    </div>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <strong><?= htmlspecialchars($recipe['title']) ?></strong>
                                                <?php if ($recipe['description']): ?>
                                                    <br><small class="text-muted"><?= mb_substr($recipe['description'], 0, 60) ?>...</small>
                                                <?php endif; ?>
                                            </td>
                                            <td><?= $recipe['calories'] ? $recipe['calories'] . ' kcal' : '-' ?></td>
                                            <td><?= $recipe['prep_time_minutes'] ? $recipe['prep_time_minutes'] . ' min' : '-' ?></td>
                                            <td>
                                                <?php if ($recipe['is_published']): ?>
                                                    <span class="badge badge-success">Published</span>
                                                <?php else: ?>
                                                    <span class="badge badge-warning">Draft</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div class="actions">
                                                    <a href="detail.php?id=<?= $recipe['id'] ?>" class="btn btn-sm btn-outline" title="Detail" style="border-color: var(--primary-light); color: var(--primary-light);">
                                                        <i class="bi bi-info-circle"></i>
                                                    </a>
                                                    <a href="edit.php?id=<?= $recipe['id'] ?>" class="btn btn-sm btn-secondary" title="Edit">
                                                        <i class="bi bi-pencil"></i>
                                                    </a>
                                                    <a href="?toggle=<?= $recipe['id'] ?>" class="btn btn-sm btn-outline" title="Toggle">
                                                        <i class="bi bi-<?= $recipe['is_published'] ? 'eye-slash' : 'eye' ?>"></i>
                                                    </a>
                                                    <button onclick="confirmDelete('?delete=<?= $recipe['id'] ?>', '<?= addslashes($recipe['title']) ?>')" 
                                                            class="btn btn-sm btn-danger" title="Hapus">
                                                        <i class="bi bi-trash"></i>
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

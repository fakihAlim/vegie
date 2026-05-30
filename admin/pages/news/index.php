<?php
/**
 * News Management - List
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola Berita';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    $stmt = $db->prepare("SELECT image FROM news WHERE id = ?");
    $stmt->execute([$id]);
    $news = $stmt->fetch();
    
    if ($news) {
        if ($news['image']) {
            $filePath = __DIR__ . '/../../../api/' . $news['image'];
            if (file_exists($filePath)) unlink($filePath);
        }
        $stmt = $db->prepare("DELETE FROM news WHERE id = ?");
        $stmt->execute([$id]);
        $_SESSION['flash_success'] = 'Berita berhasil dihapus';
    }
    header('Location: index.php');
    exit;
}

// Handle publish/unpublish toggle
if (isset($_GET['toggle'])) {
    $id = (int) $_GET['toggle'];
    $stmt = $db->prepare("SELECT is_published FROM news WHERE id = ?");
    $stmt->execute([$id]);
    $news = $stmt->fetch();
    
    if ($news) {
        $newStatus = $news['is_published'] ? 0 : 1;
        $publishedAt = $newStatus ? date('Y-m-d H:i:s') : null;
        $stmt = $db->prepare("UPDATE news SET is_published = ?, published_at = ? WHERE id = ?");
        $stmt->execute([$newStatus, $publishedAt, $id]);
        $_SESSION['flash_success'] = $newStatus ? 'Berita dipublish' : 'Berita di-unpublish';
    }
    header('Location: index.php');
    exit;
}

// Fetch all news
$stmt = $db->query("SELECT * FROM news ORDER BY created_at DESC");
$newsList = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">📰 Kelola Berita</span>
            <div class="user-menu">
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Berita
                </a>
            </div>
        </div>

        <div class="content-area">
            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($newsList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">📰</div>
                            <p>Belum ada berita. Klik "Tambah Berita" untuk membuat yang pertama.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Gambar</th>
                                        <th>Judul</th>
                                        <th>Status</th>
                                        <th>Tanggal</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($newsList as $i => $news): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <?php if ($news['image']): ?>
                                                    <img src="../../../api/<?= htmlspecialchars($news['image']) ?>" 
                                                         class="thumbnail" alt="News">
                                                <?php else: ?>
                                                    <div class="thumbnail" style="background: var(--accent-light); display: flex; align-items: center; justify-content: center;">
                                                        <i class="bi bi-image" style="color: var(--text-muted);"></i>
                                                    </div>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <strong><?= htmlspecialchars($news['title']) ?></strong>
                                                <br><small class="text-muted"><?= mb_substr(strip_tags($news['content']), 0, 80) ?>...</small>
                                            </td>
                                            <td>
                                                <?php if ($news['is_published']): ?>
                                                    <span class="badge badge-success">Published</span>
                                                <?php else: ?>
                                                    <span class="badge badge-warning">Draft</span>
                                                <?php endif; ?>
                                            </td>
                                            <td class="text-muted"><?= date('d M Y', strtotime($news['created_at'])) ?></td>
                                            <td>
                                                <div class="actions">
                                                    <a href="edit.php?id=<?= $news['id'] ?>" class="btn btn-sm btn-secondary" title="Edit">
                                                        <i class="bi bi-pencil"></i>
                                                    </a>
                                                    <a href="?toggle=<?= $news['id'] ?>" class="btn btn-sm btn-outline" title="Toggle">
                                                        <i class="bi bi-<?= $news['is_published'] ? 'eye-slash' : 'eye' ?>"></i>
                                                    </a>
                                                    <button onclick="confirmDelete('?delete=<?= $news['id'] ?>', '<?= addslashes($news['title']) ?>')" 
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

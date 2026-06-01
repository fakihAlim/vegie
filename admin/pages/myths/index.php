<?php
/**
 * Myths & Facts Management
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola Myth vs Fact';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    $stmt = $db->prepare("DELETE FROM myth_facts WHERE id = ?");
    $stmt->execute([$id]);
    $_SESSION['flash_success'] = 'Data berhasil dihapus';
    header('Location: index.php');
    exit;
}

// Fetch all
$stmt = $db->query("SELECT * FROM myth_facts ORDER BY created_at DESC");
$mythsList = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">💡 Kelola Myth vs Fact</span>
            <div class="user-menu" style="display: flex; gap: 12px; align-items: center;">
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Data
                </a>
            </div>
        </div>

        <div class="content-area">
            <?php if (isset($_SESSION['flash_success'])): ?>
                <div class="alert alert-success" style="margin-bottom: 20px; padding: 12px 20px; border-radius: 8px; background: #e8f5e9; color: #2e7d32; border: 1px solid #c8e6c9;">
                    <?= $_SESSION['flash_success']; unset($_SESSION['flash_success']); ?>
                </div>
            <?php endif; ?>

            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($mythsList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">💡</div>
                            <p>Belum ada data Myth vs Fact. Klik <strong>"Tambah Data"</strong>.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Gambar</th>
                                        <th>Judul & Deskripsi</th>
                                        <th class="text-center">Tipe</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($mythsList as $i => $item): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <?php if ($item['image_url']): ?>
                                                    <img src="<?= htmlspecialchars($item['image_url']) ?>" alt="img" style="width: 60px; height: 60px; object-fit: cover; border-radius: 8px;">
                                                <?php else: ?>
                                                    <div style="width: 60px; height: 60px; background: #f0f0f0; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: #aaa;">
                                                        <i class="bi bi-image"></i>
                                                    </div>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div style="font-weight: bold; max-width: 300px; word-wrap: break-word;">
                                                    <?= htmlspecialchars($item['title']) ?>
                                                </div>
                                                <div class="text-muted" style="font-size: 12px; margin-top: 4px; max-width: 300px;">
                                                    <?= htmlspecialchars($item['description']) ?>
                                                </div>
                                            </td>
                                            <td class="text-center">
                                                <?php if ($item['type'] === 'myth'): ?>
                                                    <span class="badge badge-warning" style="background: orange; color: white;">Mitos</span>
                                                <?php else: ?>
                                                    <span class="badge badge-success" style="background: green; color: white;">Fakta</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div class="actions">
                                                    <button onclick="confirmDelete('?delete=<?= $item['id'] ?>', '<?= addslashes($item['title']) ?>')" 
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

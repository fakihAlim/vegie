<?php
/**
 * Quests Management
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola Misi Harian';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    $stmt = $db->prepare("DELETE FROM quests WHERE id = ?");
    $stmt->execute([$id]);
    $_SESSION['flash_success'] = 'Misi berhasil dihapus';
    header('Location: index.php');
    exit;
}

// Fetch all
$stmt = $db->query("SELECT * FROM quests ORDER BY created_at DESC");
$questsList = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🎯 Kelola Misi Harian</span>
            <div class="user-menu" style="display: flex; gap: 12px; align-items: center;">
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Misi
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
                    <?php if (empty($questsList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">🎯</div>
                            <p>Belum ada Misi Harian. Klik <strong>"Tambah Misi"</strong>.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Misi</th>
                                        <th class="text-center">Tipe</th>
                                        <th class="text-center">Target</th>
                                        <th class="text-center">Poin</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($questsList as $i => $item): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <div style="font-weight: bold; max-width: 300px; word-wrap: break-word;">
                                                    <?= htmlspecialchars($item['title']) ?>
                                                </div>
                                                <div class="text-muted" style="font-size: 12px; margin-top: 4px; max-width: 300px;">
                                                    <?= htmlspecialchars($item['description']) ?>
                                                </div>
                                            </td>
                                            <td class="text-center">
                                                <span class="badge badge-outline" style="color: var(--primary); border: 1px solid var(--primary);"><?= htmlspecialchars($item['quest_type']) ?></span>
                                            </td>
                                            <td class="text-center">
                                                <strong><?= $item['target_count'] ?>x</strong>
                                            </td>
                                            <td class="text-center">
                                                <strong style="color: #ef6c00;">+<?= $item['points_reward'] ?> Pts</strong>
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

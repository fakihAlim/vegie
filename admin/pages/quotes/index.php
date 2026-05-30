<?php
/**
 * Quotes Management - List
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola Kata Mutiara';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    $stmt = $db->prepare("DELETE FROM daily_quotes WHERE id = ?");
    $stmt->execute([$id]);
    $_SESSION['flash_success'] = 'Quote berhasil dihapus';
    header('Location: index.php');
    exit;
}

// Handle toggle active/inactive
if (isset($_GET['toggle'])) {
    $id = (int) $_GET['toggle'];
    $stmt = $db->prepare("SELECT is_active FROM daily_quotes WHERE id = ?");
    $stmt->execute([$id]);
    $quote = $stmt->fetch();
    
    if ($quote) {
        $newStatus = $quote['is_active'] ? 0 : 1;
        $stmt = $db->prepare("UPDATE daily_quotes SET is_active = ? WHERE id = ?");
        $stmt->execute([$newStatus, $id]);
        $_SESSION['flash_success'] = $newStatus ? 'Quote diaktifkan' : 'Quote dinonaktifkan';
    }
    header('Location: index.php');
    exit;
}

// Fetch all quotes
$stmt = $db->query("SELECT * FROM daily_quotes ORDER BY created_at DESC");
$quotesList = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">💬 Kelola Kata Mutiara</span>
            <div class="user-menu">
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Quote
                </a>
            </div>
        </div>

        <div class="content-area">
            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($quotesList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">💬</div>
                            <p>Belum ada kata mutiara. Klik "Tambah Quote" untuk membuat yang pertama.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Kata Mutiara</th>
                                        <th>Penulis</th>
                                        <th>Tanggal Tampil</th>
                                        <th>Status</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($quotesList as $i => $quote): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <em>"<?= htmlspecialchars(mb_substr($quote['quote_text'], 0, 80)) ?><?= mb_strlen($quote['quote_text']) > 80 ? '...' : '' ?>"</em>
                                            </td>
                                            <td><?= htmlspecialchars($quote['author']) ?></td>
                                            <td class="text-muted">
                                                <?= $quote['display_date'] ? date('d M Y', strtotime($quote['display_date'])) : '<span style="color: var(--text-muted);">Auto-rotate</span>' ?>
                                            </td>
                                            <td>
                                                <?php if ($quote['is_active']): ?>
                                                    <span class="badge badge-success">Aktif</span>
                                                <?php else: ?>
                                                    <span class="badge badge-warning">Nonaktif</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div class="actions">
                                                    <a href="edit.php?id=<?= $quote['id'] ?>" class="btn btn-sm btn-secondary" title="Edit">
                                                        <i class="bi bi-pencil"></i>
                                                    </a>
                                                    <a href="?toggle=<?= $quote['id'] ?>" class="btn btn-sm btn-outline" title="Toggle">
                                                        <i class="bi bi-<?= $quote['is_active'] ? 'eye-slash' : 'eye' ?>"></i>
                                                    </a>
                                                    <button onclick="confirmDelete('?delete=<?= $quote['id'] ?>', '<?= addslashes(mb_substr($quote['quote_text'], 0, 40)) ?>')" 
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

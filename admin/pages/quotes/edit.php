<?php
/**
 * Quotes Management - Edit
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Edit Kata Mutiara';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();
$errors = [];

$id = (int) ($_GET['id'] ?? 0);
$stmt = $db->prepare("SELECT * FROM daily_quotes WHERE id = ?");
$stmt->execute([$id]);
$quote = $stmt->fetch();

if (!$quote) {
    $_SESSION['flash_error'] = 'Quote tidak ditemukan';
    header('Location: index.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $quoteText = trim($_POST['quote_text'] ?? '');
    $author = trim($_POST['author'] ?? 'Anonim');
    $displayDate = !empty($_POST['display_date']) ? $_POST['display_date'] : null;
    $isActive = isset($_POST['is_active']) ? 1 : 0;

    // Validate
    if (empty($quoteText)) {
        $errors[] = 'Kata mutiara wajib diisi';
    }

    if (empty($errors)) {
        $stmt = $db->prepare(
            "UPDATE daily_quotes SET quote_text = ?, author = ?, display_date = ?, is_active = ? WHERE id = ?"
        );
        $stmt->execute([$quoteText, $author ?: 'Anonim', $displayDate, $isActive, $id]);
        $_SESSION['flash_success'] = 'Quote berhasil diperbarui';
        header('Location: index.php');
        exit;
    }
    
    // If there are errors, override $quote with POST data for re-display
    $quote['quote_text'] = $quoteText;
    $quote['author'] = $author;
    $quote['display_date'] = $displayDate;
    $quote['is_active'] = $isActive;
}
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">💬 Edit Kata Mutiara</span>
            <div class="user-menu">
                <a href="index.php" class="btn btn-outline btn-sm">
                    <i class="bi bi-arrow-left"></i> Kembali
                </a>
            </div>
        </div>

        <div class="content-area">
            <?php if (!empty($errors)): ?>
                <div class="alert alert-danger">
                    <?php foreach ($errors as $error): ?>
                        <p style="margin: 0;"><?= $error ?></p>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>

            <div class="card">
                <div class="card-body">
                    <form method="POST" action="">
                        <div class="form-group">
                            <label for="quote_text">Kata Mutiara <span style="color: var(--error);">*</span></label>
                            <textarea name="quote_text" id="quote_text" rows="4" class="form-control" 
                                      placeholder="Masukkan kata mutiara..." required><?= htmlspecialchars($quote['quote_text']) ?></textarea>
                        </div>

                        <div class="form-group">
                            <label for="author">Penulis / Sumber</label>
                            <input type="text" name="author" id="author" class="form-control" 
                                   placeholder="Contoh: Hippocrates" 
                                   value="<?= htmlspecialchars($quote['author']) ?>">
                            <small class="text-muted">Kosongkan untuk default "Anonim"</small>
                        </div>

                        <div class="form-group">
                            <label for="display_date">Tanggal Tampil (Opsional)</label>
                            <input type="date" name="display_date" id="display_date" class="form-control"
                                   value="<?= htmlspecialchars($quote['display_date'] ?? '') ?>">
                            <small class="text-muted">Kosongkan agar quote ditampilkan secara rotasi otomatis</small>
                        </div>

                        <div class="form-group" style="display: flex; align-items: center; gap: 8px;">
                            <input type="checkbox" name="is_active" id="is_active" value="1" 
                                   <?= $quote['is_active'] ? 'checked' : '' ?>>
                            <label for="is_active" style="margin: 0;">Aktif</label>
                        </div>

                        <div class="form-actions" style="margin-top: 24px;">
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-check-circle"></i> Update
                            </button>
                            <a href="index.php" class="btn btn-outline">Batal</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

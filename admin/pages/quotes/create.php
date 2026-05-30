<?php
/**
 * Quotes Management - Create
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Tambah Kata Mutiara';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();
$errors = [];

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
            "INSERT INTO daily_quotes (quote_text, author, display_date, is_active) VALUES (?, ?, ?, ?)"
        );
        $stmt->execute([$quoteText, $author ?: 'Anonim', $displayDate, $isActive]);
        $_SESSION['flash_success'] = 'Quote berhasil ditambahkan';
        header('Location: index.php');
        exit;
    }
}
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">💬 Tambah Kata Mutiara</span>
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
                                      placeholder="Masukkan kata mutiara..." required><?= htmlspecialchars($_POST['quote_text'] ?? '') ?></textarea>
                        </div>

                        <div class="form-group">
                            <label for="author">Penulis / Sumber</label>
                            <input type="text" name="author" id="author" class="form-control" 
                                   placeholder="Contoh: Hippocrates" 
                                   value="<?= htmlspecialchars($_POST['author'] ?? '') ?>">
                            <small class="text-muted">Kosongkan untuk default "Anonim"</small>
                        </div>

                        <div class="form-group">
                            <label for="display_date">Tanggal Tampil (Opsional)</label>
                            <input type="date" name="display_date" id="display_date" class="form-control"
                                   value="<?= htmlspecialchars($_POST['display_date'] ?? '') ?>">
                            <small class="text-muted">Kosongkan agar quote ditampilkan secara rotasi otomatis</small>
                        </div>

                        <div class="form-group" style="display: flex; align-items: center; gap: 8px;">
                            <input type="checkbox" name="is_active" id="is_active" value="1" 
                                   <?= !isset($_POST['is_active']) || $_POST['is_active'] ? 'checked' : '' ?>>
                            <label for="is_active" style="margin: 0;">Aktif</label>
                        </div>

                        <div class="form-actions" style="margin-top: 24px;">
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-check-circle"></i> Simpan
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

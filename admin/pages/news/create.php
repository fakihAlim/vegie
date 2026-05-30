<?php
/**
 * News Management - Create
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Tambah Berita';
require_once __DIR__ . '/../../includes/header.php';
require_once __DIR__ . '/../../../api/helpers/upload.php';

$db = Database::getInstance()->getConnection();
$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title'] ?? '');
    $content = trim($_POST['content'] ?? '');
    $isPublished = isset($_POST['is_published']) ? 1 : 0;

    if (empty($title)) $errors[] = 'Judul wajib diisi';
    if (empty($content)) $errors[] = 'Konten wajib diisi';

    // Handle image upload
    $imagePath = null;
    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $imagePath = uploadImage($_FILES['image'], 'news');
        if (!$imagePath) $errors[] = 'Gagal upload gambar';
    }

    if (empty($errors)) {
        $publishedAt = $isPublished ? date('Y-m-d H:i:s') : null;
        $stmt = $db->prepare(
            "INSERT INTO news (title, content, image, is_published, published_at) VALUES (?, ?, ?, ?, ?)"
        );
        $stmt->execute([$title, $content, $imagePath, $isPublished, $publishedAt]);

        $_SESSION['flash_success'] = 'Berita berhasil ditambahkan';
        header('Location: index.php');
        exit;
    }
}
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">📰 Tambah Berita</span>
            <a href="index.php" class="btn btn-sm btn-secondary">
                <i class="bi bi-arrow-left"></i> Kembali
            </a>
        </div>

        <div class="content-area">
            <?php if (!empty($errors)): ?>
                <div class="alert alert-error">
                    <i class="bi bi-exclamation-circle"></i>
                    <div><?= implode('<br>', $errors) ?></div>
                </div>
            <?php endif; ?>

            <div class="card">
                <div class="card-body">
                    <form method="POST" enctype="multipart/form-data">
                        <div class="form-group">
                            <label for="title">Judul Berita *</label>
                            <input type="text" id="title" name="title" class="form-control" 
                                   value="<?= htmlspecialchars($_POST['title'] ?? '') ?>" 
                                   placeholder="Masukkan judul berita" required>
                        </div>

                        <div class="form-group">
                            <label for="content">Konten *</label>
                            <textarea id="content" name="content" class="form-control" rows="10"
                                      placeholder="Tulis konten berita di sini..."
                                      required><?= htmlspecialchars($_POST['content'] ?? '') ?></textarea>
                        </div>

                        <div class="form-group">
                            <label for="image">Gambar</label>
                            <div class="upload-area" onclick="document.getElementById('image').click()">
                                <div class="upload-icon"><i class="bi bi-cloud-arrow-up"></i></div>
                                <p>Klik untuk upload gambar<br><small>JPG, PNG, WebP — Max 5MB</small></p>
                            </div>
                            <input type="file" id="image" name="image" accept="image/*" 
                                   style="display:none" onchange="previewImage(this, 'imagePreview')">
                            <div id="imagePreview"></div>
                        </div>

                        <div class="form-group">
                            <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; text-transform: none; letter-spacing: normal; font-size: 14px;">
                                <input type="checkbox" name="is_published" value="1" 
                                    <?= isset($_POST['is_published']) ? 'checked' : '' ?>>
                                Publish langsung
                            </label>
                        </div>

                        <div class="d-flex gap-1">
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-check-circle"></i> Simpan Berita
                            </button>
                            <a href="index.php" class="btn btn-secondary">Batal</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

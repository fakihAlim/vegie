<?php
/**
 * News Management - Edit
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Edit Berita';
require_once __DIR__ . '/../../includes/header.php';
require_once __DIR__ . '/../../../api/helpers/upload.php';

$db = Database::getInstance()->getConnection();

$id = (int) ($_GET['id'] ?? 0);
$stmt = $db->prepare("SELECT * FROM news WHERE id = ?");
$stmt->execute([$id]);
$news = $stmt->fetch();

if (!$news) {
    $_SESSION['flash_error'] = 'Berita tidak ditemukan';
    header('Location: index.php');
    exit;
}

$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title'] ?? '');
    $content = trim($_POST['content'] ?? '');
    $isPublished = isset($_POST['is_published']) ? 1 : 0;

    if (empty($title)) $errors[] = 'Judul wajib diisi';
    if (empty($content)) $errors[] = 'Konten wajib diisi';

    // Handle image upload
    $imagePath = $news['image'];
    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $newPath = uploadImage($_FILES['image'], 'news');
        if ($newPath) {
            // Delete old image
            if ($news['image']) {
                $oldPath = __DIR__ . '/../../../api/' . $news['image'];
                if (file_exists($oldPath)) unlink($oldPath);
            }
            $imagePath = $newPath;
        }
    }

    if (empty($errors)) {
        $publishedAt = $isPublished ? ($news['published_at'] ?? date('Y-m-d H:i:s')) : null;
        $stmt = $db->prepare(
            "UPDATE news SET title = ?, content = ?, image = ?, is_published = ?, published_at = ? WHERE id = ?"
        );
        $stmt->execute([$title, $content, $imagePath, $isPublished, $publishedAt, $id]);

        $_SESSION['flash_success'] = 'Berita berhasil diperbarui';
        header('Location: index.php');
        exit;
    }
}
?>

<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/easymde/dist/easymde.min.css">
<style>
    /* Premium custom styling for EasyMDE in admin dashboard */
    .EasyMDEContainer {
        margin-top: 8px;
        background: #fff;
        border-radius: 8px;
    }
    .editor-toolbar {
        border-top-left-radius: 8px !important;
        border-top-right-radius: 8px !important;
        border-color: #e2e8f0 !important;
        background-color: #f8fafc;
    }
    .CodeMirror {
        border-bottom-left-radius: 8px !important;
        border-bottom-right-radius: 8px !important;
        border-color: #e2e8f0 !important;
        font-family: 'Inter', system-ui, -apple-system, sans-serif;
        font-size: 15px;
    }
</style>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">📰 Edit Berita</span>
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
                                   value="<?= htmlspecialchars($_POST['title'] ?? $news['title']) ?>" required>
                        </div>

                        <div class="form-group">
                            <label for="content">Konten *</label>
                            <textarea id="content" name="content" class="form-control" rows="10"><?= htmlspecialchars($_POST['content'] ?? $news['content']) ?></textarea>
                        </div>

                        <div class="form-group">
                            <label for="image">Gambar</label>
                            <?php if ($news['image']): ?>
                                <div class="mb-2">
                                    <p class="text-muted mb-1" style="font-size: 13px;">Gambar saat ini:</p>
                                    <img src="../../api/<?= htmlspecialchars($news['image']) ?>" 
                                         style="max-width: 200px; border-radius: 8px;">
                                </div>
                            <?php endif; ?>
                            <div class="upload-area" onclick="document.getElementById('image').click()">
                                <div class="upload-icon"><i class="bi bi-cloud-arrow-up"></i></div>
                                <p>Klik untuk upload gambar baru<br><small>JPG, PNG, WebP — Max 5MB</small></p>
                            </div>
                            <input type="file" id="image" name="image" accept="image/*"
                                   style="display:none" onchange="previewImage(this, 'imagePreview')">
                            <div id="imagePreview"></div>
                        </div>

                        <div class="form-group">
                            <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; text-transform: none; letter-spacing: normal; font-size: 14px;">
                                <input type="checkbox" name="is_published" value="1"
                                    <?= ($news['is_published']) ? 'checked' : '' ?>>
                                Published
                            </label>
                        </div>

                        <div class="d-flex gap-1">
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-check-circle"></i> Simpan Perubahan
                            </button>
                            <a href="index.php" class="btn btn-secondary">Batal</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/easymde/dist/easymde.min.js"></script>
<script>
    document.addEventListener("DOMContentLoaded", function() {
        const easyMDE = new EasyMDE({
            element: document.getElementById('content'),
            spellChecker: false,
            autosave: {
                enabled: true,
                uniqueId: "news_edit_editor_" + <?= $id ?>,
                delay: 2000,
            },
            placeholder: "Tulis konten berita di sini menggunakan format Markdown...",
            status: ["lines", "words", "cursor"],
            tabSize: 4,
            renderingConfig: {
                singleLineBreaks: false
            }
        });
    });
</script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

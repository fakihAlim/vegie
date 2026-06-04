<?php
/**
 * Edit Myth/Fact
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Edit Myth vs Fact';
require_once __DIR__ . '/../../includes/header.php';
require_once __DIR__ . '/../../../api/helpers/upload.php';

$db = Database::getInstance()->getConnection();

if (!isset($_GET['id'])) {
    $_SESSION['flash_error'] = 'ID data tidak ditemukan';
    header('Location: index.php');
    exit;
}

$id = (int) $_GET['id'];
$stmt = $db->prepare("SELECT * FROM myth_facts WHERE id = ?");
$stmt->execute([$id]);
$item = $stmt->fetch();

if (!$item) {
    $_SESSION['flash_error'] = 'Data tidak ditemukan';
    header('Location: index.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title']);
    $type = $_POST['type'];
    $description = trim($_POST['description']);

    // Handle image upload
    $imageUrl = $item['image_url'];
    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $newPath = uploadImage($_FILES['image'], 'myths');
        if ($newPath) {
            // Delete old image if it is a local upload
            if ($item['image_url'] && strpos($item['image_url'], 'http') !== 0) {
                $oldPath = __DIR__ . '/../../../api/' . $item['image_url'];
                if (file_exists($oldPath)) {
                    unlink($oldPath);
                }
            }
            $imageUrl = $newPath;
        } else {
            $error = "Gagal mengunggah gambar.";
        }
    }

    if (!isset($error)) {
        try {
            $stmt = $db->prepare("UPDATE myth_facts SET title = ?, type = ?, description = ?, image_url = ? WHERE id = ?");
            $stmt->execute([$title, $type, $description, $imageUrl, $id]);
            
            $_SESSION['flash_success'] = 'Data berhasil diperbarui!';
            header('Location: index.php');
            exit;
        } catch (Exception $e) {
            $error = "Gagal memperbarui: " . $e->getMessage();
        }
    }
}
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">Edit Myth vs Fact</span>
            <a href="index.php" class="btn btn-outline btn-sm">
                <i class="bi bi-arrow-left"></i> Kembali
            </a>
        </div>

        <div class="content-area">
            <?php if (isset($error)): ?>
                <div class="alert alert-danger" style="margin-bottom: 20px; padding: 12px; background: #ffebee; color: #c62828; border-radius: 8px;">
                    <?= $error ?>
                </div>
            <?php endif; ?>

            <div class="card">
                <div class="card-body">
                    <form method="POST" action="" enctype="multipart/form-data">
                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Judul</label>
                            <input type="text" name="title" value="<?= htmlspecialchars($item['title']) ?>" class="form-control" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                        </div>
                        
                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Tipe</label>
                            <select name="type" class="form-control" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                                <option value="myth" <?= $item['type'] === 'myth' ? 'selected' : '' ?>>Mitos</option>
                                <option value="fact" <?= $item['type'] === 'fact' ? 'selected' : '' ?>>Fakta</option>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Deskripsi</label>
                            <textarea name="description" class="form-control" rows="4" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;"><?= htmlspecialchars($item['description']) ?></textarea>
                        </div>

                        <div class="form-group" style="margin-bottom: 24px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Upload Gambar Baru (Opsional)</label>
                            <?php if ($item['image_url']): ?>
                                <div style="margin-bottom: 10px;">
                                    <span style="display: block; font-size: 12px; color: #666; margin-bottom: 4px;">Gambar Saat Ini:</span>
                                    <?php 
                                        $imgSrc = $item['image_url'];
                                        if (strpos($imgSrc, 'http') !== 0) {
                                            $imgSrc = '../../../api/' . $imgSrc;
                                        }
                                    ?>
                                    <img src="<?= htmlspecialchars($imgSrc) ?>" alt="current_img" style="max-width: 150px; border-radius: 8px; border: 1px solid #ddd;">
                                </div>
                            <?php endif; ?>
                            <input type="file" name="image" class="form-control" accept="image/*" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                            <small class="text-muted" style="display: block; margin-top: 4px;">Pilih file baru jika ingin mengganti gambar saat ini. File gambar berformat JPG, PNG, GIF, atau WEBP (Maksimal 5MB).</small>
                        </div>

                        <button type="submit" class="btn btn-primary">Perbarui Data</button>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

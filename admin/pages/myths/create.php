<?php
/**
 * Create Myth/Fact
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Tambah Myth vs Fact';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title']);
    $type = $_POST['type'];
    $description = trim($_POST['description']);
    $imageUrl = trim($_POST['image_url'] ?? '');

    try {
        $stmt = $db->prepare("INSERT INTO myth_facts (title, type, description, image_url) VALUES (?, ?, ?, ?)");
        $stmt->execute([$title, $type, $description, $imageUrl]);
        
        $_SESSION['flash_success'] = 'Data berhasil ditambahkan!';
        header('Location: index.php');
        exit;
    } catch (Exception $e) {
        $error = "Gagal menyimpan: " . $e->getMessage();
    }
}
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">Tambah Myth vs Fact</span>
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
                    <form method="POST" action="">
                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Judul</label>
                            <input type="text" name="title" class="form-control" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                        </div>
                        
                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Tipe</label>
                            <select name="type" class="form-control" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                                <option value="myth">Mitos</option>
                                <option value="fact">Fakta</option>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Deskripsi</label>
                            <textarea name="description" class="form-control" rows="4" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;"></textarea>
                        </div>

                        <div class="form-group" style="margin-bottom: 24px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">URL Gambar (Opsional)</label>
                            <input type="url" name="image_url" class="form-control" placeholder="https://..." style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                        </div>

                        <button type="submit" class="btn btn-primary">Simpan Data</button>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

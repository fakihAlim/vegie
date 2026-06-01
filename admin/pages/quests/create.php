<?php
/**
 * Create Quest
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Tambah Misi Harian';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title']);
    $description = trim($_POST['description']);
    $points = (int) $_POST['points_reward'];
    $type = trim($_POST['quest_type']);
    $target = (int) $_POST['target_count'];

    try {
        $stmt = $db->prepare("INSERT INTO quests (title, description, points_reward, quest_type, target_count) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$title, $description, $points, $type, $target]);
        
        $_SESSION['flash_success'] = 'Misi berhasil ditambahkan!';
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
            <span class="page-title">Tambah Misi Harian</span>
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
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Judul Misi</label>
                            <input type="text" name="title" class="form-control" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;" placeholder="Contoh: Log Makanan 3 Kali">
                        </div>
                        
                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Deskripsi</label>
                            <textarea name="description" class="form-control" rows="3" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;"></textarea>
                        </div>

                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Tipe Misi (Kode unik sistem)</label>
                            <input type="text" name="quest_type" class="form-control" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;" placeholder="Contoh: food_log_count">
                            <small style="color: #666; display: block; margin-top: 4px;">Gunakan <i>food_log_count</i>, <i>share_group</i>, <i>read_article</i>, atau lainnya sesuai controller.</small>
                        </div>

                        <div class="form-group" style="margin-bottom: 16px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Target (Berapa kali dilakukan)</label>
                            <input type="number" name="target_count" class="form-control" required value="1" min="1" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                        </div>

                        <div class="form-group" style="margin-bottom: 24px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: bold;">Hadiah Poin</label>
                            <input type="number" name="points_reward" class="form-control" required value="50" min="0" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                        </div>

                        <button type="submit" class="btn btn-primary">Simpan Misi</button>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

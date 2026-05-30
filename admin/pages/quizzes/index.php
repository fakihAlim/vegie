<?php
/**
 * Quizzes Management - List & AI Trigger
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola Kuis Nutrisi';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    $stmt = $db->prepare("DELETE FROM quizzes WHERE id = ?");
    $stmt->execute([$id]);
    $_SESSION['flash_success'] = 'Kuis berhasil dihapus';
    header('Location: index.php');
    exit;
}

// Handle toggle active/inactive
if (isset($_GET['toggle'])) {
    $id = (int) $_GET['toggle'];
    $stmt = $db->prepare("SELECT is_active FROM quizzes WHERE id = ?");
    $stmt->execute([$id]);
    $quiz = $stmt->fetch();
    
    if ($quiz) {
        $newStatus = $quiz['is_active'] ? 0 : 1;
        $stmt = $db->prepare("UPDATE quizzes SET is_active = ? WHERE id = ?");
        $stmt->execute([$newStatus, $id]);
        $_SESSION['flash_success'] = $newStatus ? 'Kuis diaktifkan' : 'Kuis dinonaktifkan';
    }
    header('Location: index.php');
    exit;
}

// Handle AI generation trigger
if (isset($_POST['generate_ai'])) {
    try {
        require_once __DIR__ . '/../../../api/helpers/ai_quiz_generator.php';
        require_once __DIR__ . '/../../../api/helpers/push_notification.php';
        
        $quizData = generatePlantBasedQuiz();
        if ($quizData) {
            $stmt = $db->prepare(
                "INSERT INTO quizzes (question, option_a, option_b, option_c, option_d, correct_answer, explanation, points, is_active)
                 VALUES (?, ?, ?, ?, ?, ?, ?, 50, 1)"
            );
            $stmt->execute([
                $quizData['question'],
                $quizData['option_a'],
                $quizData['option_b'],
                $quizData['option_c'],
                $quizData['option_d'],
                $quizData['correct_answer'],
                $quizData['explanation']
            ]);
            $quizId = $db->lastInsertId();
            
            // Send FCM Push Notification
            sendPushNotification('Kuis Baru!', 'Uji pengetahuanmu tentang nutrisi hari ini.', 'quiz', $quizId);
            
            $_SESSION['flash_success'] = 'Kuis baru berhasil dibuat oleh AI dan notifikasi push telah dikirim! 🤖🎉';
        } else {
            $_SESSION['flash_error'] = 'AI gagal menghasilkan pertanyaan kuis. Silakan periksa koneksi internet / API Key Anda.';
        }
    } catch (Exception $e) {
        $_SESSION['flash_error'] = 'Terjadi kesalahan: ' . $e->getMessage();
    }
    header('Location: index.php');
    exit;
}

// Fetch all quizzes
$stmt = $db->query("SELECT * FROM quizzes ORDER BY created_at DESC");
$quizzesList = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🧩 Kelola Kuis Nutrisi</span>
            <div class="user-menu" style="display: flex; gap: 12px; align-items: center;">
                <!-- AI Generator Form Trigger -->
                <form method="POST" action="" onsubmit="showAiLoading()" style="margin: 0;">
                    <button type="submit" name="generate_ai" class="btn btn-secondary btn-sm" id="btn-ai-gen">
                        <i class="bi bi-robot"></i> Buat Kuis via AI 🤖
                    </button>
                </form>
                
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Manual
                </a>
            </div>
        </div>

        <div class="content-area">
            <!-- Flash Message -->
            <?php if (isset($_SESSION['flash_success'])): ?>
                <div class="alert alert-success" style="margin-bottom: 20px; padding: 12px 20px; border-radius: 8px; background: #e8f5e9; color: #2e7d32; border: 1px solid #c8e6c9;">
                    <?= $_SESSION['flash_success']; unset($_SESSION['flash_success']); ?>
                </div>
            <?php endif; ?>
            <?php if (isset($_SESSION['flash_error'])): ?>
                <div class="alert alert-danger" style="margin-bottom: 20px; padding: 12px 20px; border-radius: 8px; background: #ffebee; color: #c62828; border: 1px solid #ffcdd2;">
                    <?= $_SESSION['flash_error']; unset($_SESSION['flash_error']); ?>
                </div>
            <?php endif; ?>

            <!-- Loading overlay for AI Gen -->
            <div id="ai-loading" class="card" style="display: none; margin-bottom: 20px; background: #e0f7fa; border: 1px solid #b2ebf2;">
                <div class="card-body text-center" style="padding: 24px; color: #00838f;">
                    <div class="spinner-border text-info" role="status" style="margin-bottom: 12px; width: 3rem; height: 3rem;">
                        <span class="visually-hidden">Memproses AI...</span>
                    </div>
                    <h4>Sedang Menghasilkan Pertanyaan Menggunakan AI...</h4>
                    <p class="text-muted" style="margin-bottom: 0;">Proses ini melibatkan pemanggilan AI Model dan pengiriman push notification ke seluruh perangkat pengguna. Mohon tunggu sekitar 5-15 detik.</p>
                </div>
            </div>

            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($quizzesList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">🧩</div>
                            <p>Belum ada kuis nutrisi. Klik <strong>"Buat Kuis via AI"</strong> untuk men-generate otomatis atau <strong>"Tambah Manual"</strong>.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Pertanyaan</th>
                                        <th>Pilihan A / B / C / D</th>
                                        <th class="text-center">Kunci</th>
                                        <th class="text-center">Poin</th>
                                        <th>Status</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($quizzesList as $i => $quiz): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <div style="font-weight: bold; max-width: 280px; word-wrap: break-word;">
                                                    <?= htmlspecialchars($quiz['question']) ?>
                                                </div>
                                                <div class="text-muted" style="font-size: 11px; margin-top: 4px; max-width: 280px; font-style: italic; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                                                    Penjelasan: <?= htmlspecialchars($quiz['explanation']) ?>
                                                </div>
                                            </td>
                                            <td>
                                                <div class="text-muted" style="font-size: 12px; line-height: 1.4;">
                                                    <strong>A:</strong> <?= htmlspecialchars(mb_substr($quiz['option_a'], 0, 30)) ?><?= mb_strlen($quiz['option_a']) > 30 ? '...' : '' ?><br>
                                                    <strong>B:</strong> <?= htmlspecialchars(mb_substr($quiz['option_b'], 0, 30)) ?><?= mb_strlen($quiz['option_b']) > 30 ? '...' : '' ?><br>
                                                    <strong>C:</strong> <?= htmlspecialchars(mb_substr($quiz['option_c'], 0, 30)) ?><?= mb_strlen($quiz['option_c']) > 30 ? '...' : '' ?><br>
                                                    <strong>D:</strong> <?= htmlspecialchars(mb_substr($quiz['option_d'], 0, 30)) ?><?= mb_strlen($quiz['option_d']) > 30 ? '...' : '' ?>
                                                </div>
                                            </td>
                                            <td class="text-center">
                                                <span class="badge badge-success" style="font-size: 12px; padding: 4px 10px; font-weight: bold; background: var(--primary);">
                                                    <?= strtoupper($quiz['correct_answer']) ?>
                                                </span>
                                            </td>
                                            <td class="text-center">
                                                <strong style="color: #ef6c00;"><?= $quiz['points'] ?> Pts</strong>
                                            </td>
                                            <td>
                                                <?php if ($quiz['is_active']): ?>
                                                    <span class="badge badge-success">Aktif</span>
                                                <?php else: ?>
                                                    <span class="badge badge-warning">Nonaktif</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div class="actions">
                                                    <a href="edit.php?id=<?= $quiz['id'] ?>" class="btn btn-sm btn-secondary" title="Edit">
                                                        <i class="bi bi-pencil"></i>
                                                    </a>
                                                    <a href="?toggle=<?= $quiz['id'] ?>" class="btn btn-sm btn-outline" title="Toggle Aktif/Nonaktif">
                                                        <i class="bi bi-<?= $quiz['is_active'] ? 'eye-slash' : 'eye' ?>"></i>
                                                    </a>
                                                    <button onclick="confirmDelete('?delete=<?= $quiz['id'] ?>', '<?= addslashes(mb_substr($quiz['question'], 0, 40)) ?>')" 
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

<script>
function showAiLoading() {
    document.getElementById('ai-loading').style.display = 'block';
    document.getElementById('btn-ai-gen').disabled = true;
    document.getElementById('btn-ai-gen').innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true" style="margin-right: 6px;"></span>Menghubungi AI...';
}
</script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

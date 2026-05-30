<?php
/**
 * Notifications Management
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Notifikasi';
require_once __DIR__ . '/../../includes/header.php';
require_once __DIR__ . '/../../../api/config/firebase.php';

$db = Database::getInstance()->getConnection();

// Handle send notification
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'send') {
    $title = trim($_POST['notif_title'] ?? '');
    $body = trim($_POST['notif_body'] ?? '');
    $type = $_POST['notif_type'] ?? 'system';

    if (!empty($title) && !empty($body)) {
        // Save to notifications table
        $stmt = $db->prepare("INSERT INTO notifications (title, body, type) VALUES (?, ?, ?)");
        $stmt->execute([$title, $body, $type]);

        // Get all FCM tokens
        $stmt = $db->query("SELECT DISTINCT token FROM user_fcm_tokens");
        $tokens = $stmt->fetchAll(PDO::FETCH_COLUMN);

        if (!empty($tokens)) {
            $result = sendFCMNotification($tokens, $title, $body, ['type' => $type]);
            if ($result['success']) {
                $_SESSION['flash_success'] = 'Notifikasi berhasil dikirim ke ' . count($tokens) . ' perangkat';
            } else {
                $_SESSION['flash_success'] = 'Notifikasi tersimpan. FCM: ' . ($result['message'] ?? 'Check server key');
            }
        } else {
            $_SESSION['flash_success'] = 'Notifikasi tersimpan (belum ada perangkat terdaftar)';
        }
    } else {
        $_SESSION['flash_error'] = 'Judul dan isi notifikasi wajib diisi';
    }
    header('Location: index.php');
    exit;
}

// Fetch notification history
$stmt = $db->query("SELECT * FROM notifications ORDER BY sent_at DESC LIMIT 50");
$notifications = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🔔 Notifikasi</span>
            <button class="btn btn-primary btn-sm" onclick="document.getElementById('sendModal').classList.add('active')">
                <i class="bi bi-send"></i> Kirim Notifikasi
            </button>
        </div>

        <div class="content-area">
            <div class="card">
                <div class="card-header">
                    <h3>Riwayat Notifikasi</h3>
                </div>
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($notifications)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">🔔</div>
                            <p>Belum ada notifikasi yang dikirim.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Judul</th>
                                        <th>Isi</th>
                                        <th>Tipe</th>
                                        <th>Waktu</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($notifications as $i => $notif): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td><strong><?= htmlspecialchars($notif['title']) ?></strong></td>
                                            <td class="text-muted"><?= mb_substr(htmlspecialchars($notif['body']), 0, 60) ?></td>
                                            <td>
                                                <?php
                                                $badgeClass = match($notif['type']) {
                                                    'news' => 'badge-info',
                                                    'recipe' => 'badge-success',
                                                    'group' => 'badge-warning',
                                                    default => 'badge-info'
                                                };
                                                ?>
                                                <span class="badge <?= $badgeClass ?>"><?= ucfirst($notif['type']) ?></span>
                                            </td>
                                            <td class="text-muted"><?= date('d M Y H:i', strtotime($notif['sent_at'])) ?></td>
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

<!-- Send Notification Modal -->
<div class="modal-overlay" id="sendModal">
    <div class="modal">
        <div class="modal-header">
            <h3>🔔 Kirim Notifikasi</h3>
            <button class="modal-close" onclick="document.getElementById('sendModal').classList.remove('active')">&times;</button>
        </div>
        <form method="POST">
            <input type="hidden" name="action" value="send">
            <div class="modal-body">
                <div class="form-group">
                    <label for="notif_title">Judul *</label>
                    <input type="text" id="notif_title" name="notif_title" class="form-control" 
                           placeholder="Judul notifikasi" required>
                </div>
                <div class="form-group">
                    <label for="notif_body">Isi Pesan *</label>
                    <textarea id="notif_body" name="notif_body" class="form-control" rows="3"
                              placeholder="Isi pesan notifikasi" required></textarea>
                </div>
                <div class="form-group">
                    <label for="notif_type">Tipe</label>
                    <select id="notif_type" name="notif_type" class="form-control">
                        <option value="system">System</option>
                        <option value="news">Berita</option>
                        <option value="recipe">Resep</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="document.getElementById('sendModal').classList.remove('active')">Batal</button>
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-send"></i> Kirim
                </button>
            </div>
        </form>
    </div>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

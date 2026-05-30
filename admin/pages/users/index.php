<?php
/**
 * Users Management - List
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola User';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Fetch all users with stats
$stmt = $db->query(
    "SELECT u.*, 
            (SELECT COUNT(*) FROM food_logs WHERE user_id = u.id) as total_logs,
            (SELECT COUNT(*) FROM group_members WHERE user_id = u.id) as total_groups
     FROM users u 
     ORDER BY u.created_at DESC"
);
$users = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">👥 Kelola User</span>
            <div class="user-menu">
                <span class="badge badge-info"><?= count($users) ?> users</span>
            </div>
        </div>

        <div class="content-area">
            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($users)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">👤</div>
                            <p>Belum ada user terdaftar.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Nama</th>
                                        <th>Email</th>
                                        <th>Food Logs</th>
                                        <th>Groups</th>
                                        <th>Tahap TTM</th>
                                        <th>Bergabung</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($users as $i => $user): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <div class="d-flex align-center gap-1">
                                                    <div class="user-avatar" style="width: 32px; height: 32px; font-size: 12px; background: var(--accent-light); color: var(--primary); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600;">
                                                        <?= strtoupper(substr($user['name'], 0, 1)) ?>
                                                    </div>
                                                    <div>
                                                        <strong><?= htmlspecialchars($user['name']) ?></strong>
                                                        <?php if ($user['bio']): ?>
                                                            <br><small class="text-muted"><?= mb_substr($user['bio'], 0, 40) ?></small>
                                                        <?php endif; ?>
                                                    </div>
                                                </div>
                                            </td>
                                            <td class="text-muted"><?= htmlspecialchars($user['email']) ?></td>
                                            <td><span class="badge badge-success"><?= $user['total_logs'] ?></span></td>
                                            <td><span class="badge badge-info"><?= $user['total_groups'] ?></span></td>
                                            <td>
                                                <?php if ($user['is_onboarding_completed']): ?>
                                                    <span class="badge badge-success" style="background-color: var(--primary);"><?= htmlspecialchars($user['current_stage']) ?></span>
                                                <?php else: ?>
                                                    <span class="badge" style="background-color: #f59e0b; color: white;">Belum Onboarding</span>
                                                <?php endif; ?>
                                            </td>
                                            <td class="text-muted"><?= date('d M Y', strtotime($user['join_date'])) ?></td>
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

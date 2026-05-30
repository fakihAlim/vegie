<?php
/**
 * User Activity Analytics
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Analitik Penggunaan';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// --- 1. FILTERS & PAGINATION ---
$filterUser = $_GET['user_id'] ?? '';
$filterAction = $_GET['action'] ?? '';
$filterPlatform = $_GET['platform'] ?? '';
$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = 25;
$offset = ($page - 1) * $perPage;

// --- 2. STATS QUERIES ---
// Today's total logs
$stmt = $db->query("SELECT COUNT(*) as count FROM user_activity_logs WHERE DATE(created_at) = CURRENT_DATE()");
$statsTodayLogs = $stmt->fetch()['count'];

// Today's active users
$stmt = $db->query("SELECT COUNT(DISTINCT user_id) as count FROM user_activity_logs WHERE DATE(created_at) = CURRENT_DATE()");
$statsTodayActiveUsers = $stmt->fetch()['count'];

// Weekly active users
$stmt = $db->query("SELECT COUNT(DISTINCT user_id) as count FROM user_activity_logs WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
$statsWeeklyActiveUsers = $stmt->fetch()['count'];

// Most popular action
$stmt = $db->query("SELECT action, COUNT(*) as count FROM user_activity_logs GROUP BY action ORDER BY count DESC LIMIT 1");
$popularActionRow = $stmt->fetch();
$statsPopularAction = $popularActionRow ? $popularActionRow['action'] : '-';
$statsPopularActionCount = $popularActionRow ? $popularActionRow['count'] : 0;

// --- 3. CHART DATA ---
// Daily logs for last 30 days
$stmt = $db->query("
    SELECT DATE(created_at) as date, COUNT(*) as count 
    FROM user_activity_logs 
    WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) 
    GROUP BY DATE(created_at) 
    ORDER BY DATE(created_at) ASC
");
$chartDailyData = $stmt->fetchAll();

// Top features/actions chart data
$stmt = $db->query("
    SELECT action, COUNT(*) as count 
    FROM user_activity_logs 
    GROUP BY action 
    ORDER BY count DESC 
    LIMIT 6
");
$chartActionData = $stmt->fetchAll();

// --- 4. LIST FOR FILTERS ---
$stmt = $db->query("SELECT id, name, email FROM users ORDER BY name ASC");
$allUsers = $stmt->fetchAll();

$stmt = $db->query("SELECT DISTINCT action FROM user_activity_logs ORDER BY action ASC");
$allActions = $stmt->fetchAll();

// --- 5. LOGS LIST (PAGINATED WITH FILTERS) ---
$whereClauses = [];
$params = [];

if ($filterUser) {
    $whereClauses[] = "l.user_id = ?";
    $params[] = $filterUser;
}
if ($filterAction) {
    $whereClauses[] = "l.action = ?";
    $params[] = $filterAction;
}
if ($filterPlatform) {
    $whereClauses[] = "l.platform = ?";
    $params[] = $filterPlatform;
}

$whereSql = "";
if (!empty($whereClauses)) {
    $whereSql = "WHERE " . implode(" AND ", $whereClauses);
}

// Get Total for Pagination
$countQuery = "SELECT COUNT(*) as total FROM user_activity_logs l $whereSql";
$stmt = $db->prepare($countQuery);
$stmt->execute($params);
$totalLogs = $stmt->fetch()['total'];
$totalPages = ceil($totalLogs / $perPage);

// Get Logs
$logsQuery = "
    SELECT l.*, u.name as user_name, u.email as user_email
    FROM user_activity_logs l
    INNER JOIN users u ON l.user_id = u.id
    $whereSql
    ORDER BY l.created_at DESC
    LIMIT ? OFFSET ?
";
$params[] = $perPage;
$params[] = $offset;

$stmt = $db->prepare($logsQuery);
// Force integer binding for LIMIT/OFFSET
$stmt->bindValue(count($params), $offset, PDO::PARAM_INT);
$stmt->bindValue(count($params) - 1, $perPage, PDO::PARAM_INT);
for ($i = 0; $i < count($params) - 2; $i++) {
    $stmt->bindValue($i + 1, $params[$i]);
}
$stmt->execute();
$logs = $stmt->fetchAll();
?>

<!-- Include Chart.js -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">📊 Analitik Penggunaan & Aktivitas</span>
            <div class="user-menu">
                <span class="badge badge-success" style="font-size: 13px; padding: 6px 12px;">Real-Time Logging</span>
            </div>
        </div>

        <div class="content-area" style="display: flex; flex-direction: column; gap: 24px;">
            
            <!-- Quick Stats Summary Cards -->
            <div class="stats-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px;">
                
                <div class="stat-card" style="border-left: 4px solid #10B981; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.02);">
                    <div class="stat-icon" style="background-color: rgba(16, 185, 129, 0.1); color: #10B981;">
                        <i class="bi bi-activity"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><?= number_format($statsTodayLogs) ?></div>
                        <div class="stat-label">Aktivitas Hari Ini</div>
                    </div>
                </div>

                <div class="stat-card" style="border-left: 4px solid #3B82F6; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.02);">
                    <div class="stat-icon" style="background-color: rgba(59, 130, 246, 0.1); color: #3B82F6;">
                        <i class="bi bi-people-fill"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><?= number_format($statsTodayActiveUsers) ?></div>
                        <div class="stat-label">User Aktif Hari Ini</div>
                    </div>
                </div>

                <div class="stat-card" style="border-left: 4px solid #8B5CF6; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.02);">
                    <div class="stat-icon" style="background-color: rgba(139, 92, 246, 0.1); color: #8B5CF6;">
                        <i class="bi bi-calendar-range-fill"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><?= number_format($statsWeeklyActiveUsers) ?></div>
                        <div class="stat-label">User Aktif Minggu Ini</div>
                    </div>
                </div>

                <div class="stat-card" style="border-left: 4px solid #F59E0B; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.02);">
                    <div class="stat-icon" style="background-color: rgba(245, 158, 11, 0.1); color: #F59E0B;">
                        <i class="bi bi-award-fill"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value" style="font-size: 18px; line-height: 28px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="<?= htmlspecialchars($statsPopularAction) ?>">
                            <?= htmlspecialchars($statsPopularAction) ?>
                        </div>
                        <div class="stat-label">Aksi Terpopuler (<?= number_format($statsPopularActionCount) ?>x)</div>
                    </div>
                </div>

            </div>

            <!-- Charts Section -->
            <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 24px; min-height: 350px;">
                
                <!-- Line Chart: Daily Activity -->
                <div class="card" style="border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.03);">
                    <div class="card-header" style="background: transparent; border-bottom: 1px solid #F3F4F6;">
                        <h3><i class="bi bi-graph-up" style="margin-right: 8px; color: var(--primary);"></i> Tren Aktivitas Pengguna (30 Hari Terakhir)</h3>
                    </div>
                    <div class="card-body" style="padding: 20px;">
                        <canvas id="dailyActivityChart" style="max-height: 300px; width: 100%;"></canvas>
                    </div>
                </div>

                <!-- Doughnut Chart: Top Features -->
                <div class="card" style="border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.03);">
                    <div class="card-header" style="background: transparent; border-bottom: 1px solid #F3F4F6;">
                        <h3><i class="bi bi-pie-chart-fill" style="margin-right: 8px; color: var(--primary);"></i> Fitur Terpopuler</h3>
                    </div>
                    <div class="card-body" style="padding: 20px; display: flex; align-items: center; justify-content: center;">
                        <canvas id="featurePopularityChart" style="max-height: 300px; max-width: 300px;"></canvas>
                    </div>
                </div>

            </div>

            <!-- Filters Section -->
            <div class="card" style="border-radius: 14px; box-shadow: 0 4px 10px rgba(0,0,0,0.02); margin-bottom: 0;">
                <div class="card-body" style="padding: 20px;">
                    <form method="GET" action="" style="display: flex; flex-wrap: wrap; gap: 16px; align-items: flex-end;">
                        
                        <div style="flex: 1; min-width: 200px;">
                            <label class="text-muted" style="font-size: 12px; font-weight: 600; display: block; margin-bottom: 6px;">Filter User</label>
                            <select name="user_id" class="form-control" style="width: 100%; height: 42px; border-radius: 8px; border: 1px solid #D1D5DB; padding: 8px 12px;">
                                <option value="">Semua User</option>
                                <?php foreach ($allUsers as $u): ?>
                                    <option value="<?= $u['id'] ?>" <?= (string)$filterUser === (string)$u['id'] ? 'selected' : '' ?>>
                                        <?= htmlspecialchars($u['name']) ?> (<?= htmlspecialchars($u['email']) ?>)
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div style="flex: 1; min-width: 150px;">
                            <label class="text-muted" style="font-size: 12px; font-weight: 600; display: block; margin-bottom: 6px;">Filter Aksi</label>
                            <select name="action" class="form-control" style="width: 100%; height: 42px; border-radius: 8px; border: 1px solid #D1D5DB; padding: 8px 12px;">
                                <option value="">Semua Aksi</option>
                                <?php foreach ($allActions as $act): ?>
                                    <option value="<?= htmlspecialchars($act['action']) ?>" <?= $filterAction === $act['action'] ? 'selected' : '' ?>>
                                        <?= htmlspecialchars($act['action']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div style="width: 150px;">
                            <label class="text-muted" style="font-size: 12px; font-weight: 600; display: block; margin-bottom: 6px;">Platform</label>
                            <select name="platform" class="form-control" style="width: 100%; height: 42px; border-radius: 8px; border: 1px solid #D1D5DB; padding: 8px 12px;">
                                <option value="">Semua</option>
                                <option value="android" <?= $filterPlatform === 'android' ? 'selected' : '' ?>>Android</option>
                                <option value="ios" <?= $filterPlatform === 'ios' ? 'selected' : '' ?>>iOS</option>
                                <option value="web" <?= $filterPlatform === 'web' ? 'selected' : '' ?>>Web</option>
                            </select>
                        </div>

                        <div style="display: flex; gap: 8px;">
                            <button type="submit" class="btn btn-primary" style="height: 42px; border-radius: 8px; font-weight: 600; padding: 0 20px;">
                                <i class="bi bi-filter" style="margin-right: 4px;"></i> Terapkan
                            </button>
                            <?php if ($filterUser || $filterAction || $filterPlatform): ?>
                                <a href="index.php" class="btn btn-secondary" style="height: 42px; border-radius: 8px; font-weight: 600; padding: 0 20px; display: inline-flex; align-items: center;">
                                    Reset
                                </a>
                            <?php endif; ?>
                        </div>

                    </form>
                </div>
            </div>

            <!-- Raw Logs Table Section -->
            <div class="card" style="border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.03); margin-top: 0;">
                <div class="card-header" style="background: transparent; border-bottom: 1px solid #F3F4F6;">
                    <h3><i class="bi bi-list-task" style="margin-right: 8px; color: var(--primary);"></i> Log Aktivitas Mentah</h3>
                </div>
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($logs)): ?>
                        <div class="empty-state" style="padding: 48px;">
                            <div class="empty-icon">📂</div>
                            <p>Tidak ada log aktivitas ditemukan untuk kriteria filter ini.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper" style="overflow-x: auto;">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>Waktu</th>
                                        <th>Pengguna</th>
                                        <th>Aksi</th>
                                        <th>Layar</th>
                                        <th>Durasi</th>
                                        <th>Device / OS</th>
                                        <th>Platform</th>
                                        <th>Engine AI</th>
                                        <th>JSON AI</th>
                                        <th>Detail Data</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($logs as $log): ?>
                                        <tr>
                                            <td style="white-space: nowrap; font-size: 13px;" class="text-muted">
                                                <?= date('d M Y, H:i:s', strtotime($log['created_at'])) ?>
                                            </td>
                                            <td>
                                                <strong><?= htmlspecialchars($log['user_name']) ?></strong>
                                                <br><small class="text-muted"><?= htmlspecialchars($log['user_email']) ?></small>
                                            </td>
                                            <td>
                                                <span class="badge badge-<?= $log['action'] === 'app_open' || $log['action'] === 'app_close' ? 'info' : ($log['action'] === 'food_log_add' ? 'success' : 'primary') ?>" style="font-size: 11px; font-weight: 600;">
                                                    <?= htmlspecialchars($log['action']) ?>
                                                </span>
                                            </td>
                                            <td class="text-muted" style="font-weight: 500;">
                                                <?= $log['screen'] ? htmlspecialchars($log['screen']) : '-' ?>
                                            </td>
                                            <td>
                                                <?php if ($log['duration'] !== null): ?>
                                                    <?php 
                                                    $min = floor($log['duration'] / 60);
                                                    $sec = $log['duration'] % 60;
                                                    ?>
                                                    <span style="font-weight: 600; color: #4B5563;">
                                                        <?= sprintf('%02d:%02d', $min, $sec) ?>
                                                    </span>
                                                <?php else: ?>
                                                    <span class="text-muted">-</span>
                                                <?php endif; ?>
                                            </td>
                                            <td style="font-size: 13px;">
                                                <?= $log['device_name'] ? htmlspecialchars($log['device_name']) : '-' ?>
                                                <br><small class="text-muted"><?= $log['os_version'] ? htmlspecialchars($log['os_version']) : '' ?></small>
                                            </td>
                                            <td style="text-align: center;">
                                                <?php if ($log['platform'] === 'android'): ?>
                                                    <span style="color: #3DDC84; font-size: 20px;" title="Android"><i class="bi bi-android2"></i></span>
                                                <?php elseif ($log['platform'] === 'ios'): ?>
                                                    <span style="color: #000000; font-size: 20px;" title="iOS"><i class="bi bi-apple"></i></span>
                                                <?php elseif ($log['platform'] === 'web'): ?>
                                                    <span style="color: #3B82F6; font-size: 20px;" title="Web"><i class="bi bi-globe"></i></span>
                                                <?php else: ?>
                                                    <span class="text-muted">-</span>
                                                <?php endif; ?>
                                                <br><small class="text-muted"><?= $log['app_version'] ? 'v' . htmlspecialchars($log['app_version']) : '' ?></small>
                                            </td>
                                            <td>
                                                <?php 
                                                $extra = json_decode($log['extra_data'] ?? '{}', true);
                                                $aiProvider = $extra['ai_provider'] ?? null;
                                                $aiTime = $extra['ai_response_time'] ?? null;
                                                
                                                if ($aiProvider): 
                                                    $badgeClass = strtolower($aiProvider) === 'ollama' ? 'success' : 'primary';
                                                    $timeStr = $aiTime !== null ? " <small class='text-muted' style='font-weight: 600;'>({$aiTime}s)</small>" : "";
                                                ?>
                                                    <span class="badge badge-<?= $badgeClass ?>" style="font-size: 11px; font-weight: 600;">
                                                        <?= htmlspecialchars($aiProvider) ?>
                                                    </span>
                                                    <?= $timeStr ?>
                                                <?php else: ?>
                                                    <span class="text-muted">-</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <?php 
                                                $aiRaw = $extra['ai_raw_response'] ?? null;
                                                if ($aiRaw):
                                                    $parsedAi = json_decode($aiRaw, true);
                                                    $compactJson = $parsedAi ? json_encode($parsedAi) : $aiRaw;
                                                ?>
                                                    <div onclick="showRawJson(<?= htmlspecialchars(json_encode($aiRaw)) ?>)" style="max-width: 200px; cursor: pointer; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-family: monospace; font-size: 11px; background: #EEF2F6; color: #1E3A8A; border: 1px solid #DBEAFE; padding: 4px 8px; border-radius: 6px; display: inline-flex; align-items: center; gap: 4px;" title="Klik untuk melihat JSON lengkap">
                                                        <i class="bi bi-code-slash"></i> <?= htmlspecialchars($compactJson) ?>
                                                    </div>
                                                <?php else: ?>
                                                    <span class="text-muted">-</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <?php if ($log['extra_data'] && $log['extra_data'] !== 'null'): ?>
                                                    <button class="btn btn-sm btn-secondary" onclick="showExtraData(<?= htmlspecialchars(json_encode($log['extra_data'])) ?>)" style="padding: 4px 8px; font-size: 11px;">
                                                        <i class="bi bi-eye"></i> Lihat JSON
                                                    </button>
                                                <?php else: ?>
                                                    <span class="text-muted">-</span>
                                                <?php endif; ?>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>

                        <!-- Pagination Footer -->
                        <?php if ($totalPages > 1): ?>
                            <div style="display: flex; justify-content: space-between; align-items: center; padding: 20px; border-top: 1px solid #F3F4F6;">
                                <span class="text-muted" style="font-size: 13px;">
                                    Menampilkan <?= count($logs) ?> dari <?= number_format($totalLogs) ?> baris
                                </span>
                                <div style="display: flex; gap: 8px;">
                                    <?php if ($page > 1): ?>
                                        <a href="?page=<?= $page - 1 ?>&user_id=<?= $filterUser ?>&action=<?= $filterAction ?>&platform=<?= $filterPlatform ?>" class="btn btn-sm btn-secondary">Sebelumnya</a>
                                    <?php endif; ?>
                                    
                                    <span style="align-self: center; font-weight: 600; padding: 0 12px;">Halaman <?= $page ?> dari <?= $totalPages ?></span>
                                    
                                    <?php if ($page < $totalPages): ?>
                                        <a href="?page=<?= $page + 1 ?>&user_id=<?= $filterUser ?>&action=<?= $filterAction ?>&platform=<?= $filterPlatform ?>" class="btn btn-sm btn-secondary">Selanjutnya</a>
                                    <?php endif; ?>
                                </div>
                            </div>
                        <?php endif; ?>
                    <?php endif; ?>
                </div>
            </div>

        </div>
    </main>
</div>

<!-- Modal Dialog helper for JSON Viewer -->
<script>
function showExtraData(jsonData) {
    try {
        let parsed = JSON.parse(jsonData);
        let pretty = JSON.stringify(parsed, null, 4);
        Swal.fire({
            title: 'Detail Parameter Tambahan',
            html: `<pre style="text-align: left; background: #F4F4F5; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: monospace; font-size: 13px; max-height: 350px;">${pretty}</pre>`,
            confirmButtonText: 'Tutup',
            confirmButtonColor: 'var(--primary)'
        });
    } catch(e) {
        Swal.fire('Data Tambahan', jsonData, 'info');
    }
}

function showRawJson(rawJsonStr) {
    try {
        let parsed = JSON.parse(rawJsonStr);
        let pretty = JSON.stringify(parsed, null, 4);
        Swal.fire({
            title: 'JSON Kembalian AI',
            html: `<pre style="text-align: left; background: #0F172A; color: #F8FAFC; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: monospace; font-size: 13px; max-height: 350px;">${pretty}</pre>`,
            confirmButtonText: 'Tutup',
            confirmButtonColor: 'var(--primary)'
        });
    } catch(e) {
        Swal.fire({
            title: 'JSON Kembalian AI',
            html: `<pre style="text-align: left; background: #0F172A; color: #F8FAFC; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: monospace; font-size: 13px; max-height: 350px;">${rawJsonStr}</pre>`,
            confirmButtonText: 'Tutup',
            confirmButtonColor: 'var(--primary)'
        });
    }
}

// Chart setup for daily trends
const dailyCtx = document.getElementById('dailyActivityChart').getContext('2d');
const dailyLabels = [];
const dailyValues = [];

<?php
// Fill labels and values for 30 days
$dailyMap = [];
foreach ($chartDailyData as $row) {
    $dailyMap[$row['date']] = $row['count'];
}

for ($i = 29; $i >= 0; $i--) {
    $dateStr = date('Y-m-d', strtotime("-$i days"));
    $labelStr = date('d M', strtotime("-$i days"));
    $count = $dailyMap[$dateStr] ?? 0;
    
    echo "dailyLabels.push('$labelStr');\n";
    echo "dailyValues.push($count);\n";
}
?>

new Chart(dailyCtx, {
    type: 'line',
    data: {
        labels: dailyLabels,
        datasets: [{
            label: 'Total Aktivitas',
            data: dailyValues,
            borderColor: '#10B981',
            backgroundColor: 'rgba(16, 185, 129, 0.08)',
            borderWidth: 3,
            fill: true,
            tension: 0.3,
            pointBackgroundColor: '#10B981',
            pointHoverRadius: 6
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: {
                display: false
            }
        },
        scales: {
            x: {
                grid: {
                    display: false
                }
            },
            y: {
                beginAtZero: true,
                grid: {
                    color: '#F3F4F6'
                }
            }
        }
    }
});

// Chart setup for features/actions
const featureCtx = document.getElementById('featurePopularityChart').getContext('2d');
const featureLabels = [];
const featureValues = [];

<?php
foreach ($chartActionData as $row) {
    echo "featureLabels.push('" . addslashes($row['action']) . "');\n";
    echo "featureValues.push(" . (int)$row['count'] . ");\n";
}
?>

new Chart(featureCtx, {
    type: 'doughnut',
    data: {
        labels: featureLabels,
        datasets: [{
            data: featureValues,
            backgroundColor: [
                '#10B981', // green
                '#3B82F6', // blue
                '#8B5CF6', // purple
                '#F59E0B', // amber
                '#EC4899', // pink
                '#6B7280'  // grey
            ],
            hoverOffset: 4
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: {
                position: 'bottom',
                labels: {
                    padding: 12,
                    font: {
                        size: 11
                    }
                }
            }
        }
    }
});
</script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

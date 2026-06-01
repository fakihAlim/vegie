<?php
/**
 * User Detail Dashboard
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Detail User';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Validate user ID
$userId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if (!$userId) {
    echo "<script>window.location.href = 'index.php';</script>";
    exit;
}

// Fetch user data
$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    echo "<script>window.location.href = 'index.php';</script>";
    exit;
}

// -----------------------------------------------------------------------
// Data Diri & Mifflin-St Jeor Nutritional Goals Calculator
// -----------------------------------------------------------------------
$age = $user['age'] ? (int)$user['age'] : null;
$weight = $user['weight'] ? (float)$user['weight'] : null;
$height = $user['height'] ? (float)$user['height'] : null;
$gender = $user['gender'] ? trim(strtolower($user['gender'])) : null;

$nutritionCalculated = false;
if ($age !== null && $weight !== null && $height !== null && $gender !== null) {
    if ($gender === 'male') {
        $bmr = (10 * $weight) + (6.25 * $height) - (5 * $age) + 5;
    } else {
        $bmr = (10 * $weight) + (6.25 * $height) - (5 * $age) - 161;
    }
    // Moderate/Lightly Active factor = 1.375
    $tdee = $bmr * 1.375;
    $carbs = ($tdee * 0.50) / 4.0;
    $protein = ($tdee * 0.20) / 4.0;
    $fat = ($tdee * 0.30) / 9.0;
    $nutritionCalculated = true;
} else {
    $bmr = null;
    $tdee = 2000.0;
    $carbs = 250.0;
    $protein = 100.0;
    $fat = 66.7;
}

// -----------------------------------------------------------------------
// TTM Stage Indonesian Mapper
// -----------------------------------------------------------------------
$ttmStagesMap = [
    'precontemplation' => ['Pra-kontemplasi', '#ef4444', 'Belum tertarik mengubah kebiasaan makan.'],
    'contemplation' => ['Kontemplasi', '#f59e0b', 'Mulai memikirkan untuk mengurangi daging/lemak.'],
    'preparation' => ['Persiapan', '#3b82f6', 'Siap melakukan perubahan dalam waktu dekat.'],
    'action' => ['Tindakan', '#10b981', 'Sedang aktif menerapkan pola makan nabati sehat.'],
    'maintenance' => ['Pemeliharaan', '#047857', 'Sudah konsisten mempertahankan pola makan nabati (> 6 bulan).']
];
$currentTtmStage = $user['ttm_stage'] ?? 'precontemplation';
$stageInfo = $ttmStagesMap[$currentTtmStage] ?? ['Belum Diketahui', '#9ca3af', 'Belum menyelesaikan questionnaire.'];

// -----------------------------------------------------------------------
// Points Aggregations
// -----------------------------------------------------------------------
// 1. Food Logs Points
$pointsLogStmt = $db->prepare("SELECT COALESCE(SUM(points), 0) FROM food_logs WHERE user_id = ?");
$pointsLogStmt->execute([$userId]);
$foodLogPoints = (int)$pointsLogStmt->fetchColumn();

// 2. Quiz Correct Points
$pointsQuizStmt = $db->prepare("
    SELECT COALESCE(SUM(q.points), 0) 
    FROM user_quizzes uq 
    JOIN quizzes q ON q.id = uq.quiz_id 
    WHERE uq.user_id = ? AND uq.is_correct = 1
");
$pointsQuizStmt->execute([$userId]);
$quizPoints = (int)$pointsQuizStmt->fetchColumn();

// 3. Quest Points Reward (Optional check if quest tables exist)
$questPoints = 0;
try {
    $pointsQuestStmt = $db->prepare("
        SELECT COALESCE(SUM(q.points_reward), 0)
        FROM user_quests uq
        JOIN quests q ON q.id = uq.quest_id
        WHERE uq.user_id = ? AND uq.status = 'completed'
    ");
    $pointsQuestStmt->execute([$userId]);
    $questPoints = (int)$pointsQuestStmt->fetchColumn();
} catch (Exception $e) {
    // Table might not exist or no quest rewards stored yet
}

$totalPoints = $foodLogPoints + $quizPoints + $questPoints;

// -----------------------------------------------------------------------
// Dynamic Streak (Strike) Calculation
// -----------------------------------------------------------------------
$streakStmt = $db->prepare("
    SELECT DATE(meal_time) AS log_date, MIN(points) AS min_points
    FROM food_logs
    WHERE user_id = ?
    GROUP BY log_date
    ORDER BY log_date DESC
");
$streakStmt->execute([$userId]);
$streakRows = $streakStmt->fetchAll(PDO::FETCH_ASSOC);

$currentStreak = 0;
if (!empty($streakRows)) {
    $dateMap = [];
    foreach ($streakRows as $row) {
        $dateMap[$row['log_date']] = (int)$row['min_points'];
    }

    $todayStr = date('Y-m-d');
    $yesterdayStr = date('Y-m-d', strtotime('-1 day'));

    if (isset($dateMap[$todayStr]) || isset($dateMap[$yesterdayStr])) {
        $currentDate = isset($dateMap[$todayStr]) ? new DateTime('today') : new DateTime('yesterday');
        
        while (true) {
            $dateStr = $currentDate->format('Y-m-d');
            if (isset($dateMap[$dateStr])) {
                if ($dateMap[$dateStr] < 50) {
                    break; // Animal-based log resets streak!
                }
                $currentStreak++;
                $currentDate->modify('-1 day');
            } else {
                break;
            }
        }
    }
}

// -----------------------------------------------------------------------
// Carbon Saved Equivalents
// -----------------------------------------------------------------------
$carbonSaved = (float)($user['total_carbon_saved'] ?? 0.0);
$gasolineLiters = $carbonSaved * 0.43;
$treesAbsorbed = $carbonSaved / 21.77;
$phoneCharges = $carbonSaved * 121.6;

// -----------------------------------------------------------------------
// Read News & Recipes
// -----------------------------------------------------------------------
// 1. Grouped News Views
$newsViewsStmt = $db->prepare("
    SELECT 
        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(extra_data, '$.news_id')), 0) AS news_id,
        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(extra_data, '$.title')), 'Judul Artikel') AS title,
        COUNT(*) as read_count,
        MAX(created_at) as last_read
    FROM user_activity_logs
    WHERE user_id = ? AND action = 'news_view'
    GROUP BY news_id, title
    ORDER BY read_count DESC
");
$newsViewsStmt->execute([$userId]);
$newsViews = $newsViewsStmt->fetchAll(PDO::FETCH_ASSOC);

// 2. Grouped Recipe Views
$recipeViewsStmt = $db->prepare("
    SELECT 
        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(extra_data, '$.recipe_id')), 0) AS recipe_id,
        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(extra_data, '$.title')), 'Judul Resep') AS title,
        COUNT(*) as read_count,
        MAX(created_at) as last_read
    FROM user_activity_logs
    WHERE user_id = ? AND action = 'recipe_view'
    GROUP BY recipe_id, title
    ORDER BY read_count DESC
");
$recipeViewsStmt->execute([$userId]);
$recipeViews = $recipeViewsStmt->fetchAll(PDO::FETCH_ASSOC);

// -----------------------------------------------------------------------
// Badges Earned (Lencana)
// -----------------------------------------------------------------------
$badgesStmt = $db->prepare("
    SELECT b.*, ub.awarded_at 
    FROM user_badges ub
    JOIN badges b ON b.id = ub.badge_id
    WHERE ub.user_id = ?
    ORDER BY ub.awarded_at DESC
");
$badgesStmt->execute([$userId]);
$badgesUnlocked = $badgesStmt->fetchAll(PDO::FETCH_ASSOC);

// -----------------------------------------------------------------------
// App Usage Duration & Detailed Timelines
// -----------------------------------------------------------------------
// Total active app usage time (summing duration in user_activity_logs)
$durationStmt = $db->prepare("
    SELECT SUM(duration) as total_duration
    FROM user_activity_logs
    WHERE user_id = ? AND duration IS NOT NULL
");
$durationStmt->execute([$userId]);
$totalSeconds = (int)$durationStmt->fetchColumn();

// Format total seconds into human readable format
$durationFormatted = '0 Detik';
if ($totalSeconds > 0) {
    $hours = floor($totalSeconds / 3600);
    $minutes = floor(($totalSeconds % 3600) / 60);
    $seconds = $totalSeconds % 60;
    
    $parts = [];
    if ($hours > 0) $parts[] = "$hours Jam";
    if ($minutes > 0) $parts[] = "$minutes Menit";
    if ($seconds > 0 || empty($parts)) $parts[] = "$seconds Detik";
    
    $durationFormatted = implode(', ', $parts);
}

// Fetch recent active timeline logs
$timelineStmt = $db->prepare("
    SELECT * 
    FROM user_activity_logs 
    WHERE user_id = ? 
    ORDER BY created_at DESC 
    LIMIT 30
");
$timelineStmt->execute([$userId]);
$timelineLogs = $timelineStmt->fetchAll(PDO::FETCH_ASSOC);

// Actions mapper for Indonesian humanized translation
$actionsMap = [
    'app_open' => ['Membuka Aplikasi', 'badge-info', 'bi-box-arrow-in-right'],
    'app_close' => ['Keluar Aplikasi', 'badge-danger', 'bi-box-arrow-left'],
    'screen_view' => ['Melihat Layar', 'badge-success', 'bi-phone'],
    'food_log_add' => ['Mencatat Makanan', 'badge-success', 'bi-plus-circle-fill'],
    'food_log_view' => ['Melihat Riwayat Makanan', 'badge-info', 'bi-eye-fill'],
    'food_log_delete' => ['Menghapus Log Makanan', 'badge-danger', 'bi-trash3-fill'],
    'food_log_edit' => ['Mengubah Log Makanan', 'badge-warning', 'bi-pencil-square'],
    'news_view' => ['Membaca Berita', 'badge-info', 'bi-newspaper'],
    'recipe_view' => ['Melihat Resep Makanan', 'badge-info', 'bi-book-half'],
    'group_view' => ['Melihat Komunitas/Grup', 'badge-success', 'bi-people-fill'],
    'group_join' => ['Bergabung Grup Baru', 'badge-success', 'bi-person-plus-fill'],
    'profile_update' => ['Memperbarui Profil Diri', 'badge-warning', 'bi-person-gear'],
    'sync_manual' => ['Sinkronisasi Manual Data', 'badge-info', 'bi-arrow-repeat'],
    'earn_points' => ['Mendapatkan Poin', 'badge-success', 'bi-award-fill'],
    'badge_awarded' => ['Mendapatkan Lencana Baru', 'badge-success', 'bi-trophy-fill']
];
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">👤 Detail User: <?= htmlspecialchars($user['name']) ?></span>
            <div class="user-menu">
                <a href="index.php" class="btn btn-secondary btn-sm" style="display: inline-flex; align-items: center; gap: 6px;">
                    <i class="bi bi-arrow-left"></i> Kembali ke Daftar
                </a>
            </div>
        </div>

        <div class="content-area" style="padding: 24px;">
            <!-- Main Grid Split -->
            <div class="d-flex gap-2" style="flex-wrap: wrap; align-items: flex-start;">
                
                <!-- LEFT COLUMN: Profile and TTM (Width: 320px) -->
                <div style="flex: 1; min-width: 320px; max-width: 360px; display: flex; flex-direction: column; gap: 24px;">
                    
                    <!-- Data Diri Card -->
                    <div class="card" style="border-radius: var(--radius-lg); overflow: hidden; box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%); color: white; border: none; padding: 24px 20px;">
                            <div class="text-center">
                                <div class="user-avatar" style="width: 72px; height: 72px; font-size: 28px; background: rgba(255,255,255,0.2); color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600; margin: 0 auto 12px; border: 3px solid rgba(255,255,255,0.4);">
                                    <?= strtoupper(substr($user['name'], 0, 1)) ?>
                                </div>
                                <h3 style="font-size: 18px; font-weight: 600; margin-bottom: 2px; font-family: 'Poppins', sans-serif;"><?= htmlspecialchars($user['name']) ?></h3>
                                <span class="text-muted" style="color: rgba(255,255,255,0.7) !important; font-size: 13px;"><?= htmlspecialchars($user['email']) ?></span>
                            </div>
                        </div>
                        <div class="card-body" style="padding: 20px;">
                            <ul style="list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 14px; font-size: 14px;">
                                <li style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border-light); padding-bottom: 8px;">
                                    <span class="text-muted"><i class="bi bi-calendar3" style="margin-right: 6px;"></i> Bergabung</span>
                                    <strong><?= date('d M Y', strtotime($user['join_date'])) ?></strong>
                                </li>
                                <li style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border-light); padding-bottom: 8px;">
                                    <span class="text-muted"><i class="bi bi-gender-ambiguous" style="margin-right: 6px;"></i> Jenis Kelamin</span>
                                    <strong><?= $gender === 'male' ? 'Pria' : ($gender === 'female' ? 'Wanita' : 'Belum Diisi') ?></strong>
                                </li>
                                <li style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border-light); padding-bottom: 8px;">
                                    <span class="text-muted"><i class="bi bi-calendar-check" style="margin-right: 6px;"></i> Usia</span>
                                    <strong><?= $age !== null ? $age . ' Tahun' : 'Belum Diisi' ?></strong>
                                </li>
                                <li style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border-light); padding-bottom: 8px;">
                                    <span class="text-muted"><i class="bi bi-arrows-expand" style="margin-right: 6px;"></i> Tinggi Badan</span>
                                    <strong><?= $height !== null ? $height . ' cm' : 'Belum Diisi' ?></strong>
                                </li>
                                <li style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border-light); padding-bottom: 8px;">
                                    <span class="text-muted"><i class="bi bi-speedometer" style="margin-right: 6px;"></i> Berat Badan</span>
                                    <strong><?= $weight !== null ? $weight . ' kg' : 'Belum Diisi' ?></strong>
                                </li>
                            </ul>
                            <?php if ($user['bio']): ?>
                                <div style="margin-top: 16px; padding: 12px; background: var(--border-light); border-radius: var(--radius-sm); font-size: 13px; color: var(--text-secondary); line-height: 1.5;">
                                    <strong>Bio:</strong><br><?= nl2br(htmlspecialchars($user['bio'])) ?>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>

                    <!-- Mifflin-St Jeor Nutritional Goal Card -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);"><i class="bi bi-calculator" style="margin-right: 6px; color: var(--primary);"></i> Kebutuhan Gizi Harian</h3>
                        </div>
                        <div class="card-body" style="padding: 20px;">
                            <?php if ($nutritionCalculated): ?>
                                <div style="text-align: center; margin-bottom: 20px; padding-bottom: 16px; border-bottom: 1px solid var(--border-light);">
                                    <span class="text-muted" style="font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">Kebutuhan Energi (TDEE)</span>
                                    <h2 style="font-size: 28px; color: var(--primary); font-weight: 700; font-family: 'Poppins', sans-serif; margin-top: 4px;"><?= number_format($tdee, 0, ',', '.') ?> <span style="font-size: 14px; font-weight: 500; color: var(--text-secondary);">kcal/hari</span></h2>
                                    <small class="text-muted" style="font-size: 11px;">BMR Mifflin-St Jeor: <?= number_format($bmr, 0, ',', '.') ?> kcal</small>
                                </div>
                                <div style="display: flex; flex-direction: column; gap: 14px;">
                                    <div>
                                        <div style="display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 4px;">
                                            <span>🌾 Karbohidrat (50%)</span>
                                            <strong><?= number_format($carbs, 1, ',', '.') ?> g</strong>
                                        </div>
                                        <div style="width: 100%; height: 8px; background: var(--border-light); border-radius: 4px; overflow: hidden;">
                                            <div style="width: 50%; height: 100%; background: #3b82f6; border-radius: 4px;"></div>
                                        </div>
                                    </div>
                                    <div>
                                        <div style="display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 4px;">
                                            <span>🥩 Protein (20%)</span>
                                            <strong><?= number_format($protein, 1, ',', '.') ?> g</strong>
                                        </div>
                                        <div style="width: 100%; height: 8px; background: var(--border-light); border-radius: 4px; overflow: hidden;">
                                            <div style="width: 20%; height: 100%; background: #f59e0b; border-radius: 4px;"></div>
                                        </div>
                                    </div>
                                    <div>
                                        <div style="display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 4px;">
                                            <span>🥑 Lemak (30%)</span>
                                            <strong><?= number_format($fat, 1, ',', '.') ?> g</strong>
                                        </div>
                                        <div style="width: 100%; height: 8px; background: var(--border-light); border-radius: 4px; overflow: hidden;">
                                            <div style="width: 30%; height: 100%; background: #ef4444; border-radius: 4px;"></div>
                                        </div>
                                    </div>
                                </div>
                            <?php else: ?>
                                <div class="text-center" style="padding: 10px 0; color: var(--text-secondary); font-size: 13px;">
                                    <i class="bi bi-exclamation-triangle" style="font-size: 28px; color: var(--warning); display: block; margin-bottom: 8px;"></i>
                                    Data diri (gender, usia, tinggi, berat) belum lengkap untuk menghitung Mifflin-St Jeor.
                                    <div style="margin-top: 12px; font-weight: 600; color: var(--primary);">Menggunakan standar dasar: 2.000 kcal</div>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>

                    <!-- Tahapan TTM Card -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);"><i class="bi bi-activity" style="margin-right: 6px; color: var(--primary);"></i> Tahapan TTM</h3>
                        </div>
                        <div class="card-body" style="padding: 20px;">
                            <div style="display: inline-flex; align-items: center; justify-content: center; width: 100%; padding: 8px 12px; border-radius: var(--radius-sm); background-color: <?= $stageInfo[1] ?>15; color: <?= $stageInfo[1] ?>; font-weight: 600; font-size: 14px; margin-bottom: 12px; border: 1px solid <?= $stageInfo[1] ?>30;">
                                <i class="bi bi-flag-fill" style="margin-right: 8px;"></i> <?= $stageInfo[0] ?>
                            </div>
                            <p style="font-size: 13px; color: var(--text-secondary); margin-bottom: 14px; line-height: 1.5;"><?= $stageInfo[2] ?></p>
                            <?php if ($user['ttm_action_start_date']): ?>
                                <div style="display: flex; justify-content: space-between; align-items: center; background: var(--accent-lighter); padding: 8px 12px; border-radius: var(--radius-sm); font-size: 12px; border: 1px solid var(--accent-light);">
                                    <span class="text-muted">Tanggal Mulai Aksi:</span>
                                    <strong style="color: var(--primary-dark);"><?= date('d M Y', strtotime($user['ttm_action_start_date'])) ?></strong>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>

                </div>

                <!-- RIGHT COLUMN: Main Metric Dashboard (Flex: 1) -->
                <div style="flex: 2; min-width: 500px; display: flex; flex-direction: column; gap: 24px;">
                    
                    <!-- KPI Metric Cards Row -->
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px;">
                        
                        <!-- Poin KPI -->
                        <div class="card" style="border-radius: var(--radius-lg); padding: 20px; border-left: 5px solid var(--primary); display: flex; align-items: center; gap: 16px; box-shadow: var(--shadow-sm);">
                            <div style="width: 48px; height: 48px; border-radius: 12px; background: var(--accent-light); color: var(--primary); display: flex; align-items: center; justify-content: center; font-size: 22px;">
                                <i class="bi bi-award-fill"></i>
                            </div>
                            <div>
                                <span class="text-muted" style="font-size: 12px; text-transform: uppercase;">Jumlah Poin</span>
                                <h3 style="font-size: 24px; color: var(--primary-dark); margin: 0; font-family: 'Poppins', sans-serif; font-weight: 700;"><?= number_format($totalPoints, 0, ',', '.') ?></h3>
                                <small class="text-muted" style="font-size: 11px;">Logs: <?= $foodLogPoints ?> | Quizzes: <?= $quizPoints ?></small>
                            </div>
                        </div>

                        <!-- Strike KPI -->
                        <div class="card" style="border-radius: var(--radius-lg); padding: 20px; border-left: 5px solid #f97316; display: flex; align-items: center; gap: 16px; box-shadow: var(--shadow-sm);">
                            <div style="width: 48px; height: 48px; border-radius: 12px; background: #ffedd5; color: #ea580c; display: flex; align-items: center; justify-content: center; font-size: 22px;">
                                <i class="bi bi-fire"></i>
                            </div>
                            <div>
                                <span class="text-muted" style="font-size: 12px; text-transform: uppercase;">Jumlah Strike (Streak)</span>
                                <h3 style="font-size: 24px; color: #ea580c; margin: 0; font-family: 'Poppins', sans-serif; font-weight: 700;"><?= $currentStreak ?> <span style="font-size: 14px; font-weight: 500;">Hari</span></h3>
                                <small class="text-muted" style="font-size: 11px;">Konsisten Makan Nabati</small>
                            </div>
                        </div>

                        <!-- Carbon Saved KPI -->
                        <div class="card" style="border-radius: var(--radius-lg); padding: 20px; border-left: 5px solid #10b981; display: flex; align-items: center; gap: 16px; box-shadow: var(--shadow-sm);">
                            <div style="width: 48px; height: 48px; border-radius: 12px; background: #d1fae5; color: #059669; display: flex; align-items: center; justify-content: center; font-size: 22px;">
                                <i class="bi bi-leaf"></i>
                            </div>
                            <div>
                                <span class="text-muted" style="font-size: 12px; text-transform: uppercase;">Jejak Karbon</span>
                                <h3 style="font-size: 24px; color: #059669; margin: 0; font-family: 'Poppins', sans-serif; font-weight: 700;"><?= number_format($carbonSaved, 2, ',', '.') ?> <span style="font-size: 14px; font-weight: 500;">kg CO₂e</span></h3>
                                <small class="text-muted" style="font-size: 11px;">Pengurangan Emisi Nabati</small>
                            </div>
                        </div>

                    </div>

                    <!-- Carbon Equivalents Card -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);"><i class="bi bi-globe-americas" style="margin-right: 6px; color: var(--primary);"></i> Setara Dengan Penyelamatan Lingkungan</h3>
                        </div>
                        <div class="card-body" style="padding: 20px;">
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px;">
                                <div style="background: var(--background); border: 1px solid var(--border-light); padding: 16px; border-radius: var(--radius); text-align: center;">
                                    <div style="font-size: 28px; color: #ef4444; margin-bottom: 6px;"><i class="bi bi-fuel-pump"></i></div>
                                    <h4 style="font-size: 18px; font-family: 'Poppins', sans-serif; font-weight: 600; margin-bottom: 4px;"><?= number_format($gasolineLiters, 2, ',', '.') ?> L</h4>
                                    <span class="text-muted" style="font-size: 12px;">Bensin Dihemat</span>
                                </div>
                                <div style="background: var(--background); border: 1px solid var(--border-light); padding: 16px; border-radius: var(--radius); text-align: center;">
                                    <div style="font-size: 28px; color: #10b981; margin-bottom: 6px;"><i class="bi bi-tree"></i></div>
                                    <h4 style="font-size: 18px; font-family: 'Poppins', sans-serif; font-weight: 600; margin-bottom: 4px;"><?= number_format($treesAbsorbed, 3, ',', '.') ?></h4>
                                    <span class="text-muted" style="font-size: 12px;">Kemampuan Serapan Pohon/Thn</span>
                                </div>
                                <div style="background: var(--background); border: 1px solid var(--border-light); padding: 16px; border-radius: var(--radius); text-align: center;">
                                    <div style="font-size: 28px; color: #3b82f6; margin-bottom: 6px;"><i class="bi bi-battery-charging"></i></div>
                                    <h4 style="font-size: 18px; font-family: 'Poppins', sans-serif; font-weight: 600; margin-bottom: 4px;"><?= number_format($phoneCharges, 0, ',', '.') ?></h4>
                                    <span class="text-muted" style="font-size: 12px;">Isi Daya Smartphone</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Badges (Lencana) Card -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);"><i class="bi bi-award-fill" style="margin-right: 6px; color: var(--primary);"></i> Lencana yang Telah Didapat (<?= count($badgesUnlocked) ?>)</h3>
                        </div>
                        <div class="card-body" style="padding: 20px;">
                            <?php if (empty($badgesUnlocked)): ?>
                                <div style="text-align: center; padding: 24px; color: var(--text-secondary); font-size: 13px;">
                                    <i class="bi bi-trophy" style="font-size: 32px; color: var(--text-muted); display: block; margin-bottom: 8px;"></i>
                                    Belum ada lencana yang didapatkan oleh user ini.
                                </div>
                            <?php else: ?>
                                <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px;">
                                    <?php foreach ($badgesUnlocked as $badge): ?>
                                        <div style="display: flex; align-items: center; gap: 14px; background: var(--accent-lighter); border: 1px solid var(--accent-light); padding: 12px 16px; border-radius: var(--radius); transition: var(--transition);">
                                            <div style="font-size: 28px; background: white; border-radius: 50%; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; box-shadow: var(--shadow-sm); flex-shrink: 0; border: 1px solid var(--border-light);">
                                                🏆
                                            </div>
                                            <div style="overflow: hidden;">
                                                <h4 style="font-size: 13px; font-weight: 600; color: var(--primary-dark); margin-bottom: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"><?= htmlspecialchars($badge['name']) ?></h4>
                                                <p style="font-size: 11px; color: var(--text-secondary); margin-bottom: 4px; line-height: 1.3; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;"><?= htmlspecialchars($badge['description']) ?></p>
                                                <span class="badge badge-success" style="font-size: 9px; padding: 2px 6px;"><i class="bi bi-check2-circle" style="margin-right: 4px;"></i> <?= date('d M Y H:i', strtotime($badge['awarded_at'])) ?></span>
                                            </div>
                                        </div>
                                    <?php endforeach; ?>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>

                    <!-- Split Read Lists (News vs Recipes) -->
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 24px;">
                        
                        <!-- Berita Dibaca -->
                        <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                            <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                                <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);"><i class="bi bi-newspaper" style="margin-right: 6px; color: var(--primary);"></i> Berita yang Dibaca</h3>
                            </div>
                            <div class="card-body" style="padding: 0;">
                                <?php if (empty($newsViews)): ?>
                                    <div style="text-align: center; padding: 40px 20px; color: var(--text-secondary); font-size: 13px;">
                                        Belum ada riwayat membaca berita.
                                    </div>
                                <?php else: ?>
                                    <div class="table-wrapper">
                                        <table class="data-table" style="font-size: 13px;">
                                            <thead>
                                                <tr>
                                                    <th>Judul Artikel</th>
                                                    <th style="width: 80px; text-align: center;">Frekuensi</th>
                                                    <th style="width: 120px;">Terakhir</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <?php foreach ($newsViews as $news): ?>
                                                    <tr>
                                                        <td>
                                                            <div style="font-weight: 600; color: var(--text-primary); line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">
                                                                <?= htmlspecialchars($news['title']) ?>
                                                            </div>
                                                        </td>
                                                        <td style="text-align: center;"><span class="badge badge-info" style="font-size: 11px; font-weight: 600; padding: 2px 8px;"><?= $news['read_count'] ?>x</span></td>
                                                        <td class="text-muted" style="font-size: 11px;"><?= date('d M Y H:i', strtotime($news['last_read'])) ?></td>
                                                    </tr>
                                                <?php endforeach; ?>
                                            </tbody>
                                        </table>
                                    </div>
                                <?php endif; ?>
                            </div>
                        </div>

                        <!-- Resep Dibaca -->
                        <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                            <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                                <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);"><i class="bi bi-book" style="margin-right: 6px; color: var(--primary);"></i> Resep yang Dibaca</h3>
                            </div>
                            <div class="card-body" style="padding: 0;">
                                <?php if (empty($recipeViews)): ?>
                                    <div style="text-align: center; padding: 40px 20px; color: var(--text-secondary); font-size: 13px;">
                                        Belum ada riwayat membaca resep.
                                    </div>
                                <?php else: ?>
                                    <div class="table-wrapper">
                                        <table class="data-table" style="font-size: 13px;">
                                            <thead>
                                                <tr>
                                                    <th>Judul Resep</th>
                                                    <th style="width: 80px; text-align: center;">Frekuensi</th>
                                                    <th style="width: 120px;">Terakhir</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <?php foreach ($recipeViews as $recipe): ?>
                                                    <tr>
                                                        <td>
                                                            <div style="font-weight: 600; color: var(--text-primary); line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">
                                                                <?= htmlspecialchars($recipe['title']) ?>
                                                            </div>
                                                        </td>
                                                        <td style="text-align: center;"><span class="badge badge-info" style="font-size: 11px; font-weight: 600; padding: 2px 8px;"><?= $recipe['read_count'] ?>x</span></td>
                                                        <td class="text-muted" style="font-size: 11px;"><?= date('d M Y H:i', strtotime($recipe['last_read'])) ?></td>
                                                    </tr>
                                                <?php endforeach; ?>
                                            </tbody>
                                        </table>
                                    </div>
                                <?php endif; ?>
                            </div>
                        </div>

                    </div>

                    <!-- Usage Logs & App Session History -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);"><i class="bi bi-clock-history" style="margin-right: 6px; color: var(--primary);"></i> Log Aktivitas & Waktu Penggunaan Aplikasi</h3>
                            <span class="badge badge-success" style="font-size: 12px; padding: 4px 12px;"><i class="bi bi-hourglass-split" style="margin-right: 4px;"></i> Total Waktu: <?= $durationFormatted ?></span>
                        </div>
                        <div class="card-body" style="padding: 0;">
                            <?php if (empty($timelineLogs)): ?>
                                <div style="text-align: center; padding: 40px 20px; color: var(--text-secondary); font-size: 13px;">
                                    Belum ada log aktivitas dari aplikasi mobile.
                                </div>
                            <?php else: ?>
                                <div class="table-wrapper">
                                    <table class="data-table" style="font-size: 13px;">
                                        <thead>
                                            <tr>
                                                <th style="width: 160px;">Waktu & Tanggal</th>
                                                <th>Aktivitas</th>
                                                <th>Layar Terkait</th>
                                                <th>Perangkat</th>
                                                <th style="text-align: center; width: 100px;">Durasi Sesi</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php foreach ($timelineLogs as $log): 
                                                $actionData = $actionsMap[$log['action']] ?? [$log['action'], 'badge-info', 'bi-activity'];
                                                $osIcon = 'bi-phone';
                                                if (strpos(strtolower($log['platform'] ?? ''), 'android') !== false) {
                                                    $osIcon = 'bi-android text-success';
                                                } elseif (strpos(strtolower($log['platform'] ?? ''), 'ios') !== false) {
                                                    $osIcon = 'bi-apple text-dark';
                                                }
                                            ?>
                                                <tr>
                                                    <td class="text-muted" style="font-size: 12px; font-weight: 500;"><?= date('d M Y, H:i:s', strtotime($log['created_at'])) ?></td>
                                                    <td>
                                                        <span class="badge <?= $actionData[1] ?>" style="font-size: 11px; display: inline-flex; align-items: center; gap: 6px;">
                                                            <i class="bi <?= $actionData[2] ?>"></i> <?= $actionData[0] ?>
                                                        </span>
                                                        <?php if ($log['action'] === 'earn_points' && $log['extra_data']):
                                                            $earned = json_decode($log['extra_data'], true);
                                                            if (isset($earned['points_earned'])): ?>
                                                                <strong style="color: var(--success); margin-left: 6px;">+<?= $earned['points_earned'] ?> Poin (<?= htmlspecialchars($earned['reason'] ?? '') ?>)</strong>
                                                            <?php endif;
                                                        elseif ($log['action'] === 'badge_awarded' && $log['extra_data']):
                                                            $badgeAwarded = json_decode($log['extra_data'], true);
                                                            if (isset($badgeAwarded['badge_name'])): ?>
                                                                <strong style="color: var(--primary); margin-left: 6px;">🏆 Lencana: <?= htmlspecialchars($badgeAwarded['badge_name']) ?></strong>
                                                            <?php endif;
                                                        endif; ?>
                                                    </td>
                                                    <td>
                                                        <?php if ($log['screen']): ?>
                                                            <span style="font-family: monospace; font-size: 12px; background: var(--border-light); padding: 2px 6px; border-radius: 4px; color: var(--text-secondary);"><?= htmlspecialchars($log['screen']) ?></span>
                                                        <?php else: ?>
                                                            <span class="text-muted" style="font-size: 11px;">-</span>
                                                        <?php endif; ?>
                                                    </td>
                                                    <td>
                                                        <div style="display: flex; align-items: center; gap: 6px; font-size: 12px;">
                                                            <i class="bi <?= $osIcon ?>" style="font-size: 14px;"></i>
                                                            <span style="font-weight: 500;"><?= htmlspecialchars($log['device_name'] ?? 'Generic Device') ?></span>
                                                            <small class="text-muted">(<?= htmlspecialchars($log['os_version'] ?? 'Unknown OS') ?>)</small>
                                                        </div>
                                                    </td>
                                                    <td style="text-align: center; font-weight: 600; color: var(--primary-dark);">
                                                        <?php if ($log['duration'] !== null): ?>
                                                            <?php 
                                                            $sec = (int)$log['duration'];
                                                            if ($sec < 60) {
                                                                echo $sec . ' dtk';
                                                            } else {
                                                                echo floor($sec / 60) . ' mnt ' . ($sec % 60) . ' dtk';
                                                            }
                                                            ?>
                                                        <?php else: ?>
                                                            <span class="text-muted" style="font-weight: normal; font-size: 11px;">-</span>
                                                        <?php endif; ?>
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

            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

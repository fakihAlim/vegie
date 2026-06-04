<?php
/**
 * Food Log Detail - Nutrition Card View
 * LovingHarmony Admin Panel
 * 
 * Displays food log with nutrition analysis card similar to cek.php design
 */
$pageTitle = 'Detail Food Log';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

$id = (int) ($_GET['id'] ?? 0);
if (!$id) {
    header('Location: index.php');
    exit;
}

// Handle re-analyze request
if (isset($_POST['reanalyze'])) {
    $selectedModel = $_POST['selected_model'] ?? null;
    if ($selectedModel === 'default') {
        $selectedModel = null;
    }
    
    $stmt = $db->prepare("SELECT photo FROM food_logs WHERE id = ?");
    $stmt->execute([$id]);
    $log = $stmt->fetch();
    
    if ($log && $log['photo']) {
        $fullPhotoPath = __DIR__ . '/../../../api/' . $log['photo'];
        if (file_exists($fullPhotoPath)) {
            require_once __DIR__ . '/../../../api/helpers/nutrition_analyzer.php';
            $errorMessage = '';
            $aiResult = analyzeNutrition($fullPhotoPath, $selectedModel, $errorMessage);
            
            if ($aiResult) {
                $stmt = $db->prepare(
                    "UPDATE food_logs SET food_name = ?, calories = ?, carbs = ?, fat = ?, protein = ?, ai_provider = ?, ai_response_time = ?, raw_response = ? WHERE id = ?"
                );
                $stmt->execute([
                    $aiResult['food_name'], $aiResult['calories'], $aiResult['carbs'], 
                    $aiResult['fat'], $aiResult['protein'],
                    $aiResult['ai_provider'] ?? null,
                    $aiResult['ai_response_time'] ?? null,
                    $aiResult['raw_response'] ?? null,
                    $id
                ]);
                $_SESSION['flash_success'] = 'Analisis nutrisi berhasil diperbarui menggunakan model: ' . ($aiResult['ai_provider'] ?? 'AI') . '!';
            } else {
                $_SESSION['flash_error'] = 'Gagal menganalisis foto dengan model terpilih. Detail Error: ' . $errorMessage;
            }
        } else {
            $_SESSION['flash_error'] = 'File foto tidak ditemukan di server.';
        }
    }
    header("Location: detail.php?id=$id");
    exit;
}

// Handle manual edit
if (isset($_POST['save_nutrition'])) {
    $foodName = $_POST['food_name'] ?? '';
    $calories = $_POST['calories'] !== '' ? (float) $_POST['calories'] : null;
    $carbs = $_POST['carbs'] !== '' ? (float) $_POST['carbs'] : null;
    $fat = $_POST['fat'] !== '' ? (float) $_POST['fat'] : null;
    $protein = $_POST['protein'] !== '' ? (float) $_POST['protein'] : null;
    $nutritionNotes = $_POST['nutrition_notes'] ?? '';

    $stmt = $db->prepare(
        "UPDATE food_logs SET food_name = ?, calories = ?, carbs = ?, fat = ?, protein = ?, nutrition_notes = ? WHERE id = ?"
    );
    $stmt->execute([$foodName, $calories, $carbs, $fat, $protein, $nutritionNotes, $id]);
    $_SESSION['flash_success'] = 'Data nutrisi berhasil disimpan!';
    header("Location: detail.php?id=$id");
    exit;
}

// Fetch food log
$stmt = $db->prepare(
    "SELECT fl.*, u.name as user_name, u.email as user_email
     FROM food_logs fl 
     INNER JOIN users u ON fl.user_id = u.id 
     WHERE fl.id = ?"
);
$stmt->execute([$id]);
$log = $stmt->fetch();

if (!$log) {
    $_SESSION['flash_error'] = 'Food log tidak ditemukan';
    header('Location: index.php');
    exit;
}

$hasNutrition = $log['calories'] !== null;
$catColors = ['breakfast' => '#f59e0b', 'lunch' => '#10b981', 'dinner' => '#3b82f6', 'snack' => '#8b5cf6'];
$catColor = $catColors[$log['category']] ?? '#6b7280';
?>

<style>
    .nutrition-card {
        background: linear-gradient(135deg, #eff6ff 0%, #f0f9ff 100%);
        border-radius: 16px;
        border: 1px solid #bfdbfe;
        padding: 24px;
        margin-bottom: 24px;
    }
    .nutrition-header {
        display: flex;
        gap: 20px;
        align-items: flex-start;
        margin-bottom: 20px;
    }
    .nutrition-photo {
        width: 120px;
        height: 120px;
        border-radius: 12px;
        object-fit: cover;
        border: 3px solid white;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        cursor: pointer;
        transition: transform 0.2s;
    }
    .nutrition-photo:hover {
        transform: scale(1.05);
    }
    .nutrition-info h2 {
        font-size: 22px;
        color: #1e3a5f;
        margin: 0 0 4px 0;
    }
    .nutrition-subtitle {
        font-size: 11px;
        color: #64748b;
        text-transform: uppercase;
        letter-spacing: 1px;
        font-weight: 600;
    }
    .calorie-box {
        background: linear-gradient(135deg, #dbeafe, #e0f2fe);
        border: 1px solid #93c5fd;
        border-radius: 12px;
        padding: 16px 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
    }
    .calorie-label {
        font-weight: 600;
        color: #1e40af;
        font-size: 14px;
    }
    .calorie-value {
        font-size: 22px;
        font-weight: 800;
        color: #1d4ed8;
    }
    .nutrient-row {
        margin-bottom: 14px;
    }
    .nutrient-label-row {
        display: flex;
        justify-content: space-between;
        margin-bottom: 4px;
    }
    .nutrient-name {
        font-weight: 600;
        font-size: 14px;
    }
    .nutrient-value {
        font-weight: 700;
        font-size: 14px;
    }
    .nutrient-bar {
        width: 100%;
        background: #e2e8f0;
        border-radius: 999px;
        height: 8px;
        overflow: hidden;
    }
    .nutrient-bar-fill {
        height: 100%;
        border-radius: 999px;
        transition: width 0.8s cubic-bezier(0.4, 0, 0.2, 1);
    }
    .bar-carbs { background: #f59e0b; }
    .bar-fat { background: #eab308; }
    .bar-protein { background: #ef4444; }
    .name-carbs { color: #92400e; }
    .name-fat { color: #854d0e; }
    .name-protein { color: #991b1b; }
    .val-carbs { color: #b45309; }
    .val-fat { color: #a16207; }
    .val-protein { color: #dc2626; }
    
    .edit-form {
        background: white;
        border-radius: 16px;
        border: 1px solid var(--border);
        padding: 24px;
    }
    .form-group {
        margin-bottom: 16px;
    }
    .form-group label {
        display: block;
        font-size: 13px;
        font-weight: 600;
        margin-bottom: 6px;
        color: var(--text-secondary);
    }
    .form-group input, .form-group textarea {
        width: 100%;
        padding: 10px 14px;
        border: 1px solid var(--border);
        border-radius: 10px;
        font-size: 14px;
        transition: border-color 0.2s;
    }
    .form-group input:focus, .form-group textarea:focus {
        border-color: var(--primary);
        outline: none;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }
    .nutrient-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 12px;
    }

    /* Fullscreen image overlay */
    .image-overlay {
        display: none;
        position: fixed;
        top: 0; left: 0;
        width: 100%; height: 100%;
        background: rgba(0,0,0,0.85);
        z-index: 9999;
        align-items: center;
        justify-content: center;
        cursor: pointer;
    }
    .image-overlay.active { display: flex; }
    .image-overlay img {
        max-width: 90%;
        max-height: 90%;
        border-radius: 12px;
        box-shadow: 0 20px 60px rgba(0,0,0,0.5);
    }
</style>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <div style="display: flex; align-items: center; gap: 12px;">
                <a href="index.php" class="btn btn-sm btn-secondary"><i class="bi bi-arrow-left"></i></a>
                <span class="page-title">Detail Food Log #<?= $id ?></span>
            </div>
            <div class="user-menu">
                <span class="text-muted">User: <strong><?= htmlspecialchars($log['user_name']) ?></strong></span>
            </div>
        </div>

        <div class="content-area">
            <?php if (isset($_SESSION['flash_success'])): ?>
                <div style="background: #dcfce7; border: 1px solid #86efac; color: #166534; padding: 12px 16px; border-radius: 10px; margin-bottom: 16px; font-size: 14px;">
                    ✅ <?= htmlspecialchars($_SESSION['flash_success']) ?>
                </div>
                <?php unset($_SESSION['flash_success']); ?>
            <?php endif; ?>

            <?php if (isset($_SESSION['flash_error'])): ?>
                <div style="background: #fef2f2; border: 1px solid #fca5a5; color: #991b1b; padding: 12px 16px; border-radius: 10px; margin-bottom: 16px; font-size: 14px;">
                    ⚠️ <?= htmlspecialchars($_SESSION['flash_error']) ?>
                </div>
                <?php unset($_SESSION['flash_error']); ?>
            <?php endif; ?>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px;">
                <!-- Left: Nutrition Card -->
                <div>
                    <div class="nutrition-card">
                        <div class="nutrition-header">
                            <?php if ($log['photo']): ?>
                                <img src="../../../api/<?= htmlspecialchars($log['photo']) ?>" 
                                     class="nutrition-photo" alt="Food"
                                     onclick="document.getElementById('imageOverlay').classList.add('active')">
                            <?php else: ?>
                                <div style="width: 120px; height: 120px; background: #e2e8f0; border-radius: 12px; display: flex; align-items: center; justify-content: center;">
                                    <i class="bi bi-image" style="font-size: 32px; color: #94a3b8;"></i>
                                </div>
                            <?php endif; ?>
                            
                            <div class="nutrition-info">
                                <h2><?= htmlspecialchars($log['food_name']) ?></h2>
                                <p class="nutrition-subtitle">
                                    Estimasi Kandungan Per Porsi
                                </p>
                                <div style="margin-top: 8px;">
                                    <span style="background: <?= $catColor ?>15; color: <?= $catColor ?>; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: 600; text-transform: uppercase;">
                                        <?= ucfirst($log['category']) ?>
                                    </span>
                                    <span class="text-muted" style="font-size: 12px; margin-left: 8px;">
                                        <?= date('d M Y, H:i', strtotime($log['meal_time'])) ?>
                                    </span>
                                    <?php if (!empty($log['ai_provider'])): ?>
                                        <div style="margin-top: 10px;">
                                            <span style="background: #4f46e5; color: white; padding: 3px 10px; border-radius: 12px; font-size: 10px; font-weight: 600;">
                                                <i class="bi bi-robot"></i> Diperiksa oleh <?= htmlspecialchars($log['ai_provider']) ?> 
                                                (<?= htmlspecialchars($log['ai_response_time']) ?>s)
                                            </span>
                                        </div>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>

                        <?php if ($hasNutrition): ?>
                            <div class="calorie-box">
                                <span class="calorie-label">Total Energi / Kalori</span>
                                <span class="calorie-value"><?= number_format($log['calories'], 0) ?> kcal</span>
                            </div>

                            <?php
                            $maxVal = max($log['carbs'], $log['fat'], $log['protein'], 1);
                            $nutrients = [
                                ['name' => 'Karbohidrat', 'val' => $log['carbs'], 'class' => 'carbs'],
                                ['name' => 'Lemak',       'val' => $log['fat'],   'class' => 'fat'],
                                ['name' => 'Protein',     'val' => $log['protein'], 'class' => 'protein'],
                            ];
                            foreach ($nutrients as $n):
                                $w = ($n['val'] / $maxVal) * 100;
                            ?>
                                <div class="nutrient-row">
                                    <div class="nutrient-label-row">
                                        <span class="nutrient-name name-<?= $n['class'] ?>"><?= $n['name'] ?></span>
                                        <span class="nutrient-value val-<?= $n['class'] ?>"><?= number_format($n['val'], 1) ?>g</span>
                                    </div>
                                    <div class="nutrient-bar">
                                        <div class="nutrient-bar-fill bar-<?= $n['class'] ?>" style="width: <?= number_format($w, 2) ?>%"></div>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        <?php else: ?>
                            <?php
                            $currentProvider = $log['ai_provider'] ?? '';
                            function isModelSelected($modelName, $currentProvider) {
                                return (strpos($currentProvider, $modelName) !== false) ? 'selected' : '';
                            }
                            ?>
                            <div style="text-align: center; padding: 24px; color: #94a3b8;">
                                <i class="bi bi-exclamation-circle" style="font-size: 32px; display: block; margin-bottom: 8px;"></i>
                                <p>Data nutrisi belum tersedia</p>
                                <form method="POST" style="margin-top: 16px; background: #fff; padding: 16px; border-radius: 12px; border: 1px dashed #bfdbfe; text-align: left;">
                                    <div class="form-group" style="margin-bottom: 12px;">
                                        <label style="font-size: 12px; font-weight: 600; color: #1e3a5f;">Pilih Model AI</label>
                                        <select name="selected_model" class="form-select" style="width: 100%; padding: 8px; border-radius: 8px; font-size: 13px;">
                                            <option value="default">Default Fallback (Ollama -> Gemini)</option>
                                            <optgroup label="Google Gemini API">
                                                <option value="gemini-3-flash-preview" <?= isModelSelected('gemini-3-flash-preview', $currentProvider) ?>>Gemini 3 Flash Live</option>
                                                <option value="gemini-3.1-flash-tts-preview" <?= isModelSelected('gemini-3.1-flash-tts-preview', $currentProvider) ?>>Gemini 3.1 Flash TTS</option>
                                                <option value="gemini-3.1-flash-lite" <?= isModelSelected('gemini-3.1-flash-lite', $currentProvider) ?>>Gemini 3.1 Flash Lite</option>
                                                <option value="gemini-3.5-flash" <?= isModelSelected('gemini-3.5-flash', $currentProvider) ?>>Gemini 3.5 Flash</option>
                                                <option value="gemma-4-31b-it" <?= isModelSelected('gemma-4-31b-it', $currentProvider) ?>>Gemma 4 31B</option>
                                            </optgroup>
                                            <optgroup label="Ollama (Local/Cloud)">
                                                <option value="minimax-m2.5:cloud" <?= isModelSelected('minimax-m2.5:cloud', $currentProvider) ?>>minimax-m2.5:cloud</option>
                                                <option value="jensonodigie/Jenteck-GPT:latest" <?= isModelSelected('jensonodigie/Jenteck-GPT:latest', $currentProvider) ?>>jensonodigie/Jenteck-GPT:latest</option>
                                                <option value="cogito-2.1:671b-cloud" <?= isModelSelected('cogito-2.1:671b-cloud', $currentProvider) ?>>cogito-2.1:671b-cloud</option>
                                                <option value="gemma4:31b-cloud" <?= isModelSelected('gemma4:31b-cloud', $currentProvider) ?>>gemma4:31b-cloud</option>
                                                <option value="minimax-m2:cloud" <?= isModelSelected('minimax-m2:cloud', $currentProvider) ?>>minimax-m2:cloud</option>
                                            </optgroup>
                                        </select>
                                    </div>
                                    <button type="submit" name="reanalyze" value="1" class="btn btn-primary btn-sm" style="width: 100%; display: inline-flex; align-items: center; justify-content: center; gap: 8px;">
                                        <i class="bi bi-robot"></i> Analisis dengan AI
                                    </button>
                                </form>
                            </div>
                        <?php endif; ?>
                    </div>

                    <?php if ($log['nutrition_notes']): ?>
                        <div class="card">
                            <div class="card-body">
                                <h4 style="margin-bottom: 8px;"><i class="bi bi-journal-text" style="color: var(--primary);"></i> Catatan</h4>
                                <p class="text-muted"><?= nl2br(htmlspecialchars($log['nutrition_notes'])) ?></p>
                            </div>
                        </div>
                    <?php endif; ?>

                    <?php if ($hasNutrition): ?>
                        <?php
                        if (!isset($currentProvider)) {
                            $currentProvider = $log['ai_provider'] ?? '';
                        }
                        if (!function_exists('isModelSelected')) {
                            function isModelSelected($modelName, $currentProvider) {
                                return (strpos($currentProvider, $modelName) !== false) ? 'selected' : '';
                            }
                        }
                        ?>
                        <div class="card" style="margin-top: 16px;">
                            <div class="card-body" style="padding: 16px;">
                                <h5 style="margin-bottom: 12px; color: #1e3a5f;"><i class="bi bi-cpu" style="color: var(--primary);"></i> Uji & Re-Analisis Model</h5>
                                <form method="POST">
                                    <div class="form-group" style="margin-bottom: 12px;">
                                        <label style="font-size: 12px; font-weight: 600; color: #64748b;">Pilih Model untuk Eksperimen</label>
                                        <select name="selected_model" class="form-select" style="width: 100%; padding: 8px; border-radius: 8px; font-size: 13px;">
                                            <option value="default">Default Fallback (Ollama -> Gemini)</option>
                                            <optgroup label="Google Gemini API">
                                                <option value="gemini-3-flash-preview" <?= isModelSelected('gemini-3-flash-preview', $currentProvider) ?>>Gemini 3 Flash Live</option>
                                                <option value="gemini-3.1-flash-tts-preview" <?= isModelSelected('gemini-3.1-flash-tts-preview', $currentProvider) ?>>Gemini 3.1 Flash TTS</option>
                                                <option value="gemini-3.1-flash-lite" <?= isModelSelected('gemini-3.1-flash-lite', $currentProvider) ?>>Gemini 3.1 Flash Lite</option>
                                                <option value="gemini-3.5-flash" <?= isModelSelected('gemini-3.5-flash', $currentProvider) ?>>Gemini 3.5 Flash</option>
                                                <option value="gemma-4-31b-it" <?= isModelSelected('gemma-4-31b-it', $currentProvider) ?>>Gemma 4 31B</option>
                                            </optgroup>
                                            <optgroup label="Ollama (Local/Cloud)">
                                                <option value="minimax-m2.5:cloud" <?= isModelSelected('minimax-m2.5:cloud', $currentProvider) ?>>minimax-m2.5:cloud</option>
                                                <option value="jensonodigie/Jenteck-GPT:latest" <?= isModelSelected('jensonodigie/Jenteck-GPT:latest', $currentProvider) ?>>jensonodigie/Jenteck-GPT:latest</option>
                                                <option value="cogito-2.1:671b-cloud" <?= isModelSelected('cogito-2.1:671b-cloud', $currentProvider) ?>>cogito-2.1:671b-cloud</option>
                                                <option value="gemma4:31b-cloud" <?= isModelSelected('gemma4:31b-cloud', $currentProvider) ?>>gemma4:31b-cloud</option>
                                                <option value="minimax-m2:cloud" <?= isModelSelected('minimax-m2:cloud', $currentProvider) ?>>minimax-m2:cloud</option>
                                            </optgroup>
                                        </select>
                                    </div>
                                    <button type="submit" name="reanalyze" value="1" class="btn btn-sm btn-secondary" style="width: 100%; display: inline-flex; align-items: center; justify-content: center; gap: 8px;">
                                        <i class="bi bi-arrow-repeat"></i> Jalankan Re-Analisis
                                    </button>
                                </form>
                            </div>
                        </div>
                    <?php endif; ?>
                </div>

                <!-- Right: Edit Form -->
                <div class="edit-form">
                    <h3 style="margin-bottom: 20px;"><i class="bi bi-pencil-square" style="color: var(--primary);"></i> Edit Data Nutrisi</h3>
                    
                    <form method="POST">
                        <div class="form-group">
                            <label>Nama Makanan</label>
                            <input type="text" name="food_name" value="<?= htmlspecialchars($log['food_name']) ?>" required>
                        </div>

                        <div class="form-group">
                            <label>Kalori (kcal)</label>
                            <input type="number" name="calories" step="0.1" value="<?= $log['calories'] ?>" placeholder="e.g. 380">
                        </div>

                        <div class="nutrient-grid">
                            <div class="form-group">
                                <label>Karbohidrat (g)</label>
                                <input type="number" name="carbs" step="0.1" value="<?= $log['carbs'] ?>" placeholder="e.g. 15.5">
                            </div>
                            <div class="form-group">
                                <label>Lemak (g)</label>
                                <input type="number" name="fat" step="0.1" value="<?= $log['fat'] ?>" placeholder="e.g. 22.0">
                            </div>
                            <div class="form-group">
                                <label>Protein (g)</label>
                                <input type="number" name="protein" step="0.1" value="<?= $log['protein'] ?>" placeholder="e.g. 30.0">
                            </div>
                        </div>

                        <div class="form-group">
                            <label>Catatan Nutrisi</label>
                            <textarea name="nutrition_notes" rows="3" placeholder="Catatan tambahan..."><?= htmlspecialchars($log['nutrition_notes'] ?? '') ?></textarea>
                        </div>

                        <button type="submit" name="save_nutrition" value="1" class="btn btn-primary" style="width: 100%;">
                            <i class="bi bi-check-circle"></i> Simpan Perubahan
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<!-- Fullscreen Image Overlay -->
<?php if ($log['photo']): ?>
<div id="imageOverlay" class="image-overlay" onclick="this.classList.remove('active')">
    <img src="../../../api/<?= htmlspecialchars($log['photo']) ?>" alt="Food">
</div>
<?php endif; ?>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

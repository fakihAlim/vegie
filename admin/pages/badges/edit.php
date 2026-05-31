<?php
/**
 * Badges Management - Edit
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Edit Lencana';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();
$errors = [];

// Determine base URL position
$scriptName = $_SERVER['SCRIPT_NAME'];
$adminPos = strpos($scriptName, '/admin/');
if ($adminPos !== false) {
    $baseUrl = substr($scriptName, 0, $adminPos + 7);
} else {
    $baseUrl = '/admin/';
}
$rootUrl = substr($baseUrl, 0, -6); // Get root of Vegie folder (e.g. /Vegie/)

// Validate ID
if (!isset($_GET['id'])) {
    $_SESSION['flash_error'] = 'ID Lencana tidak ditentukan';
    header('Location: index.php');
    exit;
}

$id = (int) $_GET['id'];
$stmt = $db->prepare("SELECT * FROM badges WHERE id = ?");
$stmt->execute([$id]);
$badge = $stmt->fetch();

if (!$badge) {
    $_SESSION['flash_error'] = 'Lencana tidak ditemukan';
    header('Location: index.php');
    exit;
}

// Scan presets dynamically
$presetFiles = [];
$presetPath = __DIR__ . '/../../../vegie_app/assets/lottie';
if (is_dir($presetPath)) {
    $files = glob($presetPath . '/*.json');
    foreach ($files as $file) {
        $filename = basename($file);
        $presetFiles[] = 'assets/lottie/' . $filename;
    }
}
natsort($presetFiles);
$presetFiles = array_values($presetFiles);

// Determine initial Lottie Source
$initialSource = 'preset';
if (strpos($badge['lottie_file'], 'uploads/') === 0) {
    $initialSource = 'upload';
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $code = trim($_POST['code'] ?? '');
    $name = trim($_POST['name'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $category = trim($_POST['category'] ?? '');
    $targetValue = (int) ($_POST['target_value'] ?? 1);
    $lottieSource = trim($_POST['lottie_source'] ?? 'preset');
    $presetFile = trim($_POST['lottie_preset'] ?? '');

    // Validation
    if (empty($code)) $errors[] = 'Code Key wajib diisi';
    if (empty($name)) $errors[] = 'Nama Lencana wajib diisi';
    if (empty($category)) $errors[] = 'Kategori wajib diisi';
    if ($targetValue <= 0) $errors[] = 'Target Threshold harus berupa angka positif';

    // Validate unique code
    if (!empty($code)) {
        if (!preg_match('/^[a-zA-Z0-9_]+$/', $code)) {
            $errors[] = 'Code Key hanya boleh berisi huruf, angka, dan underscore (contoh: streak_10)';
        } else {
            $stmt = $db->prepare("SELECT id FROM badges WHERE code = ? AND id != ?");
            $stmt->execute([$code, $id]);
            if ($stmt->fetch()) {
                $errors[] = "Code Key '$code' sudah digunakan oleh lencana lain";
            }
        }
    }

    // Determine path
    $lottiePath = $badge['lottie_file'];
    if ($lottieSource === 'upload') {
        if (isset($_FILES['lottie_file']) && $_FILES['lottie_file']['error'] === UPLOAD_ERR_OK) {
            $file = $_FILES['lottie_file'];
            $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
            if ($extension !== 'json') {
                $errors[] = 'Hanya file JSON Lottie (.json) yang diperbolehkan';
            } else {
                $content = file_get_contents($file['tmp_name']);
                if (json_decode($content) === null) {
                    $errors[] = 'File yang diupload mengandung format JSON yang tidak valid';
                } else {
                    $targetDir = __DIR__ . '/../../../api/uploads/lotties/';
                    if (!is_dir($targetDir)) {
                        mkdir($targetDir, 0777, true);
                    }
                    $filename = uniqid() . '_' . time() . '.json';
                    $targetPath = $targetDir . $filename;
                    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
                        // Delete previous upload to save space
                        if (strpos($badge['lottie_file'], 'uploads/lotties/') === 0) {
                            @unlink(__DIR__ . '/../../../api/' . $badge['lottie_file']);
                        }
                        $lottiePath = 'uploads/lotties/' . $filename;
                    } else {
                        $errors[] = 'Gagal menyimpan file Lottie ke server';
                    }
                }
            }
        }
    } else {
        if (empty($presetFile)) {
            $errors[] = 'Silakan pilih file preset Lottie';
        } else {
            // Delete previous custom upload if switching to preset
            if ($presetFile !== $badge['lottie_file'] && strpos($badge['lottie_file'], 'uploads/lotties/') === 0) {
                @unlink(__DIR__ . '/../../../api/' . $badge['lottie_file']);
            }
            $lottiePath = $presetFile;
        }
    }

    if (empty($errors)) {
        $stmt = $db->prepare("
            UPDATE badges 
            SET code = ?, category = ?, target_value = ?, name = ?, description = ?, lottie_file = ?
            WHERE id = ?
        ");
        $stmt->execute([$code, $category, $targetValue, $name, $description, $lottiePath, $id]);

        $_SESSION['flash_success'] = 'Lencana berhasil diubah!';
        header('Location: index.php');
        exit;
    }
}
?>

<!-- Include Lottie Player CDN for interactive visual previewing -->
<script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js"></script>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🏆 Edit Lencana: <?= htmlspecialchars($badge['name']) ?></span>
            <a href="index.php" class="btn btn-sm btn-secondary">
                <i class="bi bi-arrow-left"></i> Kembali
            </a>
        </div>

        <div class="content-area">
            <?php if (!empty($errors)): ?>
                <div class="alert alert-error" style="margin-bottom: 20px; padding: 12px 20px; border-radius: 8px; background: #ffebee; color: #c62828; border: 1px solid #ffcdd2;">
                    <i class="bi bi-exclamation-triangle-fill"></i>
                    <div><?= implode('<br>', $errors) ?></div>
                </div>
            <?php endif; ?>

            <div style="display: grid; grid-template-columns: 3fr 2fr; gap: 32px; align-items: start;">
                <!-- Form Area -->
                <div class="card">
                    <div class="card-header">
                        <h3>📋 Form Edit Lencana</h3>
                    </div>
                    <div class="card-body">
                        <form method="POST" enctype="multipart/form-data" id="badgeForm">
                            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                                <div class="form-group">
                                    <label for="code">Code Key (Unik) *</label>
                                    <input type="text" id="code" name="code" class="form-control" 
                                           value="<?= htmlspecialchars($_POST['code'] ?? $badge['code']) ?>" 
                                           placeholder="e.g. explorer_super" required>
                                    <small class="text-muted" style="font-size: 11px;">Hanya huruf, angka, dan underscore.</small>
                                </div>

                                <div class="form-group">
                                    <label for="name">Nama Lencana *</label>
                                    <input type="text" id="name" name="name" class="form-control" 
                                           value="<?= htmlspecialchars($_POST['name'] ?? $badge['name']) ?>" 
                                           placeholder="e.g. Penjelajah Senior" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="description">Deskripsi Lencana</label>
                                <textarea id="description" name="description" class="form-control" rows="3"
                                          placeholder="Tulis penjelasan bagaimana pengguna bisa membuka lencana ini..."><?= htmlspecialchars($_POST['description'] ?? $badge['description']) ?></textarea>
                            </div>

                            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                                <div class="form-group">
                                    <label for="category">Kategori Pemicu *</label>
                                    <select id="category" name="category" class="form-control" required onchange="updateTargetUnit()">
                                        <?php 
                                            $currCategory = $_POST['category'] ?? $badge['category'];
                                        ?>
                                        <option value="plant_lover" <?= $currCategory === 'plant_lover' ? 'selected' : '' ?>>🌿 Pecinta Nabati (Log Makanan)</option>
                                        <option value="explorer" <?= $currCategory === 'explorer' ? 'selected' : '' ?>>📖 Sang Penjelajah (Baca Artikel)</option>
                                        <option value="streak" <?= $currCategory === 'streak' ? 'selected' : '' ?>>🔥 Pejuang Konsisten (Streak Harian)</option>
                                        <option value="quiz_ace" <?= $currCategory === 'quiz_ace' ? 'selected' : '' ?>>🎓 Juara Kuis (Kuis Benar)</option>
                                    </select>
                                </div>

                                <div class="form-group">
                                    <label for="target_value">Target Threshold *</label>
                                    <div style="display: flex; align-items: center; gap: 8px;">
                                        <input type="number" id="target_value" name="target_value" class="form-control" 
                                               value="<?= htmlspecialchars($_POST['target_value'] ?? $badge['target_value']) ?>" 
                                               min="1" required style="flex: 1;">
                                        <span id="target_unit" style="font-weight: 600; color: var(--primary); font-size: 13px; min-width: 80px;">log nabati</span>
                                    </div>
                                </div>
                            </div>

                            <div style="border-top: 1px solid var(--border-light); margin: 24px 0; padding-top: 16px;">
                                <div class="form-group">
                                    <label style="text-transform: none; font-size: 14px; font-weight: 600;">PILIH METODE ANIMASI LOTTIE</label>
                                    <div style="display: flex; gap: 24px; margin-top: 8px; margin-bottom: 16px;">
                                        <?php 
                                            $currSource = $_POST['lottie_source'] ?? $initialSource;
                                        ?>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; text-transform: none; font-weight: normal; letter-spacing: normal;">
                                            <input type="radio" name="lottie_source" value="preset" <?= $currSource === 'preset' ? 'checked' : '' ?> onchange="toggleLottieSource('preset')">
                                            Gunakan File Preset Bunga (1-22)
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; text-transform: none; font-weight: normal; letter-spacing: normal;">
                                            <input type="radio" name="lottie_source" value="upload" <?= $currSource === 'upload' ? 'checked' : '' ?> onchange="toggleLottieSource('upload')">
                                            Upload File Lottie JSON Kustom
                                        </label>
                                    </div>
                                </div>

                                <!-- Preset Select Wrapper -->
                                <div class="form-group" id="preset_wrapper" style="<?= $currSource === 'preset' ? 'display: block;' : 'display: none;' ?>">
                                    <label for="lottie_preset">Pilih Animasi Preset *</label>
                                    <select id="lottie_preset" name="lottie_preset" class="form-control" onchange="previewPresetChange()">
                                        <?php 
                                            $currPreset = $_POST['lottie_preset'] ?? ($initialSource === 'preset' ? $badge['lottie_file'] : 'assets/lottie/flower.json');
                                        ?>
                                        <?php foreach ($presetFiles as $preset): ?>
                                            <option value="<?= htmlspecialchars($preset) ?>" <?= $currPreset === $preset ? 'selected' : '' ?>>
                                                <?= htmlspecialchars(basename($preset)) ?>
                                            </option>
                                        <?php endforeach; ?>
                                    </select>
                                </div>

                                <!-- Upload File Wrapper -->
                                <div class="form-group" id="upload_wrapper" style="<?= $currSource === 'upload' ? 'display: block;' : 'display: none;' ?>">
                                    <label for="lottie_file">Upload File JSON Lottie Baru (Opsional)</label>
                                    <div class="upload-area" onclick="document.getElementById('lottie_file').click()">
                                        <div class="upload-icon"><i class="bi bi-file-earmark-arrow-up-fill"></i></div>
                                        <p>Klik untuk memilih file JSON Lottie baru<br><small>Biarkan kosong jika tidak ingin mengubah file upload saat ini</small></p>
                                    </div>
                                    <input type="file" id="lottie_file" name="lottie_file" accept=".json" 
                                           style="display:none" onchange="previewUploadChange(this)">
                                    <?php if ($initialSource === 'upload'): ?>
                                        <div style="margin-top: 8px; font-size: 12px; color: var(--text-secondary);">
                                            File upload aktif saat ini: <code style="background: var(--border-light); padding: 2px 6px; border-radius: 4px;"><?= htmlspecialchars(basename($badge['lottie_file'])) ?></code>
                                        </div>
                                    <?php endif; ?>
                                </div>
                            </div>

                            <div class="d-flex gap-1" style="margin-top: 24px;">
                                <button type="submit" class="btn btn-primary" style="padding: 12px 28px;">
                                    <i class="bi bi-check-circle-fill"></i> Simpan Perubahan
                                </button>
                                <a href="index.php" class="btn btn-secondary" style="padding: 12px 28px;">Batal</a>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Preview Area -->
                <div class="card">
                    <div class="card-header">
                        <h3>👁️ Live Preview Animasi</h3>
                    </div>
                    <div class="card-body text-center" style="padding: 32px 16px;">
                        <div style="background: linear-gradient(135deg, rgba(45, 106, 79, 0.03) 0%, rgba(149, 213, 178, 0.1) 100%); border-radius: 24px; padding: 40px 24px; display: inline-flex; align-items: center; justify-content: center; box-shadow: inset 0 4px 12px rgba(45,106,79,0.05); border: 2px dashed rgba(45, 106, 79, 0.15); width: 100%; min-height: 260px; position: relative;">
                            <lottie-player 
                                id="lottiePreviewPlayer"
                                src="" 
                                background="transparent" 
                                speed="1" 
                                style="width: 180px; height: 180px;" 
                                loop 
                                autoplay>
                            </lottie-player>
                        </div>
                        <div style="margin-top: 20px;">
                            <h4 id="preview_name" style="color: var(--primary-dark); font-weight: 600;"><?= htmlspecialchars($badge['name']) ?></h4>
                            <p id="preview_desc" class="text-muted" style="font-size: 13px; margin-top: 6px; min-height: 40px; max-width: 280px; margin-left: auto; margin-right: auto;">
                                <?= htmlspecialchars($badge['description'] ?? 'Deskripsi lencana akan tampil di sini.') ?>
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<script>
const rootUrl = '<?= $rootUrl ?>';
const initialLottieFile = '<?= $badge['lottie_file'] ?>';
const initialSource = '<?= $initialSource ?>';

// Secure helper to fetch and load Lottie JSON directly into the player component
function loadLottieToPlayer(url, playerEl) {
    fetch(url)
        .then(response => {
            if (!response.ok) throw new Error('HTTP error ' + response.status);
            return response.json();
        })
        .then(data => {
            playerEl.load(data);
        })
        .catch(err => {
            console.error('Failed to load Lottie animation:', err);
            // Fallback to direct attribute load
            playerEl.setAttribute('src', url);
        });
}

// Live Name and Description update inside preview
const nameInput = document.getElementById('name');
const descInput = document.getElementById('description');
const previewName = document.getElementById('preview_name');
const previewDesc = document.getElementById('preview_desc');

nameInput.addEventListener('input', function() {
    previewName.textContent = this.value || 'Nama Lencana';
});

descInput.addEventListener('input', function() {
    previewDesc.textContent = this.value || 'Deskripsi lencana akan tampil di sini.';
});

// Update target metric unit label based on category selection
function updateTargetUnit() {
    const category = document.getElementById('category').value;
    const unitEl = document.getElementById('target_unit');
    
    switch(category) {
        case 'plant_lover':
            unitEl.textContent = 'log nabati';
            break;
        case 'explorer':
            unitEl.textContent = 'artikel';
            break;
        case 'streak':
            unitEl.textContent = 'hari';
            break;
        case 'quiz_ace':
            unitEl.textContent = 'soal benar';
            break;
    }
}

// Toggle Lottie Source (Preset selection vs custom JSON upload)
function toggleLottieSource(source) {
    const presetWrap = document.getElementById('preset_wrapper');
    const uploadWrap = document.getElementById('upload_wrapper');
    const player = document.getElementById('lottiePreviewPlayer');
    
    if (source === 'preset') {
        presetWrap.style.display = 'block';
        uploadWrap.style.display = 'none';
        previewPresetChange();
    } else {
        presetWrap.style.display = 'none';
        uploadWrap.style.display = 'block';
        
        // Restore initial upload if source matches and no new file selected
        const fileInput = document.getElementById('lottie_file');
        if (fileInput.files && fileInput.files[0]) {
            previewUploadChange(fileInput);
        } else if (initialSource === 'upload') {
            player.setAttribute('src', rootUrl + 'api/' + initialLottieFile);
        } else {
            player.setAttribute('src', '');
        }
    }
}

// Preview Preset Change
function previewPresetChange() {
    const preset = document.getElementById('lottie_preset').value;
    const player = document.getElementById('lottiePreviewPlayer');
    if (preset) {
        const filename = preset.split('/').pop();
        loadLottieToPlayer('get_preset.php?file=' + encodeURIComponent(filename), player);
    }
}

// Preview Upload File Change
function previewUploadChange(input) {
    const player = document.getElementById('lottiePreviewPlayer');
    if (input.files && input.files[0]) {
        const file = input.files[0];
        
        if (file.name.endsWith('.json')) {
            const reader = new FileReader();
            reader.onload = function(e) {
                try {
                    const data = JSON.parse(e.target.result);
                    player.load(data);
                } catch (err) {
                    console.error('Invalid JSON file uploaded:', err);
                }
            };
            reader.readAsText(file);
        } else {
            player.setAttribute('src', '');
        }
    }
}

// Initialize player on page load
function initPlayer() {
    const player = document.getElementById('lottiePreviewPlayer');
    if (initialSource === 'upload') {
        player.setAttribute('src', rootUrl + 'api/' + initialLottieFile);
    } else {
        const filename = initialLottieFile.split('/').pop();
        loadLottieToPlayer('get_preset.php?file=' + encodeURIComponent(filename), player);
    }
}

// Initial triggers
updateTargetUnit();
initPlayer();
</script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

<?php
/**
 * Recipes Management - Create
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Tambah Resep';
require_once __DIR__ . '/../../includes/header.php';
require_once __DIR__ . '/../../../api/helpers/upload.php';

$db = Database::getInstance()->getConnection();
$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $calories = !empty($_POST['calories']) ? (int) $_POST['calories'] : null;
    $prepTime = !empty($_POST['prep_time_minutes']) ? (int) $_POST['prep_time_minutes'] : null;
    $isPublished = isset($_POST['is_published']) ? 1 : 0;
    $ingredients = $_POST['ingredients'] ?? [];
    $ingredientAmounts = $_POST['ingredient_amounts'] ?? [];
    $steps = $_POST['steps'] ?? [];
    
    // New fields
    $protein = !empty($_POST['protein']) ? (int) $_POST['protein'] : null;
    $carbs = !empty($_POST['carbs']) ? (int) $_POST['carbs'] : null;
    $fat = !empty($_POST['fat']) ? (int) $_POST['fat'] : null;
    $tips = !empty($_POST['tips']) ? trim($_POST['tips']) : null;
    $tags = !empty($_POST['tags']) && is_array($_POST['tags']) ? implode(',', $_POST['tags']) : null;

    if (empty($title)) $errors[] = 'Judul wajib diisi';
    if ($calories !== null && $calories < 0) $errors[] = 'Kalori tidak boleh kurang dari 0';
    if ($prepTime !== null && $prepTime < 0) $errors[] = 'Waktu masak tidak boleh kurang dari 0';
    if ($protein !== null && $protein < 0) $errors[] = 'Protein tidak boleh kurang dari 0';
    if ($carbs !== null && $carbs < 0) $errors[] = 'Karbohidrat tidak boleh kurang dari 0';
    if ($fat !== null && $fat < 0) $errors[] = 'Lemak tidak boleh kurang dari 0';

    // Handle photo upload
    $photoPath = null;
    if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
        $photoPath = uploadImage($_FILES['photo'], 'recipes');
        if (!$photoPath) $errors[] = 'Gagal upload foto';
    }

    if (empty($errors)) {
        $db->beginTransaction();
        try {
            $publishedAt = $isPublished ? date('Y-m-d H:i:s') : null;
            $stmt = $db->prepare(
                "INSERT INTO recipes (title, photo, description, calories, prep_time_minutes, is_published, published_at, tags, protein, carbs, fat, tips) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            );
            $stmt->execute([$title, $photoPath, $description, $calories, $prepTime, $isPublished, $publishedAt, $tags, $protein, $carbs, $fat, $tips]);
            $recipeId = $db->lastInsertId();

            // Insert ingredients
            $stmtIng = $db->prepare(
                "INSERT INTO recipe_ingredients (recipe_id, ingredient, amount, sort_order) VALUES (?, ?, ?, ?)"
            );
            foreach ($ingredients as $i => $ing) {
                $ing = trim($ing);
                if (!empty($ing)) {
                    $amount = trim($ingredientAmounts[$i] ?? '');
                    $stmtIng->execute([$recipeId, $ing, $amount, $i + 1]);
                }
            }

            // Insert steps
            $stmtStep = $db->prepare(
                "INSERT INTO recipe_steps (recipe_id, step_number, description) VALUES (?, ?, ?)"
            );
            $stepNum = 1;
            foreach ($steps as $step) {
                $step = trim($step);
                if (!empty($step)) {
                    $stmtStep->execute([$recipeId, $stepNum, $step]);
                    $stepNum++;
                }
            }

            $db->commit();

            // Send Push Notification if published
            if ($isPublished && $recipeId) {
                require_once __DIR__ . '/../../../api/helpers/push_notification.php';
                sendPushNotification('Resep Baru', $title, 'recipe', $recipeId);
            }

            $_SESSION['flash_success'] = 'Resep berhasil ditambahkan';
            header('Location: index.php');
            exit;
        } catch (Exception $e) {
            $db->rollBack();
            $errors[] = 'Gagal menyimpan resep: ' . $e->getMessage();
        }
    }
}
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🥗 Tambah Resep</span>
            <a href="index.php" class="btn btn-sm btn-secondary">
                <i class="bi bi-arrow-left"></i> Kembali
            </a>
        </div>

        <div class="content-area">
            <?php if (!empty($errors)): ?>
                <div class="alert alert-error">
                    <i class="bi bi-exclamation-circle"></i>
                    <div><?= implode('<br>', $errors) ?></div>
                </div>
            <?php endif; ?>

            <form method="POST" enctype="multipart/form-data">
                <!-- Basic Info -->
                <div class="card mb-3">
                    <div class="card-header">
                        <h3>Informasi Dasar</h3>
                    </div>
                    <div class="card-body">
                        <div class="form-group">
                            <label for="title">Judul Resep *</label>
                            <input type="text" id="title" name="title" class="form-control"
                                   value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
                                   placeholder="Contoh: Nasi Goreng Vegetarian" required>
                        </div>

                        <div class="form-group">
                            <label for="description">Deskripsi</label>
                            <textarea id="description" name="description" class="form-control" rows="3"
                                      placeholder="Deskripsi singkat tentang resep ini..."><?= htmlspecialchars($_POST['description'] ?? '') ?></textarea>
                        </div>

                        <div class="form-group">
                            <label for="prep_time_minutes">Waktu Masak (menit)</label>
                            <input type="number" id="prep_time_minutes" name="prep_time_minutes" class="form-control"
                                   value="<?= htmlspecialchars($_POST['prep_time_minutes'] ?? '') ?>"
                                   placeholder="Contoh: 30" min="0">
                        </div>

                        <div class="form-group">
                            <label>Kategori Makanan / Tags (Pilih satu atau lebih)</label>
                            <div style="display: flex; flex-wrap: wrap; gap: 16px; margin-top: 8px;">
                                <?php
                                $availableTags = ['High Protein', 'Vegan', 'Vegetarian', 'Low Calorie', 'Gluten Free', 'Dairy Free'];
                                foreach ($availableTags as $tag):
                                ?>
                                    <div class="form-check form-check-inline" style="display: inline-flex; align-items: center;">
                                        <label style="display: inline-flex; align-items: center; gap: 8px; cursor: pointer; text-transform: none; letter-spacing: normal; font-size: 14px; font-weight: 500; margin: 0;">
                                            <input type="checkbox" name="tags[]" value="<?= htmlspecialchars($tag) ?>"
                                                   <?= isset($_POST['tags']) && in_array($tag, $_POST['tags']) ? 'checked' : '' ?>
                                                   style="width: 16px; height: 16px; accent-color: var(--primary);">
                                            <?= htmlspecialchars($tag) ?>
                                        </label>
                                    </div>
                                <?php endforeach; ?>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="photo">Foto Resep</label>
                            <div class="upload-area" onclick="document.getElementById('photo').click()">
                                <div class="upload-icon"><i class="bi bi-cloud-arrow-up"></i></div>
                                <p>Klik untuk upload foto<br><small>JPG, PNG, WebP — Max 5MB</small></p>
                            </div>
                            <input type="file" id="photo" name="photo" accept="image/*"
                                   style="display:none" onchange="previewImage(this, 'photoPreview')">
                            <div id="photoPreview"></div>
                        </div>
                    </div>
                </div>

                <!-- Nutritional Info -->
                <div class="card mb-3">
                    <div class="card-header">
                        <h3>📊 Informasi Nutrisi</h3>
                    </div>
                    <div class="card-body">
                        <div style="display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 16px;">
                            <div class="form-group" style="margin-bottom: 0;">
                                <label for="calories">Kalori (kcal)</label>
                                <input type="number" id="calories" name="calories" class="form-control"
                                       value="<?= htmlspecialchars($_POST['calories'] ?? '') ?>"
                                       placeholder="Contoh: 350" min="0">
                            </div>
                            <div class="form-group" style="margin-bottom: 0;">
                                <label for="protein">Protein (g)</label>
                                <input type="number" id="protein" name="protein" class="form-control"
                                       value="<?= htmlspecialchars($_POST['protein'] ?? '') ?>"
                                       placeholder="Contoh: 15" min="0">
                            </div>
                            <div class="form-group" style="margin-bottom: 0;">
                                <label for="carbs">Karbohidrat (g)</label>
                                <input type="number" id="carbs" name="carbs" class="form-control"
                                       value="<?= htmlspecialchars($_POST['carbs'] ?? '') ?>"
                                       placeholder="Contoh: 45" min="0">
                            </div>
                            <div class="form-group" style="margin-bottom: 0;">
                                <label for="fat">Lemak (g)</label>
                                <input type="number" id="fat" name="fat" class="form-control"
                                       value="<?= htmlspecialchars($_POST['fat'] ?? '') ?>"
                                       placeholder="Contoh: 10" min="0">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Cooking Tips -->
                <div class="card mb-3">
                    <div class="card-header">
                        <h3>💡 Tips Memasak</h3>
                    </div>
                    <div class="card-body">
                        <div class="form-group" style="margin-bottom: 0;">
                            <label for="tips">Tips / Saran Penyajian</label>
                            <textarea id="tips" name="tips" class="form-control" rows="4"
                                      placeholder="Masukkan tips atau saran terkait resep ini..."><?= htmlspecialchars($_POST['tips'] ?? '') ?></textarea>
                            <small class="text-muted" style="margin-top: 6px; display: block;">Mendukung penjelasan panjang, langkah alternatif, atau tips penyajian khusus.</small>
                        </div>
                    </div>
                </div>

                <!-- Ingredients -->
                <div class="card mb-3">
                    <div class="card-header">
                        <h3>🥬 Bahan-bahan</h3>
                        <button type="button" class="btn btn-sm btn-secondary" onclick="addIngredient()">
                            <i class="bi bi-plus"></i> Tambah Bahan
                        </button>
                    </div>
                    <div class="card-body" id="ingredientsList">
                        <div class="ingredient-row d-flex gap-1 mb-1" style="align-items: flex-end;">
                            <div style="flex: 2;">
                                <label>Bahan</label>
                                <input type="text" name="ingredients[]" class="form-control" placeholder="Contoh: Tahu">
                            </div>
                            <div style="flex: 1;">
                                <label>Jumlah</label>
                                <input type="text" name="ingredient_amounts[]" class="form-control" placeholder="Contoh: 200g">
                            </div>
                            <button type="button" class="btn btn-sm btn-danger" onclick="this.parentElement.remove()" style="margin-bottom: 20px;">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Steps -->
                <div class="card mb-3">
                    <div class="card-header">
                        <h3>👨‍🍳 Langkah Memasak</h3>
                        <button type="button" class="btn btn-sm btn-secondary" onclick="addStep()">
                            <i class="bi bi-plus"></i> Tambah Langkah
                        </button>
                    </div>
                    <div class="card-body" id="stepsList">
                        <div class="step-row d-flex gap-1 mb-1" style="align-items: flex-start;">
                            <div style="width: 36px; height: 36px; border-radius: 50%; background: var(--accent-light); color: var(--primary); display: flex; align-items: center; justify-content: center; font-weight: 600; flex-shrink: 0; margin-top: 8px;" class="step-number">1</div>
                            <div style="flex: 1;">
                                <textarea name="steps[]" class="form-control" rows="2" placeholder="Jelaskan langkah memasak..."></textarea>
                            </div>
                            <button type="button" class="btn btn-sm btn-danger" onclick="removeStep(this)" style="margin-top: 8px;">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Publish -->
                <div class="card mb-3">
                    <div class="card-body">
                        <div class="form-group" style="margin-bottom: 0;">
                            <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; text-transform: none; letter-spacing: normal; font-size: 14px;">
                                <input type="checkbox" name="is_published" value="1">
                                Publish langsung
                            </label>
                        </div>
                    </div>
                </div>

                <div class="d-flex gap-1">
                    <button type="submit" class="btn btn-primary btn-lg">
                        <i class="bi bi-check-circle"></i> Simpan Resep
                    </button>
                    <a href="index.php" class="btn btn-secondary btn-lg">Batal</a>
                </div>
            </form>
        </div>
    </main>
</div>

<script>
function addIngredient() {
    const list = document.getElementById('ingredientsList');
    const html = `
        <div class="ingredient-row d-flex gap-1 mb-1" style="align-items: flex-end;">
            <div style="flex: 2;">
                <input type="text" name="ingredients[]" class="form-control" placeholder="Nama bahan">
            </div>
            <div style="flex: 1;">
                <input type="text" name="ingredient_amounts[]" class="form-control" placeholder="Jumlah">
            </div>
            <button type="button" class="btn btn-sm btn-danger" onclick="this.parentElement.remove()" style="margin-bottom: 20px;">
                <i class="bi bi-trash"></i>
            </button>
        </div>
    `;
    list.insertAdjacentHTML('beforeend', html);
}

function addStep() {
    const list = document.getElementById('stepsList');
    const stepCount = list.querySelectorAll('.step-row').length + 1;
    const html = `
        <div class="step-row d-flex gap-1 mb-1" style="align-items: flex-start;">
            <div style="width: 36px; height: 36px; border-radius: 50%; background: var(--accent-light); color: var(--primary); display: flex; align-items: center; justify-content: center; font-weight: 600; flex-shrink: 0; margin-top: 8px;" class="step-number">${stepCount}</div>
            <div style="flex: 1;">
                <textarea name="steps[]" class="form-control" rows="2" placeholder="Jelaskan langkah memasak..."></textarea>
            </div>
            <button type="button" class="btn btn-sm btn-danger" onclick="removeStep(this)" style="margin-top: 8px;">
                <i class="bi bi-trash"></i>
            </button>
        </div>
    `;
    list.insertAdjacentHTML('beforeend', html);
}

function removeStep(btn) {
    btn.closest('.step-row').remove();
    // Re-number remaining steps
    document.querySelectorAll('#stepsList .step-number').forEach((el, i) => {
        el.textContent = i + 1;
    });
}
</script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

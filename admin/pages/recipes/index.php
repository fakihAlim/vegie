<?php
/**
 * Recipes Management - List
 * LovingHarmony Admin Panel
 */

// Start session if not started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Check admin auth (must be checked before template download check)
if (!isset($_SESSION['admin_id'])) {
    header('Location: ../../login.php');
    exit;
}

// Handle template download (must be handled before header.php to prevent rendering any HTML output)
if (isset($_GET['download_template'])) {
    $sampleRecipe = [
        "title" => "Nasi Goreng Vegetarian Premium",
        "description" => "Nasi goreng lezat dengan campuran sayuran segar dan tahu goreng.",
        "prep_time_minutes" => 25,
        "calories" => 380,
        "protein" => 12,
        "carbs" => 55,
        "fat" => 10,
        "tips" => "Gunakan nasi yang sudah dingin agar tekstur nasi goreng lebih pera dan tidak lembek.",
        "tags" => ["Vegetarian", "Vegan", "Low Calorie"],
        "ingredients" => [
            ["name" => "Nasi putih dingin", "amount" => "2 piring"],
            ["name" => "Tahu putih, potong dadu dan goreng", "amount" => "100g"],
            ["name" => "Wortel, potong dadu kecil", "amount" => "50g"],
            ["name" => "Kacang polong", "amount" => "30g"],
            ["name" => "Kecap manis", "amount" => "2 sdm"],
            ["name" => "Garam dan lada", "amount" => "secukupnya"]
        ],
        "steps" => [
            "Panaskan sedikit minyak di wajan, lalu tumis wortel hingga agak layu.",
            "Masukkan tahu goreng dan kacang polong, aduk rata.",
            "Masukkan nasi putih, aduk rata dengan sayuran.",
            "Tambahkan kecap manis, garam, dan lada. Aduk hingga bumbu merata dan nasi goreng matang.",
            "Sajikan selagi hangat dengan taburan bawang goreng jika suka."
        ]
    ];
    $templateData = [$sampleRecipe];
    
    header('Content-Type: application/json');
    header('Content-Disposition: attachment; filename="template_resep.json"');
    echo json_encode($templateData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    exit;
}

require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    $stmt = $db->prepare("SELECT photo FROM recipes WHERE id = ?");
    $stmt->execute([$id]);
    $recipe = $stmt->fetch();
    
    if ($recipe) {
        if ($recipe['photo']) {
            $filePath = __DIR__ . '/../../../api/' . $recipe['photo'];
            if (file_exists($filePath)) unlink($filePath);
        }
        $stmt = $db->prepare("DELETE FROM recipes WHERE id = ?");
        $stmt->execute([$id]);
        $_SESSION['flash_success'] = 'Resep berhasil dihapus';
    }
    header('Location: index.php');
    exit;
}

// Handle publish/unpublish toggle
if (isset($_GET['toggle'])) {
    $id = (int) $_GET['toggle'];
    $stmt = $db->prepare("SELECT is_published FROM recipes WHERE id = ?");
    $stmt->execute([$id]);
    $recipe = $stmt->fetch();
    
    if ($recipe) {
        $newStatus = $recipe['is_published'] ? 0 : 1;
        $publishedAt = $newStatus ? date('Y-m-d H:i:s') : null;
        $stmt = $db->prepare("UPDATE recipes SET is_published = ?, published_at = ? WHERE id = ?");
        $stmt->execute([$newStatus, $publishedAt, $id]);
        $_SESSION['flash_success'] = $newStatus ? 'Resep dipublish' : 'Resep di-unpublish';
    }
    header('Location: index.php');
    exit;
}

// Handle JSON import
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['import_json'])) {
    $jsonContent = '';
    
    // Check if file was uploaded
    if (isset($_FILES['json_file']) && $_FILES['json_file']['error'] === UPLOAD_ERR_OK) {
        $jsonContent = file_get_contents($_FILES['json_file']['tmp_name']);
    } elseif (!empty($_POST['json_text'])) {
        $jsonContent = trim($_POST['json_text']);
    }
    
    if (empty($jsonContent)) {
        $_SESSION['flash_error'] = 'Harap pilih file JSON atau tempel kode JSON.';
    } else {
        $data = json_decode($jsonContent, true);
        if ($data === null) {
            $_SESSION['flash_error'] = 'Format JSON tidak valid. Pastikan penulisan JSON sudah benar.';
        } else {
            $recipesToImport = [];
            
            // Check structure: single object vs array of objects
            if (isset($data['title'])) {
                // Single recipe object
                $recipesToImport[] = $data;
            } elseif (is_array($data) && !empty($data)) {
                $firstItem = reset($data);
                if (is_array($firstItem) && isset($firstItem['title'])) {
                    // Array of recipe objects
                    $recipesToImport = $data;
                } else {
                    $_SESSION['flash_error'] = 'Struktur JSON tidak dikenali. Harus berisi satu objek resep atau daftar resep.';
                }
            } else {
                $_SESSION['flash_error'] = 'Struktur JSON kosong atau tidak dikenali.';
            }
            
            if (!empty($recipesToImport)) {
                $db->beginTransaction();
                $successCount = 0;
                $errors = [];
                
                try {
                    $stmtRecipe = $db->prepare(
                        "INSERT INTO recipes (title, description, calories, prep_time_minutes, is_published, published_at, tags, protein, carbs, fat, tips) 
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                    );
                    $stmtIng = $db->prepare(
                        "INSERT INTO recipe_ingredients (recipe_id, ingredient, amount, sort_order) VALUES (?, ?, ?, ?)"
                    );
                    $stmtStep = $db->prepare(
                        "INSERT INTO recipe_steps (recipe_id, step_number, description) VALUES (?, ?, ?)"
                    );
                    
                    foreach ($recipesToImport as $idx => $r) {
                        $title = trim($r['title'] ?? '');
                        if (empty($title)) {
                            $errors[] = "Resep ke-" . ($idx + 1) . ": Judul wajib diisi.";
                            continue;
                        }
                        
                        $description = isset($r['description']) ? trim($r['description']) : null;
                        $calories = !empty($r['calories']) ? (int) $r['calories'] : null;
                        $prepTime = !empty($r['prep_time_minutes']) ? (int) $r['prep_time_minutes'] : null;
                        $isPublished = isset($r['is_published']) ? (int) $r['is_published'] : 1;
                        $publishedAt = $isPublished ? date('Y-m-d H:i:s') : null;
                        
                        $tagsList = isset($r['tags']) && is_array($r['tags']) ? implode(',', $r['tags']) : null;
                        $protein = !empty($r['protein']) ? (int) $r['protein'] : null;
                        $carbs = !empty($r['carbs']) ? (int) $r['carbs'] : null;
                        $fat = !empty($r['fat']) ? (int) $r['fat'] : null;
                        $tips = isset($r['tips']) ? trim($r['tips']) : null;
                        
                        $stmtRecipe->execute([$title, $description, $calories, $prepTime, $isPublished, $publishedAt, $tagsList, $protein, $carbs, $fat, $tips]);
                        $recipeId = $db->lastInsertId();
                        
                        // Insert ingredients
                        if (isset($r['ingredients']) && is_array($r['ingredients'])) {
                            foreach ($r['ingredients'] as $iIndex => $ing) {
                                if (is_array($ing)) {
                                    $name = trim($ing['name'] ?? '');
                                    $amount = trim($ing['amount'] ?? '');
                                } else {
                                    $name = trim($ing);
                                    $amount = '';
                                }
                                if (!empty($name)) {
                                    $stmtIng->execute([$recipeId, $name, $amount, $iIndex + 1]);
                                }
                            }
                        }
                        
                        // Insert steps
                        if (isset($r['steps']) && is_array($r['steps'])) {
                            foreach ($r['steps'] as $sIndex => $step) {
                                $stepDesc = trim($step);
                                if (!empty($stepDesc)) {
                                    $stmtStep->execute([$recipeId, $sIndex + 1, $stepDesc]);
                                }
                            }
                        }
                        
                        $successCount++;
                    }
                    
                    if (empty($errors)) {
                        $db->commit();
                        $_SESSION['flash_success'] = "Berhasil mengimpor $successCount resep dari file JSON.";
                    } else {
                        $db->rollBack();
                        $_SESSION['flash_error'] = "Gagal mengimpor: " . implode(" ", $errors);
                    }
                } catch (Exception $e) {
                    $db->rollBack();
                    $_SESSION['flash_error'] = 'Gagal menyimpan data resep impor: ' . $e->getMessage();
                }
            }
        }
    }
    header('Location: index.php');
    exit;
}

// Fetch all recipes
$stmt = $db->query("SELECT * FROM recipes ORDER BY created_at DESC");
$recipeList = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🥗 Kelola Resep</span>
            <div class="user-menu">
                <button onclick="openImportModal()" class="btn btn-secondary btn-sm" style="margin-right: 8px;">
                    <i class="bi bi-filetype-json"></i> Import JSON
                </button>
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Resep
                </a>
            </div>
        </div>

        <div class="content-area">
            <!-- Flash Message Alerts -->
            <?php if (isset($_SESSION['flash_success'])): ?>
                <div class="alert alert-success">
                    <i class="bi bi-check-circle"></i>
                    <div><?= $_SESSION['flash_success']; unset($_SESSION['flash_success']); ?></div>
                </div>
            <?php endif; ?>
            <?php if (isset($_SESSION['flash_error'])): ?>
                <div class="alert alert-error">
                    <i class="bi bi-exclamation-circle"></i>
                    <div><?= $_SESSION['flash_error']; unset($_SESSION['flash_error']); ?></div>
                </div>
            <?php endif; ?>

            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($recipeList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">🥗</div>
                            <p>Belum ada resep. Klik "Tambah Resep" atau "Import JSON" untuk membuat yang pertama.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Foto</th>
                                        <th>Judul</th>
                                        <th>Kalori</th>
                                        <th>Waktu Masak</th>
                                        <th>Status</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($recipeList as $i => $recipe): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <?php if ($recipe['photo']): ?>
                                                    <img src="../../../api/<?= htmlspecialchars($recipe['photo']) ?>" 
                                                         class="thumbnail" alt="Recipe">
                                                <?php else: ?>
                                                    <div class="thumbnail" style="background: var(--accent-light); display: flex; align-items: center; justify-content: center;">
                                                        <i class="bi bi-image" style="color: var(--text-muted);"></i>
                                                    </div>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <strong><?= htmlspecialchars($recipe['title']) ?></strong>
                                                <?php if ($recipe['description']): ?>
                                                    <br><small class="text-muted"><?= mb_substr($recipe['description'], 0, 60) ?>...</small>
                                                <?php endif; ?>
                                            </td>
                                            <td><?= $recipe['calories'] ? $recipe['calories'] . ' kcal' : '-' ?></td>
                                            <td><?= $recipe['prep_time_minutes'] ? $recipe['prep_time_minutes'] . ' min' : '-' ?></td>
                                            <td>
                                                <?php if ($recipe['is_published']): ?>
                                                    <span class="badge badge-success">Published</span>
                                                <?php else: ?>
                                                    <span class="badge badge-warning">Draft</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div class="actions">
                                                    <a href="detail.php?id=<?= $recipe['id'] ?>" class="btn btn-sm btn-outline" title="Detail" style="border-color: var(--primary-light); color: var(--primary-light);">
                                                        <i class="bi bi-info-circle"></i>
                                                    </a>
                                                    <a href="edit.php?id=<?= $recipe['id'] ?>" class="btn btn-sm btn-secondary" title="Edit">
                                                        <i class="bi bi-pencil"></i>
                                                    </a>
                                                    <a href="?toggle=<?= $recipe['id'] ?>" class="btn btn-sm btn-outline" title="Toggle">
                                                        <i class="bi bi-<?= $recipe['is_published'] ? 'eye-slash' : 'eye' ?>"></i>
                                                    </a>
                                                    <button onclick="confirmDelete('?delete=<?= $recipe['id'] ?>', '<?= addslashes($recipe['title']) ?>')" 
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

<!-- Modal Import JSON -->
<div id="importModal" class="modal-overlay">
    <div class="modal">
        <div class="modal-header">
            <h3>📥 Import Resep via JSON</h3>
            <button class="modal-close" onclick="closeImportModal()">&times;</button>
        </div>
        <form method="POST" enctype="multipart/form-data">
            <input type="hidden" name="import_json" value="1">
            <div class="modal-body">
                <p class="text-secondary mb-2" style="font-size: 14px; line-height: 1.5;">
                    Unggah file <code>.json</code> atau tempel teks JSON di bawah ini untuk mengimpor satu atau beberapa resep sekaligus.
                </p>
                
                <div class="form-group mb-2">
                    <label for="json_file">Pilih File JSON</label>
                    <input type="file" id="json_file" name="json_file" accept=".json" class="form-control">
                </div>
                
                <div class="form-group mb-2">
                    <label for="json_text">Atau Tempel Teks JSON</label>
                    <textarea id="json_text" name="json_text" class="form-control" rows="8" placeholder='Tempel kode JSON di sini...'></textarea>
                </div>
                
                <div style="margin-top: 16px;">
                    <a href="?download_template=1" class="btn btn-outline btn-sm" style="display: inline-flex; border-color: var(--primary-light); color: var(--primary-light);">
                        <i class="bi bi-download"></i> Unduh Contoh Format JSON
                    </a>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeImportModal()">Batal</button>
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-cloud-arrow-up"></i> Mulai Impor
                </button>
            </div>
        </form>
    </div>
</div>

<script>
function openImportModal() {
    document.getElementById('importModal').classList.add('active');
}
function closeImportModal() {
    document.getElementById('importModal').classList.remove('active');
}
// Tutup modal ketika mengklik area di luar modal
window.addEventListener('click', function(e) {
    const modal = document.getElementById('importModal');
    if (e.target === modal) {
        closeImportModal();
    }
});
</script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

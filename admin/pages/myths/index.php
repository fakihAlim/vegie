<?php
/**
 * Myths & Facts Management
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Kelola Myth vs Fact';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

// Handle delete
if (isset($_GET['delete'])) {
    $id = (int) $_GET['delete'];
    
    // Get image path to delete file from disk
    $stmtImg = $db->prepare("SELECT image_url FROM myth_facts WHERE id = ?");
    $stmtImg->execute([$id]);
    $itemImg = $stmtImg->fetch();
    if ($itemImg && $itemImg['image_url'] && strpos($itemImg['image_url'], 'http') !== 0) {
        $oldPath = __DIR__ . '/../../../api/' . $itemImg['image_url'];
        if (file_exists($oldPath)) {
            unlink($oldPath);
        }
    }

    $stmt = $db->prepare("DELETE FROM myth_facts WHERE id = ?");
    $stmt->execute([$id]);
    $_SESSION['flash_success'] = 'Data berhasil dihapus';
    header('Location: index.php');
    exit;
}

// Fetch all
$stmt = $db->query("SELECT * FROM myth_facts ORDER BY created_at DESC");
$mythsList = $stmt->fetchAll();
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">💡 Kelola Myth vs Fact</span>
            <div class="user-menu" style="display: flex; gap: 12px; align-items: center;">
                <button type="button" class="btn btn-secondary btn-sm" onclick="openAiModal()">
                    <i class="bi bi-robot"></i> Buat dengan AI 🤖
                </button>
                <a href="create.php" class="btn btn-primary btn-sm">
                    <i class="bi bi-plus-circle"></i> Tambah Data
                </a>
            </div>
        </div>

        <div class="content-area">
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

            <div class="card">
                <div class="card-body" style="padding: 0;">
                    <?php if (empty($mythsList)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">💡</div>
                            <p>Belum ada data Myth vs Fact. Klik <strong>"Buat dengan AI"</strong> atau <strong>"Tambah Data"</strong>.</p>
                        </div>
                    <?php else: ?>
                        <div class="table-wrapper">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Gambar</th>
                                        <th>Judul & Deskripsi</th>
                                        <th class="text-center">Tipe</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($mythsList as $i => $item): ?>
                                        <tr>
                                            <td><?= $i + 1 ?></td>
                                            <td>
                                                <?php if ($item['image_url']): ?>
                                                    <?php 
                                                        $imgSrc = $item['image_url'];
                                                        if (strpos($imgSrc, 'http') !== 0) {
                                                            $imgSrc = '../../../api/' . $imgSrc;
                                                        }
                                                    ?>
                                                    <img src="<?= htmlspecialchars($imgSrc) ?>" alt="img" style="width: 60px; height: 60px; object-fit: cover; border-radius: 8px; border: 1px solid #eee;">
                                                <?php else: ?>
                                                    <div style="width: 60px; height: 60px; background: #f0f0f0; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: #aaa;">
                                                        <i class="bi bi-image"></i>
                                                    </div>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div style="font-weight: bold; max-width: 300px; word-wrap: break-word;">
                                                    <?= htmlspecialchars($item['title']) ?>
                                                </div>
                                                <div class="text-muted" style="font-size: 12px; margin-top: 4px; max-width: 350px;">
                                                    <?= htmlspecialchars($item['description']) ?>
                                                </div>
                                            </td>
                                            <td class="text-center">
                                                <?php if ($item['type'] === 'myth'): ?>
                                                    <span class="badge badge-warning" style="background: orange; color: white;">Mitos</span>
                                                <?php else: ?>
                                                    <span class="badge badge-success" style="background: green; color: white;">Fakta</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div class="actions">
                                                    <a href="edit.php?id=<?= $item['id'] ?>" class="btn btn-sm btn-secondary" title="Edit">
                                                        <i class="bi bi-pencil"></i>
                                                    </a>
                                                    <button onclick="confirmDelete('?delete=<?= $item['id'] ?>', '<?= addslashes($item['title']) ?>')" 
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

<!-- AI Myth Generator Modal -->
<div class="modal-overlay" id="aiModal">
    <div class="modal" style="max-width: 600px;">
        <div class="modal-header">
            <h3>🤖 Buat Myth vs Fact dengan AI</h3>
            <button class="modal-close" onclick="closeAiModal()">&times;</button>
        </div>
        
        <!-- Step 1: AI Prompt Input -->
        <div id="ai-step-prompt" class="modal-body">
            <div class="form-group" style="margin-bottom: 16px;">
                <label style="display: block; margin-bottom: 8px; font-weight: bold;">Mode Prompt</label>
                <div style="display: flex; gap: 20px;">
                    <label style="display: flex; align-items: center; gap: 6px; font-weight: normal; cursor: pointer;">
                        <input type="radio" name="ai_mode" value="auto" checked onchange="togglePromptInput()"> Otomatis (Optimal)
                    </label>
                    <label style="display: flex; align-items: center; gap: 6px; font-weight: normal; cursor: pointer;">
                        <input type="radio" name="ai_mode" value="custom" onchange="togglePromptInput()"> Kustom (Prompt Admin)
                    </label>
                </div>
            </div>
            
            <div id="custom-prompt-container" class="form-group" style="margin-bottom: 16px; display: none;">
                <label for="custom_prompt" style="display: block; margin-bottom: 8px; font-weight: bold;">Permintaan / Topik Khusus</label>
                <textarea id="custom_prompt" class="form-control" rows="3" placeholder="Contoh: Buat mitos tentang susu kedelai atau bayam sebagai sumber besi..." style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;"></textarea>
            </div>

            <div id="ai-loading" class="text-center" style="display: none; padding: 20px; background: #e0f7fa; border-radius: 8px; margin-bottom: 16px; color: #00838f;">
                <div class="spinner-border spinner-border-sm" role="status" style="margin-right: 8px; width: 1.5rem; height: 1.5rem; vertical-align: middle;"></div>
                <span style="font-weight: bold;">Sedang merumuskan data menggunakan AI... Mohon tunggu.</span>
            </div>
            
            <div id="ai-error" class="alert alert-danger" style="display: none; padding: 12px; background: #ffebee; color: #c62828; border-radius: 8px; margin-bottom: 16px;"></div>
        </div>
        
        <div id="ai-step-prompt-footer" class="modal-footer">
            <button type="button" class="btn btn-secondary" onclick="closeAiModal()">Batal</button>
            <button type="button" class="btn btn-primary" id="btn-generate-ai" onclick="generateAiContent()">
                <i class="bi bi-cpu"></i> Hasilkan Data 🤖
            </button>
        </div>

        <!-- Step 2: Form Review & Save (Multipart Form) -->
        <form id="ai-save-form" method="POST" action="create.php" enctype="multipart/form-data" style="display: none; margin: 0;">
            <div class="modal-body">
                <div class="alert alert-success" style="padding: 10px 16px; border-radius: 8px; background: #e8f5e9; color: #2e7d32; border: 1px solid #c8e6c9; font-size: 13px; margin-bottom: 16px;">
                    🤖 <strong>AI Berhasil Merumuskan Data!</strong> Silakan periksa kembali konten di bawah ini, tambahkan gambar jika perlu, lalu simpan.
                </div>
                
                <div class="form-group" style="margin-bottom: 16px;">
                    <label for="ai_title" style="display: block; margin-bottom: 8px; font-weight: bold;">Judul</label>
                    <input type="text" id="ai_title" name="title" class="form-control" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                </div>
                
                <div class="form-group" style="margin-bottom: 16px;">
                    <label for="ai_type" style="display: block; margin-bottom: 8px; font-weight: bold;">Tipe</label>
                    <select id="ai_type" name="type" class="form-control" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                        <option value="myth">Mitos</option>
                        <option value="fact">Fakta</option>
                    </select>
                </div>

                <div class="form-group" style="margin-bottom: 16px;">
                    <label for="ai_description" style="display: block; margin-bottom: 8px; font-weight: bold;">Deskripsi</label>
                    <textarea id="ai_description" name="description" class="form-control" rows="4" required style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;"></textarea>
                </div>

                <div class="form-group" style="margin-bottom: 8px;">
                    <label for="ai_image" style="display: block; margin-bottom: 8px; font-weight: bold;">Upload Gambar (Opsional)</label>
                    <input type="file" id="ai_image" name="image" class="form-control" accept="image/*" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">
                    <small class="text-muted" style="display: block; margin-top: 4px;">File gambar berformat JPG, PNG, GIF, atau WEBP (Maksimal 5MB).</small>
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="backToPromptStep()">Kembali</button>
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-save"></i> Simpan Data
                </button>
            </div>
        </form>
    </div>
</div>

<script>
function openAiModal() {
    document.getElementById('aiModal').classList.add('active');
    backToPromptStep();
}

function closeAiModal() {
    document.getElementById('aiModal').classList.remove('active');
}

function togglePromptInput() {
    const customRadio = document.querySelector('input[name="ai_mode"]:checked');
    const container = document.getElementById('custom-prompt-container');
    if (customRadio && customRadio.value === 'custom') {
        container.style.display = 'block';
    } else {
        container.style.display = 'none';
    }
}

function backToPromptStep() {
    document.getElementById('ai-step-prompt').style.display = 'block';
    document.getElementById('ai-step-prompt-footer').style.display = 'flex';
    document.getElementById('ai-save-form').style.display = 'none';
    document.getElementById('ai-loading').style.display = 'none';
    document.getElementById('ai-error').style.display = 'none';
}

function generateAiContent() {
    const mode = document.querySelector('input[name="ai_mode"]:checked').value;
    const customPrompt = document.getElementById('custom_prompt').value;
    const btnGen = document.getElementById('btn-generate-ai');
    const loadingDiv = document.getElementById('ai-loading');
    const errorDiv = document.getElementById('ai-error');
    
    errorDiv.style.display = 'none';
    loadingDiv.style.display = 'block';
    btnGen.disabled = true;
    
    fetch('generate_ai.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            mode: mode,
            custom_prompt: customPrompt
        })
    })
    .then(response => {
        if (!response.ok) {
            return response.json().then(err => { throw new Error(err.message || 'Gagal menghasilkan data dengan AI'); });
        }
        return response.json();
    })
    .then(res => {
        btnGen.disabled = false;
        loadingDiv.style.display = 'none';
        
        if (res.success && res.data) {
            // Populate form
            document.getElementById('ai_title').value = res.data.title || '';
            document.getElementById('ai_type').value = res.data.type || 'myth';
            document.getElementById('ai_description').value = res.data.description || '';
            
            // Switch to step 2 review
            document.getElementById('ai-step-prompt').style.display = 'none';
            document.getElementById('ai-step-prompt-footer').style.display = 'none';
            document.getElementById('ai-save-form').style.display = 'block';
        } else {
            throw new Error(res.message || 'Format respons AI tidak valid.');
        }
    })
    .catch(err => {
        btnGen.disabled = false;
        loadingDiv.style.display = 'none';
        errorDiv.textContent = err.message;
        errorDiv.style.display = 'block';
    });
}

// Close modal when clicking outside
window.addEventListener('click', function(e) {
    const modalOverlay = document.getElementById('aiModal');
    if (e.target === modalOverlay) {
        closeAiModal();
    }
});
</script>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

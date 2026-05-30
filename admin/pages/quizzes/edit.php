<?php
/**
 * Quizzes Management - Edit Quiz
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Edit Kuis Nutrisi';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();
$errors = [];
$quiz = null;

if (!isset($_GET['id'])) {
    $_SESSION['flash_error'] = 'ID kuis tidak ditentukan';
    header('Location: index.php');
    exit;
}

$id = (int) $_GET['id'];
$stmt = $db->prepare("SELECT * FROM quizzes WHERE id = ?");
$stmt->execute([$id]);
$quiz = $stmt->fetch();

if (!$quiz) {
    $_SESSION['flash_error'] = 'Kuis tidak ditemukan';
    header('Location: index.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $question = trim($_POST['question'] ?? '');
    $optionA = trim($_POST['option_a'] ?? '');
    $optionB = trim($_POST['option_b'] ?? '');
    $optionC = trim($_POST['option_c'] ?? '');
    $optionD = trim($_POST['option_d'] ?? '');
    $correctAnswer = strtolower(trim($_POST['correct_answer'] ?? ''));
    $explanation = trim($_POST['explanation'] ?? '');
    $points = isset($_POST['points']) ? (int) $_POST['points'] : 50;
    $isActive = isset($_POST['is_active']) ? 1 : 0;

    // Validate
    if (empty($question)) {
        $errors[] = 'Pertanyaan wajib diisi';
    }
    if (empty($optionA) || empty($optionB) || empty($optionC) || empty($optionD)) {
        $errors[] = 'Semua pilihan A, B, C, dan D wajib diisi';
    }
    if (!in_array($correctAnswer, ['a', 'b', 'c', 'd'])) {
        $errors[] = 'Pilih kunci jawaban yang benar (A, B, C, atau D)';
    }
    if (empty($explanation)) {
        $errors[] = 'Penjelasan ilmiah wajib diisi';
    }

    if (empty($errors)) {
        $stmt = $db->prepare(
            "UPDATE quizzes 
             SET question = ?, option_a = ?, option_b = ?, option_c = ?, option_d = ?, correct_answer = ?, explanation = ?, points = ?, is_active = ? 
             WHERE id = ?"
        );
        $stmt->execute([
            $question,
            $optionA,
            $optionB,
            $optionC,
            $optionD,
            $correctAnswer,
            $explanation,
            $points,
            $isActive,
            $id
        ]);

        $_SESSION['flash_success'] = 'Kuis berhasil diperbarui! 🧩';
        header('Location: index.php');
        exit;
    }
}
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🧩 Edit Kuis Nutrisi</span>
            <div class="user-menu">
                <a href="index.php" class="btn btn-outline btn-sm">
                    <i class="bi bi-arrow-left"></i> Kembali
                </a>
            </div>
        </div>

        <div class="content-area">
            <?php if (!empty($errors)): ?>
                <div class="alert alert-danger" style="margin-bottom: 20px; padding: 12px 20px; border-radius: 8px; background: #ffebee; color: #c62828; border: 1px solid #ffcdd2;">
                    <?php foreach ($errors as $error): ?>
                        <p style="margin: 0;"><?= $error ?></p>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>

            <div class="card">
                <div class="card-body">
                    <form method="POST" action="">
                        <div class="form-group">
                            <label for="question">Pertanyaan Kuis <span style="color: var(--error);">*</span></label>
                            <textarea name="question" id="question" rows="3" class="form-control" 
                                      placeholder="Contoh: Manakah di bawah ini yang merupakan sumber Vitamin B12 terbaik untuk vegan?" required><?= htmlspecialchars($_POST['question'] ?? $quiz['question']) ?></textarea>
                        </div>

                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                            <div class="form-group">
                                <label for="option_a">Pilihan A <span style="color: var(--error);">*</span></label>
                                <input type="text" name="option_a" id="option_a" class="form-control" 
                                       placeholder="Masukkan teks pilihan A" 
                                       value="<?= htmlspecialchars($_POST['option_a'] ?? $quiz['option_a']) ?>" required>
                            </div>
                            <div class="form-group">
                                <label for="option_b">Pilihan B <span style="color: var(--error);">*</span></label>
                                <input type="text" name="option_b" id="option_b" class="form-control" 
                                       placeholder="Masukkan teks pilihan B" 
                                       value="<?= htmlspecialchars($_POST['option_b'] ?? $quiz['option_b']) ?>" required>
                            </div>
                            <div class="form-group">
                                <label for="option_c">Pilihan C <span style="color: var(--error);">*</span></label>
                                <input type="text" name="option_c" id="option_c" class="form-control" 
                                       placeholder="Masukkan teks pilihan C" 
                                       value="<?= htmlspecialchars($_POST['option_c'] ?? $quiz['option_c']) ?>" required>
                            </div>
                            <div class="form-group">
                                <label for="option_d">Pilihan D <span style="color: var(--error);">*</span></label>
                                <input type="text" name="option_d" id="option_d" class="form-control" 
                                       placeholder="Masukkan teks pilihan D" 
                                       value="<?= htmlspecialchars($_POST['option_d'] ?? $quiz['option_d']) ?>" required>
                            </div>
                        </div>

                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                            <div class="form-group">
                                <label for="correct_answer">Kunci Jawaban Benar <span style="color: var(--error);">*</span></label>
                                <select name="correct_answer" id="correct_answer" class="form-control" required>
                                    <option value="">-- Pilih Opsi yang Benar --</option>
                                    <?php $selAns = strtolower($_POST['correct_answer'] ?? $quiz['correct_answer']); ?>
                                    <option value="a" <?= $selAns === 'a' ? 'selected' : '' ?>>A</option>
                                    <option value="b" <?= $selAns === 'b' ? 'selected' : '' ?>>B</option>
                                    <option value="c" <?= $selAns === 'c' ? 'selected' : '' ?>>C</option>
                                    <option value="d" <?= $selAns === 'd' ? 'selected' : '' ?>>D</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label for="points">Poin Alokasi</label>
                                <input type="number" name="points" id="points" class="form-control" min="5" max="1000" step="5"
                                       value="<?= htmlspecialchars($_POST['points'] ?? $quiz['points']) ?>">
                                <small class="text-muted">Standar perolehan adalah 50 Poin</small>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="explanation">Penjelasan Ilmiah / Edukasi <span style="color: var(--error);">*</span></label>
                            <textarea name="explanation" id="explanation" rows="3" class="form-control" 
                                      placeholder="Berikan penjelasan ilmiah kenapa jawaban tersebut benar..." required><?= htmlspecialchars($_POST['explanation'] ?? $quiz['explanation']) ?></textarea>
                            <small class="text-muted">Akan ditampilkan kepada pengguna setelah mereka submit jawaban.</small>
                        </div>

                        <div class="form-group" style="display: flex; align-items: center; gap: 8px; margin-top: 16px;">
                            <?php $isAct = isset($_POST['is_active']) ? (bool)$_POST['is_active'] : (bool)$quiz['is_active']; ?>
                            <input type="checkbox" name="is_active" id="is_active" value="1" 
                                   <?= $isAct ? 'checked' : '' ?>>
                            <label for="is_active" style="margin: 0; font-weight: bold; cursor: pointer;">Kuis Ini Aktif (Muncul di Aplikasi)</label>
                        </div>

                        <div class="form-actions" style="margin-top: 28px;">
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-check-circle"></i> Simpan Perubahan
                            </button>
                            <a href="index.php" class="btn btn-outline">Batal</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

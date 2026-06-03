<?php
/**
 * Recipes Management - Detail
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Detail Resep';
require_once __DIR__ . '/../../includes/header.php';

$db = Database::getInstance()->getConnection();

$id = (int) ($_GET['id'] ?? 0);
$stmt = $db->prepare("SELECT * FROM recipes WHERE id = ?");
$stmt->execute([$id]);
$recipe = $stmt->fetch();

if (!$recipe) {
    $_SESSION['flash_error'] = 'Resep tidak ditemukan';
    header('Location: index.php');
    exit;
}

// Get ingredients & steps
$stmt = $db->prepare("SELECT * FROM recipe_ingredients WHERE recipe_id = ? ORDER BY sort_order");
$stmt->execute([$id]);
$ingredients = $stmt->fetchAll();

$stmt = $db->prepare("SELECT * FROM recipe_steps WHERE recipe_id = ? ORDER BY step_number");
$stmt->execute([$id]);
$steps = $stmt->fetchAll();

$recipeTags = !empty($recipe['tags']) ? explode(',', $recipe['tags']) : [];
?>

<div class="app-layout">
    <?php require_once __DIR__ . '/../../includes/sidebar.php'; ?>

    <main class="main-content">
        <div class="top-bar">
            <span class="page-title">🥗 Detail Resep: <?= htmlspecialchars($recipe['title']) ?></span>
            <div class="user-menu">
                <a href="edit.php?id=<?= $recipe['id'] ?>" class="btn btn-primary btn-sm">
                    <i class="bi bi-pencil"></i> Edit Resep
                </a>
                <a href="index.php" class="btn btn-secondary btn-sm">
                    <i class="bi bi-arrow-left"></i> Kembali
                </a>
            </div>
        </div>

        <div class="content-area" style="padding: 24px;">
            <div class="d-flex gap-2" style="flex-wrap: wrap; align-items: flex-start;">
                
                <!-- LEFT COLUMN: Recipe Overview (Width: 360px) -->
                <div style="flex: 1; min-width: 320px; max-width: 400px; display: flex; flex-direction: column; gap: 24px;">
                    
                    <!-- Recipe Photo & Basic Info Card -->
                    <div class="card" style="border-radius: var(--radius-lg); overflow: hidden; box-shadow: var(--shadow-md);">
                        <?php if ($recipe['photo']): ?>
                            <img src="../../../api/<?= htmlspecialchars($recipe['photo']) ?>"
                                 style="width: 100%; height: 240px; object-fit: cover; border-bottom: 1px solid var(--border-light);" alt="Recipe Photo">
                        <?php else: ?>
                            <div style="width: 100%; height: 240px; background: var(--accent-light); display: flex; align-items: center; justify-content: center; border-bottom: 1px solid var(--border-light);">
                                <i class="bi bi-image" style="font-size: 64px; color: var(--primary);"></i>
                            </div>
                        <?php endif; ?>
                        
                        <div class="card-body" style="padding: 20px;">
                            <h2 style="font-size: 20px; font-weight: 700; color: var(--primary-dark); margin-bottom: 8px; font-family: 'Poppins', sans-serif;">
                                <?= htmlspecialchars($recipe['title']) ?>
                            </h2>
                            <p class="text-muted" style="font-size: 14px; margin-bottom: 16px; line-height: 1.5;">
                                <?= htmlspecialchars($recipe['description'] ?? 'Tidak ada deskripsi.') ?>
                            </p>
                            
                            <ul style="list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 14px; font-size: 14px;">
                                <li style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border-light); padding-bottom: 8px;">
                                    <span class="text-muted"><i class="bi bi-clock-history" style="margin-right: 6px;"></i> Waktu Masak</span>
                                    <strong><?= $recipe['prep_time_minutes'] ? $recipe['prep_time_minutes'] . ' Menit' : '-' ?></strong>
                                </li>
                                <li style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border-light); padding-bottom: 8px;">
                                    <span class="text-muted"><i class="bi bi-eye" style="margin-right: 6px;"></i> Status</span>
                                    <strong>
                                        <?php if ($recipe['is_published']): ?>
                                            <span class="badge badge-success">Published</span>
                                        <?php else: ?>
                                            <span class="badge badge-warning">Draft</span>
                                        <?php endif; ?>
                                    </strong>
                                </li>
                                <?php if ($recipe['published_at']): ?>
                                    <li style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border-light); padding-bottom: 8px;">
                                        <span class="text-muted"><i class="bi bi-calendar-check" style="margin-right: 6px;"></i> Tanggal Rilis</span>
                                        <strong><?= date('d M Y, H:i', strtotime($recipe['published_at'])) ?></strong>
                                    </li>
                                <?php endif; ?>
                            </ul>
                        </div>
                    </div>

                    <!-- Category / Tags Card -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);">
                                <i class="bi bi-tags" style="margin-right: 6px; color: var(--primary);"></i> Kategori / Tags
                            </h3>
                        </div>
                        <div class="card-body" style="padding: 20px;">
                            <?php if (empty($recipeTags)): ?>
                                <span class="text-muted" style="font-size: 13px;">Tidak ada kategori yang dipilih.</span>
                            <?php else: ?>
                                <div style="display: flex; flex-wrap: wrap; gap: 8px;">
                                    <?php foreach ($recipeTags as $tag): ?>
                                        <span class="badge badge-success" style="font-size: 12px; padding: 6px 12px; background-color: var(--accent-light); color: var(--primary-dark); font-weight: 600; border-radius: 20px;">
                                            <i class="bi bi-tag-fill" style="margin-right: 4px;"></i> <?= htmlspecialchars(trim($tag)) ?>
                                        </span>
                                    <?php endforeach; ?>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>

                <!-- RIGHT COLUMN: Nutrisi, Bahan, Langkah, Tips (Flex: 2) -->
                <div style="flex: 2; min-width: 480px; display: flex; flex-direction: column; gap: 24px;">
                    
                    <!-- Nutritional Information Card -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);">
                                <i class="bi bi-pie-chart" style="margin-right: 6px; color: var(--primary);"></i> Informasi Nilai Gizi
                            </h3>
                        </div>
                        <div class="card-body" style="padding: 20px;">
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 16px;">
                                <div style="background: var(--background); border: 1px solid var(--border-light); padding: 16px; border-radius: var(--radius); text-align: center; border-left: 4px solid var(--warning);">
                                    <div style="font-size: 28px; color: var(--warning); margin-bottom: 6px;"><i class="bi bi-fire"></i></div>
                                    <h4 style="font-size: 20px; font-family: 'Poppins', sans-serif; font-weight: 700; color: var(--text-primary); margin-bottom: 4px;">
                                        <?= $recipe['calories'] ? number_format($recipe['calories']) : '0' ?> <span style="font-size: 12px; font-weight: 500;">kcal</span>
                                    </h4>
                                    <span class="text-muted" style="font-size: 12px;">Kalori</span>
                                </div>
                                <div style="background: var(--background); border: 1px solid var(--border-light); padding: 16px; border-radius: var(--radius); text-align: center; border-left: 4px solid var(--primary);">
                                    <div style="font-size: 28px; color: var(--primary); margin-bottom: 6px;"><i class="bi bi-egg-fried"></i></div>
                                    <h4 style="font-size: 20px; font-family: 'Poppins', sans-serif; font-weight: 700; color: var(--text-primary); margin-bottom: 4px;">
                                        <?= $recipe['protein'] ? number_format($recipe['protein']) : '0' ?> <span style="font-size: 12px; font-weight: 500;">g</span>
                                    </h4>
                                    <span class="text-muted" style="font-size: 12px;">Protein</span>
                                </div>
                                <div style="background: var(--background); border: 1px solid var(--border-light); padding: 16px; border-radius: var(--radius); text-align: center; border-left: 4px solid var(--info);">
                                    <div style="font-size: 28px; color: var(--info); margin-bottom: 6px;"><i class="bi bi-moisture"></i></div>
                                    <h4 style="font-size: 20px; font-family: 'Poppins', sans-serif; font-weight: 700; color: var(--text-primary); margin-bottom: 4px;">
                                        <?= $recipe['carbs'] ? number_format($recipe['carbs']) : '0' ?> <span style="font-size: 12px; font-weight: 500;">g</span>
                                    </h4>
                                    <span class="text-muted" style="font-size: 12px;">Karbohidrat</span>
                                </div>
                                <div style="background: var(--background); border: 1px solid var(--border-light); padding: 16px; border-radius: var(--radius); text-align: center; border-left: 4px solid var(--error);">
                                    <div style="font-size: 28px; color: var(--error); margin-bottom: 6px;"><i class="bi bi-droplet-half"></i></div>
                                    <h4 style="font-size: 20px; font-family: 'Poppins', sans-serif; font-weight: 700; color: var(--text-primary); margin-bottom: 4px;">
                                        <?= $recipe['fat'] ? number_format($recipe['fat']) : '0' ?> <span style="font-size: 12px; font-weight: 500;">g</span>
                                    </h4>
                                    <span class="text-muted" style="font-size: 12px;">Lemak</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Cooking Tips Card (Displayed only if present) -->
                    <?php if (!empty($recipe['tips'])): ?>
                        <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md); border: 1px solid var(--accent); background-color: var(--accent-lighter);">
                            <div class="card-body" style="padding: 20px; display: flex; gap: 16px; align-items: flex-start;">
                                <div style="font-size: 32px; color: var(--primary); flex-shrink: 0;"><i class="bi bi-lightbulb-fill"></i></div>
                                <div>
                                    <h4 style="font-size: 16px; font-weight: 600; color: var(--primary-dark); margin-bottom: 6px;">Tips Memasak & Saran Penyajian:</h4>
                                    <p style="font-size: 14px; line-height: 1.6; color: var(--primary-dark); margin: 0; white-space: pre-line;">
                                        <?= htmlspecialchars($recipe['tips']) ?>
                                    </p>
                                </div>
                            </div>
                        </div>
                    <?php endif; ?>

                    <!-- Ingredients Card -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);">
                                <i class="bi bi-egg" style="margin-right: 6px; color: var(--primary);"></i> Bahan-bahan
                            </h3>
                        </div>
                        <div class="card-body" style="padding: 20px;">
                            <?php if (empty($ingredients)): ?>
                                <p class="text-muted" style="font-size: 13px;">Tidak ada bahan yang dicantumkan.</p>
                            <?php else: ?>
                                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px;">
                                    <?php foreach ($ingredients as $ing): ?>
                                        <div style="display: flex; justify-content: space-between; background: var(--background); padding: 12px 16px; border-radius: var(--radius-sm); border: 1px solid var(--border-light);">
                                            <span style="font-weight: 500; font-size: 14px; color: var(--text-primary);">
                                                🍏 <?= htmlspecialchars($ing['ingredient']) ?>
                                            </span>
                                            <span class="badge badge-success" style="font-size: 12px; font-weight: 600; background-color: var(--accent-light); color: var(--primary-dark);">
                                                <?= htmlspecialchars($ing['amount'] ?? '') ?>
                                            </span>
                                        </div>
                                    <?php endforeach; ?>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>

                    <!-- Steps Card -->
                    <div class="card" style="border-radius: var(--radius-lg); box-shadow: var(--shadow-md);">
                        <div class="card-header" style="background: var(--surface); border-bottom: 1px solid var(--border-light); padding: 16px 20px;">
                            <h3 style="font-size: 15px; margin: 0; font-weight: 600; color: var(--primary-dark);">
                                <i class="bi bi-list-ol" style="margin-right: 6px; color: var(--primary);"></i> Langkah Memasak
                            </h3>
                        </div>
                        <div class="card-body" style="padding: 20px; display: flex; flex-direction: column; gap: 20px;">
                            <?php if (empty($steps)): ?>
                                <p class="text-muted" style="font-size: 13px;">Tidak ada langkah memasak yang dicantumkan.</p>
                            <?php else: ?>
                                <?php foreach ($steps as $step): ?>
                                    <div style="display: flex; gap: 16px; align-items: flex-start;">
                                        <div style="width: 32px; height: 32px; border-radius: 50%; background: var(--accent-light); color: var(--primary); display: flex; align-items: center; justify-content: center; font-weight: 700; flex-shrink: 0; font-size: 14px; font-family: 'Poppins', sans-serif;">
                                            <?= $step['step_number'] ?>
                                        </div>
                                        <div style="flex: 1; padding-top: 4px; font-size: 14.5px; line-height: 1.5; color: var(--text-primary);">
                                            <?= htmlspecialchars($step['description']) ?>
                                        </div>
                                    </div>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </div>
                    </div>

                </div>
                
            </div>
        </div>
    </main>
</div>

<?php require_once __DIR__ . '/../../includes/footer.php'; ?>

<?php
/**
 * Admin Sidebar Include
 * LovingHarmony Admin Panel
 */
?>
<aside class="sidebar" id="sidebar">
    <div class="sidebar-header">
        <div class="logo-icon">🌿</div>
        <div class="logo-text">
            <h2>LovingHarmony</h2>
            <span>Admin Panel</span>
        </div>
    </div>

    <nav class="sidebar-menu">
        <div class="menu-label">Main</div>
        <a href="<?= $baseUrl ?>index.php" class="menu-item <?= $currentPage === 'index' ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-grid-1x2-fill"></i></span>
            Dashboard
        </a>
        <a href="<?= $baseUrl ?>pages/activity-logs/index.php" class="menu-item <?= strpos($currentUri, 'activity-logs') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-graph-up-arrow"></i></span>
            Analitik Penggunaan
        </a>

        <div class="menu-label">Content</div>
        <a href="<?= $baseUrl ?>pages/news/index.php" class="menu-item <?= strpos($currentUri, 'news') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-newspaper"></i></span>
            Berita
        </a>
        <a href="<?= $baseUrl ?>pages/recipes/index.php" class="menu-item <?= strpos($currentUri, 'recipes') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-book"></i></span>
            Resep Makanan
        </a>
        <a href="<?= $baseUrl ?>pages/quotes/index.php" class="menu-item <?= strpos($currentUri, 'quotes') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-chat-quote"></i></span>
            Kata Mutiara
        </a>
        <a href="<?= $baseUrl ?>pages/quizzes/index.php" class="menu-item <?= strpos($currentUri, 'quizzes') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-question-square-fill"></i></span>
            Kuis Nutrisi
        </a>
        <a href="<?= $baseUrl ?>pages/myths/index.php" class="menu-item <?= strpos($currentUri, 'myths') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-lightbulb-fill"></i></span>
            Myth vs Fact
        </a>
        <a href="<?= $baseUrl ?>pages/quests/index.php" class="menu-item <?= strpos($currentUri, 'quests') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-compass-fill"></i></span>
            Misi Harian
        </a>

        <div class="menu-label">Management</div>
        <a href="<?= $baseUrl ?>pages/food-logs/index.php" class="menu-item <?= strpos($currentUri, 'food-logs') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-clipboard2-data-fill"></i></span>
            Food Logs
        </a>
        <a href="<?= $baseUrl ?>pages/badges/index.php" class="menu-item <?= strpos($currentUri, 'badges') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-award-fill"></i></span>
            Kelola Lencana
        </a>
        <a href="<?= $baseUrl ?>pages/users/index.php" class="menu-item <?= strpos($currentUri, 'users') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-people-fill"></i></span>
            Users
        </a>

        <div class="menu-label">System</div>
        <a href="<?= $baseUrl ?>pages/notifications/index.php" class="menu-item <?= strpos($currentUri, 'notifications') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-bell-fill"></i></span>
            Notifikasi
        </a>
        <a href="<?= $baseUrl ?>pages/settings/index.php" class="menu-item <?= (strpos($currentUri, 'settings') !== false && strpos($currentUri, 'logs.php') === false) ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-gear-fill"></i></span>
            Konfigurasi AI
        </a>
        <a href="<?= $baseUrl ?>pages/settings/logs.php" class="menu-item <?= strpos($currentUri, 'settings/logs.php') !== false ? 'active' : '' ?>">
            <span class="menu-icon"><i class="bi bi-cpu"></i></span>
            Log Aktivitas AI
        </a>
        <a href="<?= $baseUrl ?>logout.php" class="menu-item">
            <span class="menu-icon"><i class="bi bi-box-arrow-left"></i></span>
            Logout
        </a>
    </nav>
</aside>

<?php
/**
 * Admin Login Page
 * LovingHarmony Admin Panel
 */
$pageTitle = 'Login';
session_start();

// Redirect if already logged in
if (isset($_SESSION['admin_id'])) {
    header('Location: index.php');
    exit;
}

// Handle login form submission
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_once __DIR__ . '/../api/config/database.php';
    
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';

    if (empty($username) || empty($password)) {
        $error = 'Username dan password wajib diisi.';
    } else {
        try {
            $db = Database::getInstance()->getConnection();
            $stmt = $db->prepare("SELECT * FROM admins WHERE username = ?");
            $stmt->execute([$username]);
            $admin = $stmt->fetch();

            if ($admin && password_verify($password, $admin['password'])) {
                $_SESSION['admin_id'] = $admin['id'];
                $_SESSION['admin_name'] = $admin['name'];
                $_SESSION['admin_username'] = $admin['username'];
                header('Location: index.php');
                exit;
            } else {
                $error = 'Username atau password salah.';
            }
        } catch (PDOException $e) {
            $error = 'Kesalahan Database: ' . $e->getMessage();
        } catch (Exception $e) {
            $error = 'Kesalahan Sistem: ' . $e->getMessage();
        }
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login — LovingHarmony Admin</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
    <div class="login-wrapper">
        <div class="login-card">
            <div class="login-logo">
                <div class="logo-icon">🌿</div>
                <h1>LovingHarmony</h1>
                <p>Admin Panel — Masuk untuk mengelola konten</p>
            </div>

            <?php if ($error): ?>
                <div class="alert alert-error">
                    <i class="bi bi-exclamation-circle"></i>
                    <?= htmlspecialchars($error) ?>
                </div>
            <?php endif; ?>

            <form method="POST" action="">
                <div class="form-group">
                    <label for="username">Username</label>
                    <div class="input-group">
                        <span class="input-icon"><i class="bi bi-person"></i></span>
                        <input type="text" 
                               id="username" 
                               name="username" 
                               class="form-control" 
                               placeholder="Masukkan username"
                               value="<?= htmlspecialchars($_POST['username'] ?? '') ?>"
                               required 
                               autofocus>
                    </div>
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <div class="input-group">
                        <span class="input-icon"><i class="bi bi-lock"></i></span>
                        <input type="password" 
                               id="password" 
                               name="password" 
                               class="form-control" 
                               placeholder="Masukkan password"
                               required>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary btn-block btn-lg" style="margin-top: 8px;">
                    <i class="bi bi-box-arrow-in-right"></i>
                    Masuk
                </button>
            </form>

            <p class="text-center text-muted" style="margin-top: 24px; font-size: 13px;">
                &copy; <?= date('Y') ?> LovingHarmony. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>

<?php
/**
 * Admin Header Include
 * LovingHarmony Admin Panel
 */

// Start session if not started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Database connection
require_once __DIR__ . '/../../api/config/database.php';

// Check admin auth (except on login page)
$currentPage = basename($_SERVER['SCRIPT_FILENAME'], '.php');
if ($currentPage !== 'login') {
    if (!isset($_SESSION['admin_id'])) {
        header('Location: login.php');
        exit;
    }
}

// Determine Base URL for admin to fix relative paths for deep pages
$scriptName = $_SERVER['SCRIPT_NAME'];
$adminPos = strpos($scriptName, '/admin/');
if ($adminPos !== false) {
    $baseUrl = substr($scriptName, 0, $adminPos + 7);
} else {
    $baseUrl = '/admin/'; // Fallback
}

// Get current page for sidebar active state
$currentUri = $_SERVER['REQUEST_URI'];
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?? 'Admin Panel' ?> — LovingHarmony</title>
    <link rel="stylesheet" href="<?= $baseUrl ?>assets/css/style.css">
    <!-- Bootstrap Icons CDN -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>

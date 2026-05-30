<?php
/**
 * Admin Logout
 * LovingHarmony Admin Panel
 */
session_start();
session_destroy();
header('Location: login.php');
exit;

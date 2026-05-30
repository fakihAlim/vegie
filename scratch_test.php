<?php
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/Vegie/api/recipes';
$_SERVER['SCRIPT_NAME'] = '/Vegie/api/index.php';
try {
    require 'api/index.php';
} catch (Exception $e) {
    echo "Caught Exception: " . $e->getMessage() . "\n";
}

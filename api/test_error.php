<?php
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/controllers/FoodLogController.php';

// Mock authentication
function authenticate() {
    return ['user_id' => 1];
}

// Mock jsonSuccess
function jsonSuccess($data, $message = '', $code = 200) {
    echo json_encode(['success' => true, 'data' => $data]);
    exit;
}
function jsonError($message, $code) {
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
}
function getJsonBody() { return []; }
function uploadImage() { return 'test.jpg'; }
function getUploadUrl($path) { return $path; }
function analyzeNutrition($path) { return null; } // FORCE NULL

$_POST['food_name'] = 'menganalisis...';
$_POST['meal_time'] = '2023-10-10 10:00:00';
$_POST['category'] = 'breakfast';
$_FILES['photo'] = [
    'name' => 'test.jpg',
    'type' => 'image/jpeg',
    'tmp_name' => __DIR__ . '/test.jpg',
    'error' => UPLOAD_ERR_OK,
    'size' => 100
];

$c = new FoodLogController();
$c->store();

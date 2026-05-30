<?php
/**
 * File Upload Helper
 * LovingHarmony API
 */

define('UPLOAD_BASE_DIR', __DIR__ . '/../uploads/');
define('MAX_FILE_SIZE', 5 * 1024 * 1024); // 5MB
define('ALLOWED_EXTENSIONS', ['jpg', 'jpeg', 'png', 'gif', 'webp']);
define('ALLOWED_MIME_TYPES', ['image/jpeg', 'image/png', 'image/gif', 'image/webp']);

/**
 * Upload an image file
 * 
 * @param array $file - $_FILES element
 * @param string $category - Subdirectory (food_logs, news, recipes, profiles)
 * @return string|false - Relative file path on success, false on failure
 */
function uploadImage($file, $category = 'general') {
    // Validate file exists and no upload errors
    if (!isset($file['tmp_name']) || $file['error'] !== UPLOAD_ERR_OK) {
        return false;
    }

    // Validate file size
    if ($file['size'] > MAX_FILE_SIZE) {
        jsonError('File size exceeds maximum limit of 5MB', 422);
    }

    // Validate extension
    $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!in_array($extension, ALLOWED_EXTENSIONS)) {
        jsonError('Invalid file type. Allowed: ' . implode(', ', ALLOWED_EXTENSIONS), 422);
    }

    // Validate MIME type
    $mimeType = mime_content_type($file['tmp_name']);
    if (!in_array($mimeType, ALLOWED_MIME_TYPES)) {
        jsonError('Invalid file MIME type', 422);
    }

    // Create target directory if it doesn't exist
    $targetDir = UPLOAD_BASE_DIR . $category . '/';
    if (!is_dir($targetDir)) {
        mkdir($targetDir, 0777, true);
    }

    // Generate unique filename
    $filename = uniqid() . '_' . time() . '.' . $extension;
    $targetPath = $targetDir . $filename;

    // Move uploaded file
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        // No server-side compression — image is already compressed on the client (Flutter)
        
        // Return relative path for storage in database
        return 'uploads/' . $category . '/' . $filename;
    }

    return false;
}

/**
 * Delete an uploaded file
 * 
 * @param string $relativePath - Relative file path stored in DB
 * @return bool
 */
function deleteUploadedFile($relativePath) {
    if (empty($relativePath)) {
        return false;
    }

    $fullPath = __DIR__ . '/../' . $relativePath;
    if (file_exists($fullPath)) {
        return unlink($fullPath);
    }
    return false;
}

/**
 * Compress and optionally resize an image
 * 
 * @param string $sourcePath - Full path to the image file
 * @param int $quality - JPEG/WebP quality (0-100)
 * @param int $maxDimension - Maximum width or height in pixels
 * @return bool
 */
function compressImage($sourcePath, $quality = 75, $maxDimension = 1200) {
    if (!file_exists($sourcePath)) {
        return false;
    }

    $info = @getimagesize($sourcePath);
    if ($info === false) {
        return false;
    }

    $mime = $info['mime'];
    $origWidth = $info[0];
    $origHeight = $info[1];

    // Create image resource based on type
    switch ($mime) {
        case 'image/jpeg':
            $image = @imagecreatefromjpeg($sourcePath);
            break;
        case 'image/png':
            $image = @imagecreatefrompng($sourcePath);
            break;
        case 'image/webp':
            $image = @imagecreatefromwebp($sourcePath);
            break;
        case 'image/gif':
            // Don't compress GIFs (might be animated)
            return true;
        default:
            return false;
    }

    if (!$image) {
        return false;
    }

    // Resize if needed
    if ($origWidth > $maxDimension || $origHeight > $maxDimension) {
        if ($origWidth > $origHeight) {
            $newWidth = $maxDimension;
            $newHeight = (int) round($origHeight * ($maxDimension / $origWidth));
        } else {
            $newHeight = $maxDimension;
            $newWidth = (int) round($origWidth * ($maxDimension / $origHeight));
        }

        $resized = imagecreatetruecolor($newWidth, $newHeight);
        
        // Preserve transparency for PNG/WebP
        if ($mime === 'image/png' || $mime === 'image/webp') {
            imagealphablending($resized, false);
            imagesavealpha($resized, true);
        }

        imagecopyresampled($resized, $image, 0, 0, 0, 0, $newWidth, $newHeight, $origWidth, $origHeight);
        imagedestroy($image);
        $image = $resized;
    }

    // Save compressed
    switch ($mime) {
        case 'image/jpeg':
            imagejpeg($image, $sourcePath, $quality);
            break;
        case 'image/png':
            // PNG quality is 0-9 (0 = no compression, 9 = max)
            $pngQuality = (int) round((100 - $quality) / 11.11);
            imagepng($image, $sourcePath, min(9, max(0, $pngQuality)));
            break;
        case 'image/webp':
            imagewebp($image, $sourcePath, $quality);
            break;
    }

    imagedestroy($image);
    return true;
}

/**
 * Get the full URL for an uploaded file
 * 
 * @param string $relativePath - Relative file path stored in DB
 * @return string - Full URL
 */
function getUploadUrl($relativePath) {
    if (empty($relativePath)) {
        return null;
    }
    
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $basePath = rtrim(dirname(dirname($_SERVER['SCRIPT_NAME'])), '/');
    
    return $protocol . '://' . $host . $basePath . '/api/' . $relativePath;
}

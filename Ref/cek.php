<?php
/**
 * Food Nutrition Analyzer (No-DB + Auto Compress)
 * PHP 8.2 • Ollama gemma4:31b • GD Library • Tailwind CSS
 * Untuk XAMPP Localhost
 */

// =============================================================================
// 🔧 KONFIGURASI & KEAMANAN
// =============================================================================
if (file_exists(__DIR__ . '/config.php')) {
    require_once __DIR__ . '/config.php';
} else {
    die("❌ File <code>config.php</code> tidak ditemukan. Silakan buat file tersebut terlebih dahulu.");
}

$MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
$ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp'];

// Cek ekstensi GD
if (!extension_loaded('gd')) {
    die("❌ Ekstensi <code>gd</code> tidak aktif di php.ini.<br>Harap uncomment <code>extension=gd</code> dan restart Apache.");
}

// =============================================================================
// 📁 PERSIAPAN FOLDER
// =============================================================================
$uploadDir = __DIR__ . '/uploads/';
if (!is_dir($uploadDir))
    mkdir($uploadDir, 0755, true);

$result = null;
$error = null;

// =============================================================================
// 🛠️ FUNGSI KOMPRESI GAMBAR (GD LIBRARY)
// =============================================================================
function compressImageForOllama($sourcePath, $destPath, $maxSide = 1024, $quality = 85)
{
    $info = getimagesize($sourcePath);
    if (!$info)
        return false;

    [$width, $height, $type] = $info;

    // Buat resource gambar sumber
    switch ($type) {
        case IMAGETYPE_JPEG:
            $src = imagecreatefromjpeg($sourcePath);
            break;
        case IMAGETYPE_PNG:
            $src = imagecreatefrompng($sourcePath);
            break;
        case IMAGETYPE_WEBP:
            $src = imagecreatefromwebp($sourcePath);
            break;
        default:
            return false;
    }

    // Hitung rasio penskalaan
    $ratio = $maxSide / max($width, $height);
    if ($ratio >= 1) {
        $newW = $width;
        $newH = $height;
    } else {
        $newW = (int) ($width * $ratio);
        $newH = (int) ($height * $ratio);
    }

    // Buat canvas tujuan
    $dst = imagecreatetruecolor($newW, $newH);

    // Jaga transparansi (PNG/WEBP)
    if ($type === IMAGETYPE_PNG || $type === IMAGETYPE_WEBP) {
        imagealphablending($dst, false);
        imagesavealpha($dst, true);
        $trans = imagecolorallocatealpha($dst, 255, 255, 255, 127);
        imagefilledrectangle($dst, 0, 0, $newW, $newH, $trans);
    }

    // Resize halus
    imagecopyresampled($dst, $src, 0, 0, 0, 0, $newW, $newH, $width, $height);

    // Simpan sebagai JPEG (lebih kompatibel & ukuran lebih kecil untuk AI)
    $success = imagejpeg($dst, $destPath, $quality);

    imagedestroy($src);
    imagedestroy($dst);

    return $success;
}

// =============================================================================
// 🔄 PROSES FORM SUBMIT
// =============================================================================
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['image'])) {
    $startTime = microtime(true);
    $file = $_FILES['image'];

    // 1. Validasi
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $error = "Upload gagal. Kode error: " . $file['error'];
    } elseif ($file['size'] > $MAX_FILE_SIZE) {
        $error = "Ukuran file melebihi batas 5MB.";
    } elseif (!in_array(mime_content_type($file['tmp_name']), $ALLOWED_MIME)) {
        $error = "Format tidak didukung. Gunakan JPG, PNG, atau WEBP.";
    } else {
        // 2. Simpan gambar asli untuk preview
        $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $origName = 'food_' . uniqid() . '.' . $ext;
        $origPath = $uploadDir . $origName;

        if (!move_uploaded_file($file['tmp_name'], $origPath)) {
            $error = "Gagal menyimpan file.";
        } else {
            // 3. Kompresi otomatis dengan GD
            $compPath = $uploadDir . 'compressed_' . uniqid() . '.jpg';
            if (!compressImageForOllama($origPath, $compPath)) {
                $error = "Gagal mengompresi gambar. Pastikan GD Library berfungsi.";
                @unlink($origPath);
            } else {
                // 4. Base64 gambar terkompresi
                $base64 = base64_encode(file_get_contents($compPath));

                // 5. Panggil AI API (Gemini Cloud jika ada API Key, jika tidak fallback ke Ollama Lokal)
                $useGemini = defined('GEMINI_API_KEY') && !empty(GEMINI_API_KEY);
                $aiEngineName = $useGemini ? "Google Gemini API" : "Ollama (" . OLLAMA_MODEL . ")";
                
                if ($useGemini) {
                    $url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" . GEMINI_API_KEY;
                    $payload = [
                        "contents" => [
                            [
                                "parts" => [
                                    ["text" => 'You are a nutrition analysis API. Identify the food in this image. Return ONLY a valid raw JSON object with exactly these keys: "nama_makanan", "kalori", "karbohidrat", "lemak", "protein". Nutrition values for "karbohidrat", "lemak", "protein" must be numbers in grams (float). "kalori" must be a number in kcal (float). Do not include markdown, explanations, or extra text.'],
                                    ["inlineData" => ["mimeType" => "image/jpeg", "data" => $base64]]
                                ]
                            ]
                        ]
                    ];
                    
                    $ch = curl_init($url);
                    curl_setopt_array($ch, [
                        CURLOPT_RETURNTRANSFER => true,
                        CURLOPT_POST => true,
                        CURLOPT_POSTFIELDS => json_encode($payload),
                        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                        CURLOPT_TIMEOUT => 120,
                        CURLOPT_SSL_VERIFYPEER => true
                    ]);
                } else {
                    $OLLAMA_ENDPOINT = rtrim(OLLAMA_BASE_URL, '/') . '/api/generate';
                    $ch = curl_init($OLLAMA_ENDPOINT);
                    curl_setopt_array($ch, [
                        CURLOPT_RETURNTRANSFER => true,
                        CURLOPT_POST => true,
                        CURLOPT_POSTFIELDS => json_encode([
                            'model' => OLLAMA_MODEL,
                            'prompt' => 'You are a nutrition analysis API. Identify the food in this image. Return ONLY a valid raw JSON object with exactly these keys: "nama_makanan", "kalori", "karbohidrat", "lemak", "protein". Nutrition values for "karbohidrat", "lemak", "protein" must be numbers in grams (float). "kalori" must be a number in kcal (float). Do not include markdown, explanations, or extra text.',
                            'images' => [$base64],
                            'stream' => false
                        ]),
                        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                        CURLOPT_TIMEOUT => 120
                    ]);
                }

                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $curlError = curl_error($ch);
                curl_close($ch);

                // Cleanup file kompresi (tidak diperlukan lagi)
                @unlink($compPath);

                if ($curlError) {
                    $error = "Gagal menghubungi " . ($useGemini ? "Gemini" : "Ollama") . ": $curlError";
                } elseif ($httpCode !== 200) {
                    $error = ($useGemini ? "Gemini" : "Ollama") . " error HTTP $httpCode: " . substr($response, 0, 250);
                } else {
                    $data = json_decode($response, true);
                    
                    if ($useGemini) {
                        $rawText = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
                    } else {
                        $rawText = $data['response'] ?? '';
                    }

                    // Ekstrak JSON
                    $jsonStr = '';
                    if (preg_match('/```json\s*([\s\S]*?)\s*```/s', $rawText, $m))
                        $jsonStr = trim($m[1]);
                    elseif (preg_match('/\{[\s\S]*\}/s', $rawText, $m))
                        $jsonStr = trim($m[0]);
                    else
                        $jsonStr = trim($rawText);

                    $nutrition = json_decode($jsonStr, true);

                    if (is_array($nutrition) && isset($nutrition['karbohidrat'], $nutrition['lemak'], $nutrition['protein'])) {
                        $processTime = microtime(true) - $startTime;
                        $carbsVal = floatval($nutrition['karbohidrat']);
                        $fatVal = floatval($nutrition['lemak']);
                        $proteinVal = floatval($nutrition['protein']);
                        
                        $caloriesVal = isset($nutrition['kalori']) ? floatval($nutrition['kalori']) : ($carbsVal * 4 + $fatVal * 9 + $proteinVal * 4);
                        
                        $result = [
                            'name' => htmlspecialchars($nutrition['nama_makanan'] ?? 'Tidak Dikenali'),
                            'calories' => $caloriesVal,
                            'carbs' => $carbsVal,
                            'fat' => $fatVal,
                            'protein' => $proteinVal,
                            'image' => 'uploads/' . $origName,
                            'process_time' => $processTime,
                            'ai_engine' => $aiEngineName
                        ];
                    } else {
                        $error = "AI tidak mengembalikan format JSON valid.<br>Respons: " . nl2br(htmlspecialchars(substr($rawText, 0, 200)));
                    }
                }
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="id">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Food Analyzer (No-DB + GD)</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .bar-fill {
            transition: width 0.8s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .loader {
            border: 3px solid #bfdbfe;
            border-top: 3px solid #2563eb;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            animation: spin 1s linear infinite;
            display: inline-block;
        }

        @keyframes spin {
            0% {
                transform: rotate(0deg);
            }

            100% {
                transform: rotate(360deg);
            }
        }
    </style>
</head>

<body class="bg-blue-50 min-h-screen p-4 md:p-8 font-sans text-gray-800">
    <div class="max-w-3xl mx-auto space-y-6">
        <header class="text-center py-4">
            <h1 class="text-3xl font-bold text-blue-900">🍽️ Food Nutrition Analyzer</h1>
            <p class="text-blue-600 mt-2 text-sm">AI Vision • Kompresi Otomatis (GD) • Tanpa Database</p>
        </header>

        <div class="bg-white rounded-2xl shadow-lg border border-blue-200 p-6 md:p-8">
            <form method="POST" enctype="multipart/form-data" class="space-y-4" onsubmit="showLoading()">
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2">Pilih Gambar Makanan</label>
                    <input type="file" name="image" accept="image/jpeg,image/png,image/webp" required
                        class="block w-full text-sm text-gray-600 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100 border border-gray-300 rounded-lg p-2 cursor-pointer">
                </div>
                <button type="submit" id="submitBtn"
                    class="w-full bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white font-semibold py-3 px-4 rounded-xl transition shadow-md flex items-center justify-center gap-2">
                    <span>🔍 Analisis Gambar</span>
                </button>
            </form>

            <?php if ($error): ?>
                <div class="mt-4 p-4 bg-red-50 border-l-4 border-red-500 text-red-800 rounded-r-lg text-sm">⚠️
                    <?= nl2br($error) ?>
                </div>
            <?php endif; ?>

            <?php if ($result): ?>
                <div class="mt-6 p-5 bg-blue-50 rounded-xl border border-blue-200">
                    <div class="flex flex-col md:flex-row gap-5 items-start">
                        <img src="<?= htmlspecialchars($result['image']) ?>"
                            class="w-36 h-36 object-cover rounded-lg border-2 border-white shadow-sm">
                        <div class="flex-1 w-full">
                            <h2 class="text-xl font-bold text-blue-900 mb-1"><?= $result['name'] ?></h2>
                            <p class="text-xs text-gray-500 mb-4 uppercase tracking-wide">Estimasi Kandungan per Porsi &bull; Waktu Proses: <?= number_format($result['process_time'], 2) ?> detik</p>
                            
                            <div class="mb-4 p-3 bg-blue-100/50 rounded-lg flex justify-between items-center border border-blue-200">
                                <span class="font-semibold text-blue-900 text-sm">Total Energi / Kalori</span>
                                <span class="font-extrabold text-blue-700 text-lg"><?= number_format($result['calories'], 0) ?> kcal</span>
                            </div>
                            <?php
                            $maxVal = max($result['carbs'], $result['fat'], $result['protein'], 1);
                            $items = [
                                ['label' => 'Karbohidrat', 'val' => $result['carbs'], 'bg' => 'bg-amber-400', 'txt' => 'text-amber-700'],
                                ['label' => 'Lemak', 'val' => $result['fat'], 'bg' => 'bg-yellow-400', 'txt' => 'text-yellow-700'],
                                ['label' => 'Protein', 'val' => $result['protein'], 'bg' => 'bg-red-400', 'txt' => 'text-red-700']
                            ];
                            foreach ($items as $i):
                                $w = ($i['val'] / $maxVal) * 100; ?>
                                <div class="mb-3">
                                    <div class="flex justify-between text-sm mb-1">
                                        <span class="font-medium text-gray-700"><?= $i['label'] ?></span>
                                        <span class="font-bold <?= $i['txt'] ?>"><?= number_format($i['val'], 1) ?>g</span>
                                    </div>
                                    <div class="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                                        <div class="<?= $i['bg'] ?> h-2 rounded-full bar-fill"
                                            style="width: <?= number_format($w, 2) ?>%"></div>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        </div>
                    </div>
                </div>
            <?php endif; ?>
        </div>

        <div class="text-center text-xs text-blue-400 pb-4">
            XAMPP • PHP <?= phpversion() ?> • Engine: <?= isset($result['ai_engine']) ? htmlspecialchars($result['ai_engine']) : (defined('GEMINI_API_KEY') && !empty(GEMINI_API_KEY) ? 'Google Gemini API' : 'Ollama (Lokal)') ?> • GD Enabled:
            <?= extension_loaded('gd') ? '✅' : '❌' ?>
        </div>
    </div>

    <script>
        function showLoading() {
            const btn = document.getElementById('submitBtn');
            btn.disabled = true;
            btn.classList.add('opacity-75', 'cursor-not-allowed');
            btn.innerHTML = '<span class="loader"></span> Menganalisis...';
            setTimeout(() => { btn.disabled = false; btn.classList.remove('opacity-75', 'cursor-not-allowed'); btn.innerHTML = '<span>🔍 Analisis Gambar</span>'; }, 120000);
        }
    </script>
</body>

</html>
<?php
require_once __DIR__ . '/config/database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // 1. Insert News
    $newsData = [
        [
            'title' => 'Mengenal Manfaat Diet Plant-Based untuk Pemula',
            'content' => 'Pola makan berbasis tanaman (plant-based diet) semakin populer belakangan ini. Diet ini berfokus pada konsumsi makanan yang berasal dari sumber nabati sehat seperti sayuran, buah-buahan, biji-bijian, kacang-kacangan, dan polong-polongan. Berbagai studi menunjukkan bahwa diet ini dapat menurunkan risiko penyakit jantung, menurunkan tekanan darah, serta membantu dalam pengelolaan berat badan secara alami dan sehat.',
            'image' => null,
            'is_published' => 1,
            'published_at' => date('Y-m-d H:i:s', strtotime('-1 days'))
        ],
        [
            'title' => 'Mitos dan Fakta Seputar Protein pada Makanan Vegetarian',
            'content' => 'Banyak orang khawatir bahwa diet vegetarian tidak memberikan asupan protein yang cukup. Ini adalah sebuah mitos. Terdapat banyak sumber protein nabati berkualitas tinggi, seperti tempe, tahu, edamame, lentil, quinoa, dan chickpeas. Selama Anda mengonsumsi makanan yang bervariasi setiap harinya, tubuh Anda akan mendapatkan semua asam amino esensial yang dibutuhkannya tanpa perlu memakan daging.',
            'image' => null,
            'is_published' => 1,
            'published_at' => date('Y-m-d H:i:s', strtotime('-2 days'))
        ],
        [
            'title' => '5 Sayuran Hijau Lokal dengan Kandungan Gizi Tertinggi',
            'content' => 'Bayam dan kangkung adalah contoh sayuran hijau lokal yang sangat mudah ditemukan dan memiliki nutrisi luar biasa. Selain itu, daun kelor (moringa) bahkan disebut sebagai superfood karena kandungan vitamin C, kalsium, dan zat besinya yang mengalahkan banyak sayuran lain. Memasukkan sayuran lokal ini ke dalam menu harian Anda akan sangat mendukung kesehatan tubuh jangka panjang.',
            'image' => null,
            'is_published' => 1,
            'published_at' => date('Y-m-d H:i:s', strtotime('-3 days'))
        ],
        [
            'title' => 'Cara Menjaga Energi Tetap Fit dengan Pola Makan Hijau',
            'content' => 'Apakah Anda merasa cepat lelah saat beralih ke diet vegetarian? Kuncinya adalah memastikan asupan kalori dan karbohidrat kompleks Anda terpenuhi. Konsumsi oatmeal di pagi hari, makan ringan dengan buah segar, serta kacang-kacangan sangrai akan menjaga kadar gula darah stabil. Jangan lupa untuk cukup minum air karena pencernaan tinggi serat membutuhkan banyak hidrasi.',
            'image' => null,
            'is_published' => 1,
            'published_at' => date('Y-m-d H:i:s', strtotime('-4 days'))
        ],
        [
            'title' => 'Mengenal Keju Vegan: Terbuat dari Apa dan Sehatkah?',
            'content' => 'Keju vegan akhir-akhir ini menjadi solusi bagi mereka yang rindu dengan cita rasa creamy cheese namun tetap ingin menjalani hidup plant-based. Secara umum, keju vegan terbuat dari kacang mete, almond, atau kedelai yang melalui proses fermentasi. Kandungan gizinya berpusat pada lemak nabati yang baik jika dimakan dalam jumlah wajar.',
            'image' => null,
            'is_published' => 1,
            'published_at' => date('Y-m-d H:i:s', strtotime('-5 days'))
        ]
    ];

    $stmtNews = $db->prepare("INSERT INTO news (title, content, image, is_published, published_at) VALUES (?, ?, ?, ?, ?)");
    foreach ($newsData as $news) {
        $stmtNews->execute([$news['title'], $news['content'], $news['image'], $news['is_published'], $news['published_at']]);
    }

    // 2. Insert Recipes
    $recipesData = [
        [
            'raw' => [
                'title' => 'Avocado Quinoa Salad Bowl',
                'description' => 'Salad yang mengenyangkan, tinggi protein nabati, dan kaya lemak sehat dari alpukat. Sangat mantap untuk menu makan siang!',
                'photo' => null,
                'calories' => 350,
                'prep_time_minutes' => 15,
                'is_published' => 1,
                'published_at' => date('Y-m-d H:i:s')
            ],
            'ingredients' => [
                ['Quinoa (sudah dimasak)', '1 cup'],
                ['Alpukat matang', '1/2 buah, iris dadu'],
                ['Tomat Ceri', '50 gram, belah dua'],
                ['Minyak Zaitun (Olive Oil)', '1 sdm'],
                ['Perasan Jeruk Lemon', '1 sdm'],
                ['Garam dan Lada Hitam', 'secukupnya']
            ],
            'steps' => [
                'Siapkan mangkuk besar, masukkan quinoa yang sudah dimasak.',
                'Tata irisan alpukat dan tomat ceri di atas quinoa.',
                'Campurkan minyak zaitun, perasan jeruk lemon, garam, dan lada hitam di mangkuk kecil, aduk rata untuk dressing.',
                'Tuangkan dressing ke atas salad. Aduk rata sebelum dinikmati.'
            ]
        ],
        [
            'raw' => [
                'title' => 'Tofu Tumis Brokoli Garlic Sauce',
                'description' => 'Hidangan sehat ala oriental yang sangat mudah dibuat. Tofu yang renyah berpadu dengan brokoli dan saus bawang putih yang gurih.',
                'photo' => null,
                'calories' => 280,
                'prep_time_minutes' => 20,
                'is_published' => 1,
                'published_at' => date('Y-m-d H:i:s', strtotime('-1 days'))
            ],
            'ingredients' => [
                ['Tahu sutra (Tofu)', '1 blok, potong dadu'],
                ['Brokoli segar', '1 bonggol, potong kuntum'],
                ['Bawang putih', '3 siung, cincang halus'],
                ['Kecap asin cair', '2 sdm'],
                ['Minyak wijen', '1 sdt'],
                ['Larutan tepung maizena', '1 sdm dilarutkan ke air']
            ],
            'steps' => [
                'Panggang ringan atau pan-fry potongan tofu hingga berkulit kecokelatan. Sisihkan.',
                'Panaskan sedikit minyak, tumis bawang putih hingga harum.',
                'Masukkan brokoli dan sedikit air, tutup wajan selama 2 menit agar brokoli empuk.',
                'Masukkan campuran kecap asin, minyak wijen, dan larutan maizena. Aduk hingga saus mengental.',
                'Masukkan tofu kembali ke wajan, aduk merata. Angkat dan sajikan selagi hangat.'
            ]
        ],
        [
            'raw' => [
                'title' => 'Burger Tempe Panggang BBQ',
                'description' => 'Siapa bilang vegan tidak bisa makan burger yang mantap? Tempe menjadi patty yang padat dengan rasa medok berkat saus BBQ alami!',
                'photo' => null,
                'calories' => 400,
                'prep_time_minutes' => 30,
                'is_published' => 1,
                'published_at' => date('Y-m-d H:i:s', strtotime('-2 days'))
            ],
            'ingredients' => [
                ['Roti Burger Vegan (tanpa telur/susu)', '2 buah'],
                ['Tempe', '200 gram, lumatkan kasar'],
                ['Bawang bombay', '1/4 buah, cincang halus'],
                ['Saus BBQ botolan (vegan-friendly)', '3 sdm'],
                ['Tepung gandum/oat', '2 sdm (pengikat)'],
                ['Daun selada dan tomat', 'Secukupnya untuk isian']
            ],
            'steps' => [
                'Campur tempe yang sudah dilumatkan dengan bawang bombay, 1 sdm saus BBQ, dan tepung oat. Aduk dan remas hingga bisa dibentuk.',
                'Bentuk adonan tempe menjadi 2 patty bulat dan pipih.',
                'Olesi teflon dengan sedikit minyak, panggang patty dengan api sedang hingga kecokelatan di kedua sisinya.',
                'Oleskan sisa saus BBQ ke seluruh permukaan patty saat dipanggang untuk efek karamelisasi.',
                'Susun burger dengan roti, patty tempe, daun selada, dan potongan tomat segar. Siap disajikan.'
            ]
        ],
        [
            'raw' => [
                'title' => 'Smoothies Berry & Bayam Detoks',
                'description' => 'Minuman pagi yang menyegarkan tubuh sekaligus memberi suplai vitamin harian Anda dalam satu tegukan.',
                'photo' => null,
                'calories' => 120,
                'prep_time_minutes' => 5,
                'is_published' => 1,
                'published_at' => date('Y-m-d H:i:s', strtotime('-3 days'))
            ],
            'ingredients' => [
                ['Bayam hijau segar (cuci bersih)', '1 mangkuk / genggam penuh'],
                ['Buah Berries (Strawberry/Blueberry, bekukan)', '1/2 cup'],
                ['Pisang beku', '1 buah'],
                ['Susu almond / susu kedelai', '200 ml'],
                ['Biji chia (opsional)', '1 sdt']
            ],
            'steps' => [
                'Masukkan semua bahan ke dalam blender kecepatan tinggi.',
                'Nyalakan blender, tunggu hingga seluruh bahan hancur dan mencapai tekstur yang halus.',
                'Bila terlalu kental, tambahkan sedikit air atau susu almond. Bila ingin lebih dingin, tambahkan es batu.',
                'Tuang ke dalam gelas saji, taburi biji chia di atasnya. Minum selagi dingin.'
            ]
        ],
        [
            'raw' => [
                'title' => 'Sup Krim Jamur Vegan',
                'description' => 'Sup hangat nan gurih alami dari jamur, dipadukan tekstur creamy susu oat atau kacang mede.',
                'photo' => null,
                'calories' => 210,
                'prep_time_minutes' => 25,
                'is_published' => 1,
                'published_at' => date('Y-m-d H:i:s', strtotime('-4 days'))
            ],
            'ingredients' => [
                ['Jamur champignon atau kancing', '200 gram, iris tipis'],
                ['Bawang bombay', '1/2 buah, cincang halus'],
                ['Kaldu sayur cair', '200 ml'],
                ['Susu kedelai tawar / Susu oat', '150 ml'],
                ['Tepung maizena', '1 sdm'],
                ['Oregano kering & lada putih', '1 sdt']
            ],
            'steps' => [
                'Tumis jamur di teflon kering hingga mengeluarkan air dan menyusut.',
                'Tambahkan sedikit minyak, lalu masukkan bawang bombay, tumis hingga wangi.',
                'Tuangkan kaldu sayur perlahan, biarkan mendidih perlahan selama 5 menit agar kaldu jamur menyatu.',
                'Campurkan susu kedelai dengan tepung maizena, tuang ke dalam panci sup.',
                'Aduk rata selama 3 menit hingga sup mengental. Tambahkan oregano, lada, dan sedikit garam.',
                'Sajikan hangat bersama roti panggang.'
            ]
        ]
    ];

    $stmtRecipe = $db->prepare("INSERT INTO recipes (title, description, photo, calories, prep_time_minutes, is_published, published_at) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmtIng = $db->prepare("INSERT INTO recipe_ingredients (recipe_id, ingredient, amount, sort_order) VALUES (?, ?, ?, ?)");
    $stmtStep = $db->prepare("INSERT INTO recipe_steps (recipe_id, step_number, description) VALUES (?, ?, ?)");

    foreach ($recipesData as $rec) {
        $raw = $rec['raw'];
        $stmtRecipe->execute([
            $raw['title'], 
            $raw['description'], 
            $raw['photo'], 
            $raw['calories'], 
            $raw['prep_time_minutes'], 
            $raw['is_published'], 
            $raw['published_at']
        ]);
        
        $recipeId = $db->lastInsertId();

        // Ingredients
        $sortOrder = 1;
        foreach ($rec['ingredients'] as $ing) {
            $stmtIng->execute([$recipeId, $ing[0], $ing[1], $sortOrder]);
            $sortOrder++;
        }

        // Steps
        $stepNumber = 1;
        foreach ($rec['steps'] as $desc) {
            $stmtStep->execute([$recipeId, $stepNumber, $desc]);
            $stepNumber++;
        }
    }

    echo "Seeder successfully ran! 5 News and 5 Recipes added.";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}

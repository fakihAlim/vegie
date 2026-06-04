import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'id'; // Default to Indonesian

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'id';
    notifyListeners();
  }

  Future<void> changeLanguage(String langCode) async {
    if (langCode == _currentLanguage) return;
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    notifyListeners();
  }

  /// Helper translation function
  String translate(String key) {
    if (_currentLanguage == 'en') {
      return _translationsEn[key] ?? _translationsId[key] ?? key;
    }
    return _translationsId[key] ?? key;
  }

  static const Map<String, String> _translationsId = {
    // Bottom Bar Labels
    'nav_dashboard': 'Dashboard',
    'nav_insights': 'Insights',
    'nav_log': 'Log',
    'nav_discover': 'Discover',
    'nav_profile': 'Profil',

    // Dashboard (FoodLogScreen)
    'hello': 'Hello',
    'your_food_logs': 'Jurnal Makanan Anda',
    'today_nutrition': 'Total Nutrisi Hari Ini',
    'today_inspiration': 'Inspirasi Hari Ini',
    'food_logs_for': 'Jurnal Makanan untuk',
    'no_food_logs': 'Tidak ada jurnal makanan pada tanggal ini',
    'tap_camera': 'Ketuk tombol kamera untuk menambahkan makanan!',
    'calories': 'Kalori',
    'carbs': 'Karbo',
    'fat': 'Lemak',
    'protein': 'Protein',
    'estimate_serving': 'ESTIMASI PER PORSI',
    'ingredient_composition': 'KOMPOSISI BAHAN',
    'total_nutrition_label': 'Total Nutrisi',
    'total_energy_label': 'Total Energi',
    'analyzing_nutrition': 'Sedang Menganalisis Nutrisi...',
    'click_edit_manual': 'Klik untuk edit manual atau melihat hasil',
    'syncing_data': 'Menyinkronkan data...',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',

    // Insights Screen
    'insights_title': 'Insights',
    'myth_vs_fact': 'Myth vs Fact',
    'latest_news': 'Berita Terkini',
    'featured_recipes': 'Resep Pilihan',
    'no_new_myth': 'Belum ada myth vs fact yang baru. Tunggu notifikasi atau cek aplikasi secara berkala',
    'no_myth_data': 'Belum ada data Myth vs Fact',
    'no_news_data': 'Belum ada berita',
    'no_recipes_data': 'Belum ada resep',
    'medium': 'Sedang',
    'easy': 'Mudah',
    'hard': 'Sulit',
    'minutes': 'mnt',
    'seconds': 'detik',
    'hours': 'jam',

    // Discover Screen
    'daily_quests': 'Misi Harian',
    'todays_quiz': 'Kuis Hari Ini',
    'community_groups': 'Komunitas & Grup',
    'no_quests_today': 'Belum ada misi hari ini.',
    'new_quiz': 'KUIS BARU',
    'test_knowledge': 'Uji Pengetahuanmu!',
    'start_quiz': 'Mulai Kuis',
    'network_together': 'Berjejaring Bersama',
    'network_desc': 'Temukan dukungan dan inspirasi dari komunitas Vegan.',
    'open_community': 'Buka Halaman Komunitas',
    'community_locked': 'Komunitas Terkunci Sementara',
    'community_locked_desc': 'Catat 1 porsi buah atau sayur di Food Log untuk mencairkan streak dan membuka kembali fitur ini!',
    'answered_all_quizzes': 'Kamu sudah menjawab semua kuis hari ini! 🎉',

    // Profile Screen
    'profile_title': 'Profil & Pencapaian',
    'physical_info_incomplete': 'Informasi Fisik Belum Lengkap',
    'physical_info_desc': 'Silakan lengkapi data berat badan, tinggi badan, usia, dan gender Anda di pengaturan untuk menghitung BMI dan saran gizi harian.',
    'complete_profile': 'Lengkapi Profil',
    'health_nutrition_analysis': 'Analisis Kesehatan & Nutrisi',
    'total_points': 'Total Poin',
    'accumulated_points': 'Poin terakumulasi',
    'streak_days': 'Hari Streak',
    'consecutive_logging': 'Pencatatan berturut',
    'ecological_impact': 'Dampak Ekologis Anda',
    'saved_carbon_msg': 'Anda telah menghemat',
    'saved_carbon_desc': 'Pola makan vegetarian Anda secara nyata mengurangi pemanasan global.',
    'gasoline_saved': 'Setara menghemat',
    'gasoline_unit': 'Liter Bensin',
    'tree_saved': 'Setara kemampuan',
    'tree_unit': 'Pohon menyerap karbon dalam setahun',
    'badge_showcase': 'Etalase Lencana',
    'unlocked': 'terbuka',
    'badge_showcase_empty': 'Catat makanan & jawab kuis\nuntuk mendapatkan lencana pertamamu!',
    'badge_locked': 'Lencana Terkunci 🔒',
    'your_progress': 'Kemajuan Anda',
    'close': 'Tutup',
    'logout': 'Keluar Akun',

    // Settings
    'settings_title': 'Pengaturan',
    'reminder_title': 'Pengingat Harian',
    'reminder_desc': 'Bantu bangun kebiasaan mencatat food log agar diet plant-based kamu tetap terpantau.',
    'enable_reminder': 'Aktifkan Pengingat',
    'reminder_active_at': 'Pengingat aktif setiap hari pada jam',
    'reminder_disabled': 'Pengingat saat ini dinonaktifkan',
    'reminder_time_label': 'Jam Pengingat',
    'reminder_time_desc': 'Pilih jam terbaik untuk menerima notifikasi',
    'diet_exceptions': 'Pengecualian Diet',
    'diet_exceptions_desc': 'Sesuaikan penilaian food log berdasarkan aturan khusus diet plant-based Anda.',
    'allow_eggs': 'Bolehkan Telur',
    'allow_eggs_desc': 'Telur dan olahannya tidak dideteksi sebagai hewani.',
    'allow_milk': 'Bolehkan Susu & Produk Susu',
    'allow_milk_desc': 'Susu, keju, mentega tidak dideteksi sebagai hewani.',
    'allow_honey': 'Bolehkan Madu',
    'allow_honey_desc': 'Madu tidak dideteksi sebagai hewani.',
    'restrict_alliums': 'Batasi Bawang & Turunannya',
    'restrict_alliums_desc': 'Deteksi bawang, bawang putih, daun bawang sebagai non-nabati.',
    'language_settings': 'Bahasa / Language',
    'select_language': 'Pilih Bahasa Aplikasi',
    'indonesian': 'Bahasa Indonesia',
    'english': 'English',
    'reminder_scheduled': 'Pengingat harian dijadwalkan pada',
    'reminder_enabled_snack': 'Pengingat harian diaktifkan! ⏰',
    'reminder_disabled_snack': 'Pengingat harian dinonaktifkan',
  };

  static const Map<String, String> _translationsEn = {
    // Bottom Bar Labels
    'nav_dashboard': 'Dashboard',
    'nav_insights': 'Insights',
    'nav_log': 'Log',
    'nav_discover': 'Discover',
    'nav_profile': 'Profile',

    // Dashboard (FoodLogScreen)
    'hello': 'Hello',
    'your_food_logs': 'Your Food Logs',
    'today_nutrition': 'Today\'s Total Nutrition',
    'today_inspiration': 'Today\'s Inspiration',
    'food_logs_for': 'Food Logs for',
    'no_food_logs': 'No food logs on this date',
    'tap_camera': 'Tap the camera button to add a meal!',
    'calories': 'Calories',
    'carbs': 'Carbs',
    'fat': 'Fat',
    'protein': 'Protein',
    'estimate_serving': 'ESTIMATE PER SERVING',
    'ingredient_composition': 'INGREDIENT COMPOSITION',
    'total_nutrition_label': 'Total Nutrition',
    'total_energy_label': 'Total Energy',
    'analyzing_nutrition': 'Analyzing Nutrition...',
    'click_edit_manual': 'Click to edit manually or view results',
    'syncing_data': 'Syncing data...',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',

    // Insights Screen
    'insights_title': 'Insights',
    'myth_vs_fact': 'Myth vs Fact',
    'latest_news': 'Latest News',
    'featured_recipes': 'Featured Recipes',
    'no_new_myth': 'No new myths or facts. Check back later or wait for notifications.',
    'no_myth_data': 'No Myth vs Fact data available',
    'no_news_data': 'No news available',
    'no_recipes_data': 'No recipes available',
    'medium': 'Medium',
    'easy': 'Easy',
    'hard': 'Hard',
    'minutes': 'mins',
    'seconds': 'seconds',
    'hours': 'hours',

    // Discover Screen
    'daily_quests': 'Daily Quests',
    'todays_quiz': 'Today\'s Quiz',
    'community_groups': 'Community & Groups',
    'no_quests_today': 'No quests for today.',
    'new_quiz': 'NEW QUIZ',
    'test_knowledge': 'Test Your Knowledge!',
    'start_quiz': 'Start Quiz',
    'network_together': 'Network Together',
    'network_desc': 'Find support and inspiration from the Vegan community.',
    'open_community': 'Open Community Page',
    'community_locked': 'Community Temporarily Locked',
    'community_locked_desc': 'Log 1 serving of fruit or vegetable in Food Log to break the streak and unlock this feature!',
    'answered_all_quizzes': 'You have answered all quizzes for today! 🎉',

    // Profile Screen
    'profile_title': 'Profile & Achievements',
    'physical_info_incomplete': 'Physical Info Incomplete',
    'physical_info_desc': 'Please complete your weight, height, age, and gender details in settings to calculate BMI and daily nutritional suggestions.',
    'complete_profile': 'Complete Profile',
    'health_nutrition_analysis': 'Health & Nutrition Analysis',
    'total_points': 'Total Points',
    'accumulated_points': 'Accumulated points',
    'streak_days': 'Streak Days',
    'consecutive_logging': 'Consecutive logging',
    'ecological_impact': 'Your Ecological Impact',
    'saved_carbon_msg': 'You have saved',
    'saved_carbon_desc': 'Your vegetarian diet significantly reduces global warming.',
    'gasoline_saved': 'Equivalent to saving',
    'gasoline_unit': 'Liters of Gasoline',
    'tree_saved': 'Equivalent to',
    'tree_unit': 'Trees absorbing carbon in a year',
    'badge_showcase': 'Badge Showcase',
    'unlocked': 'unlocked',
    'badge_showcase_empty': 'Log food & answer quizzes\nto get your first badge!',
    'badge_locked': 'Badge Locked 🔒',
    'your_progress': 'Your Progress',
    'close': 'Close',
    'logout': 'Logout',

    // Settings
    'settings_title': 'Settings',
    'reminder_title': 'Daily Reminder',
    'reminder_desc': 'Help build a habit of logging your food so your plant-based diet stays monitored.',
    'enable_reminder': 'Enable Reminder',
    'reminder_active_at': 'Reminder active every day at',
    'reminder_disabled': 'Reminder is currently disabled',
    'reminder_time_label': 'Reminder Time',
    'reminder_time_desc': 'Choose the best time to receive notifications',
    'diet_exceptions': 'Diet Exceptions',
    'diet_exceptions_desc': 'Adjust food log evaluation based on your specific plant-based diet rules.',
    'allow_eggs': 'Allow Eggs',
    'allow_eggs_desc': 'Eggs and egg products are not detected as animal-based.',
    'allow_milk': 'Allow Milk & Dairy Products',
    'allow_milk_desc': 'Milk, cheese, butter are not detected as animal-based.',
    'allow_honey': 'Allow Honey',
    'allow_honey_desc': 'Honey is not detected as animal-based.',
    'restrict_alliums': 'Restrict Alliums & Onion Derivatives',
    'restrict_alliums_desc': 'Flag onions, garlic, and leeks as non-plant-based.',
    'language_settings': 'Language / Bahasa',
    'select_language': 'Select App Language',
    'indonesian': 'Bahasa Indonesia',
    'english': 'English',
    'reminder_scheduled': 'Daily reminder scheduled at',
    'reminder_enabled_snack': 'Daily reminder enabled! ⏰',
    'reminder_disabled_snack': 'Daily reminder disabled',
  };
}

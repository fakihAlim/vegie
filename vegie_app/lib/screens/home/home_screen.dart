import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/activity_log_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_log_provider.dart';
import '../food_log/food_log_screen.dart';
import '../news/news_screen.dart';
import '../recipes/recipes_screen.dart';
import '../groups/group_list_screen.dart';
import '../auth/profile_screen.dart';
import '../food_log/add_food_log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _logTabChange(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodLogProvider>(context, listen: false).fetchDashboardData();
    });
  }

  void _logTabChange(int index) {
    String screenName = '';
    switch (index) {
      case 0:
        screenName = 'HomeScreenDashboard';
        break;
      case 1:
        screenName = 'NewsScreen';
        break;
      case 2:
        screenName = 'RecipesScreen';
        break;
      case 3:
        screenName = 'GroupListScreen';
        break;
      case 4:
        screenName = 'ProfileScreen';
        break;
    }
    if (screenName.isNotEmpty) {
      ActivityLogService.instance.logEvent('screen_view', screen: screenName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final ttmStage = user?.ttmStage.toLowerCase() ?? 'precontemplation';
    final isLocked = user?.isFeatureLocked ?? false;

    return Scaffold(
      body: _currentIndex == 0
          ? _buildHomeDashboard(ttmStage, isLocked)
          : IndexedStack(
              index: _currentIndex,
              children: [
                const SizedBox.shrink(), // Placeholder for home
                const NewsScreen(),
                const RecipesScreen(),
                const GroupListScreen(),
                const ProfileScreen(),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _logTabChange(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Recipes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboard(String stage, bool isLocked) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user?.name.split(' ')[0] ?? 'Sobat Sehat'}! 👋',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
                Text(
                  'Level: ${_formatStageName(stage)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLocked ? Colors.cyan.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLocked ? Colors.cyan.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isLocked ? Icons.ac_unit : Icons.local_fire_department,
                  color: isLocked ? Colors.cyan : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Consumer<FoodLogProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      '${provider.streak} Hari',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLocked ? Colors.cyan[700] : Colors.orange[800],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGamificationModule(stage, isLocked),
            const SizedBox(height: 24),
            
            // Standard Bottom Section: Active food log screen button
            if (stage == 'action' || stage == 'maintenance' || stage == 'preparation') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Makan Anda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FoodLogScreen()),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Lihat Semua'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              _buildMiniFoodLogList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFoodLogList() {
    return Consumer<FoodLogProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.logs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'Belum ada riwayat makan tercatat untuk hari ini.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        
        final displayLogs = provider.logs.take(3).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayLogs.length,
          itemBuilder: (context, index) {
            final log = displayLogs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: AppTheme.primary),
                ),
                title: Text(log.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(log.category.toUpperCase(), style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  log.calories != null ? '${log.calories!.toStringAsFixed(0)} kcal' : '-- kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGamificationModule(String stage, bool isLocked) {
    switch (stage) {
      case 'precontemplation':
        return _buildPrecontemplationModule();
      case 'contemplation':
        return _buildContemplationModule();
      case 'preparation':
        return _buildPreparationModule();
      case 'action':
        return _buildActionModule(isLocked);
      case 'maintenance':
        return _buildMaintenanceModule();
      default:
        return _buildPrecontemplationModule();
    }
  }

  // --- STAGE 1: PRECONTEMPLATION (Mitos/Fakta, Invisibility Approach) ---
  Widget _buildPrecontemplationModule() {
    final myths = [
      {
        'myth': 'Vegetarian pasti kekurangan protein untuk beraktivitas berat.',
        'fact': 'Banyak atlet profesional beralih ke pola makan nabati! Tempe, kacang merah, chia seeds, dan bayam kaya akan asam amino lengkap.'
      },
      {
        'myth': 'Makan sayur saja terasa hambar dan membosankan.',
        'fact': 'Rempah tradisional melimpah di nusantara membuat kuliner nabati seperti gado-gado dan sate jamur sangat lezat dan memanjakan lidah!'
      },
      {
        'myth': 'Bahan makanan nabati sehat itu mahal dan sulit dicari.',
        'fact': 'Sayur lokal segar, tahu, dan tempe adalah protein terbaik dan paling terjangkau yang bisa dibeli dengan mudah di pasar tradisional.'
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.indigo, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.deepPurple.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💡 Pojok Edukasi: Mitos vs Fakta',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Buka wawasan Anda tentang gaya hidup vegetarian dengan fakta ilmiah menarik berikut ini.',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...myths.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('MITOS', style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item['myth']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🌱 ', style: const TextStyle(fontSize: 16)),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                          children: [
                            TextSpan(text: 'FAKTA: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                            TextSpan(text: item['fact']!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // --- STAGE 2: CONTEMPLATION (Kalkulator Karbon & Resep Favorit) ---
  Widget _buildContemplationModule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kalkulator Karbon Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Kalkulator Karbon Hijau',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Tahukah Anda? Dengan hanya melewatkan 1 porsi daging merah seminggu, Anda dapat menghemat:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCarbonStat('15.4 kg', 'Gas Emisi CO₂', Icons.cloud_outlined),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildCarbonStat('1,200 L', 'Air Bersih', Icons.water_drop_outlined),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Inspirasi Menu Nabati Favorit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildContemplationRecipeCard('Salad Tempe Madu', 'Serat & Protein tinggi', '5 Star'),
              _buildContemplationRecipeCard('Steak Jamur Portobello', 'Rasa gurih alami daging', '4.9 Star'),
              _buildContemplationRecipeCard('Smoothie Mangga Bayam', 'Segar kaya vitamin & zat besi', '4.8 Star'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarbonStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.lightGreenAccent, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildContemplationRecipeCard(String title, String subtitle, String rating) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Simpan ke Favorit', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // --- STAGE 3: PREPARATION (Checklist & Small Camera AI Button) ---
  Widget _buildPreparationModule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📋 Checklist Persiapan Nabati',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6)),
                child: Text('TAHAP PERSIAPAN', style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildChecklistItem('Siapkan stok buah, tempe, dan tahu di lemari es', true),
          _buildChecklistItem('Cari 3 resep nabati sederhana untuk minggu ini', false),
          _buildChecklistItem('Pahami 4 pilar gizi nabati seimbang', false),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            'Ingin mencoba kehebatan kecerdasan buatan?',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFoodLogScreen()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.photo_camera_outlined, color: AppTheme.primary, size: 20),
              label: const Text(
                'Uji Coba Kamera AI (Beta)',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: checked ? AppTheme.primary : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: checked ? Colors.grey : Colors.black87,
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STAGE 4: ACTION (Big Camera AI, Streaks, Leaderboards, Recovery Mission) ---
  Widget _buildActionModule(bool isLocked) {
    if (isLocked) {
      // RECOVERY STATE (GAMIFIED LOCK)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sapaan Empatik
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.cyan[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.cyan.shade100),
            ),
            child: Row(
              children: [
                const Text('🌱 ', style: TextStyle(fontSize: 20)),
                Expanded(
                  child: Text(
                    'Selamat datang kembali! Mari susun ulang menu ringan hari ini.',
                    style: TextStyle(color: Colors.cyan[900], fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Recovery Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan.shade900, Colors.teal.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.ac_unit, color: Colors.cyanAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '❄️ Misi Pemulihan (Recovery)',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Api streak Anda sedang dibekukan! Catat 1 buah pisang atau apel hari ini menggunakan kamera AI untuk mencairkan streak-mu!',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddFoodLogScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent[400],
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_camera, size: 20),
                    label: const Text('Ambil Foto Buah Anda!', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Locked Leaderboard
          const Text('Leaderboard Komunitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.35,
                child: AbsorbPointer(
                  child: _buildLeaderboardWidget(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Leaderboard Terkunci! Selesaikan Misi Pemulihan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // NORMAL ACTIVE STATE
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Huge Floating Camera AI Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.shade100, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.green.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Detektor Nutrisi Instan Anda ⚡',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cukup arahkan kamera pada makanan nabati Anda.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddFoodLogScreen()),
                    );
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.green[500]!, Colors.teal[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.center_focus_strong_rounded, size: 54, color: Colors.white),
                        SizedBox(height: 6),
                        Text(
                          'Kamera AI',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Leaderboard
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('🏆 Klasemen Mingguan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
              Text('Lihat Semua', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          _buildLeaderboardWidget(),
        ],
      );
    }
  }

  Widget _buildLeaderboardWidget() {
    final leaderboards = [
      {'rank': '1', 'name': 'Yodi Setiawan', 'xp': '1500 XP', 'medal': '🥇'},
      {'rank': '2', 'name': 'Alim Prakasa', 'xp': '1250 XP', 'medal': '🥈'},
      {'rank': '3', 'name': 'Anda', 'xp': '980 XP', 'medal': '🥉'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: leaderboards.map((user) {
          final isMe = user['name'] == 'Anda';
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: user['rank'] != '3' ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
            ),
            child: Row(
              children: [
                Text(user['medal']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(user['rank']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 12),
                Text(
                  user['name']!,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    color: isMe ? AppTheme.primary : Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(user['xp']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- STAGE 5: MAINTENANCE (Gelar Mentor & Komunitas Q&A) ---
  Widget _buildMaintenanceModule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gelar Mentor Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF1C40F), Color(0xFFD4AC0D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: const Color(0xFFF1C40F).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'GELAR KEHORMATAN',
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '🌱 Mentor Nabati Senior',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Anda telah menjaga kebiasaan makan sehat ini lebih dari 6 bulan!',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Komunitas Q&A
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('💬 Tanya Jawab Mentor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
            Text('Pertanyaan Baru', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        _buildQAItem(
          question: 'Bagaimana cara memenuhi zat besi seimbang untuk pemula nabati?',
          replies: '3 jawaban dibutuhkan',
        ),
        const SizedBox(height: 10),
        _buildQAItem(
          question: 'Apakah tempe goreng kehilangan kandungan nutrisinya secara drastis?',
          replies: '1 jawaban dibutuhkan',
        ),
      ],
    );
  }

  Widget _buildQAItem({required String question, required String replies}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(replies, style: TextStyle(color: Colors.orange[800], fontSize: 11, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Bantu Jawab', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatStageName(String stage) {
    switch (stage.toLowerCase()) {
      case 'precontemplation': return 'Pre-Kontemplasi (Eksplorasi)';
      case 'contemplation': return 'Kontemplasi (Perencanaan)';
      case 'preparation': return 'Persiapan (Awal)';
      case 'action': return 'Aksi (Berjalan)';
      case 'maintenance': return 'Pemeliharaan (Mentor)';
      default: return 'Pre-Kontemplasi';
    }
  }
}



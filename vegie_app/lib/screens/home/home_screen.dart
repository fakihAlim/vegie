import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/activity_log_service.dart';
import '../../providers/auth_provider.dart';

// Import Screen Tabs
import '../food_log/food_log_screen.dart';
import '../news/news_screen.dart';
import '../recipes/recipes_screen.dart';
import '../groups/group_list_screen.dart';
import '../auth/profile_screen.dart';

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
  }

  void _logTabChange(int index) {
    String screenName = '';
    switch (index) {
      case 0:
        screenName = 'FoodLogScreen';
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

  // Fungsi untuk menampilkan tab Komunitas (Groups)
  // Di sinilah logika "Feature Locking" dan pesan Empatik bekerja!
  Widget _buildGroupTab(bool isLocked) {
    if (isLocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.ac_unit, size: 80, color: Colors.blueGrey), // Ikon beku
              const SizedBox(height: 24),
              Text(
                "Selamat datang kembali!",
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Rencana beberapa hari lalu mungkin terlalu padat.\nStreak Anda sedang dibekukan sementara untuk melindunginya.\n\nMari susun ulang menu hari ini. Catat 1 porsi buah atau sayur di Food Log untuk mencairkan streak dan membuka kembali fitur Komunitas ini!",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Arahkan user kembali ke tab Food Log
                  setState(() => _currentIndex = 0);
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text("Catat Makanan Sekarang"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ],
          ),
        ),
      );
    }

    // Jika tidak terkunci, tampilkan halaman Groups/Komunitas normal
    return const GroupListScreen();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ambil data user dari Provider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // 2. Baca status (Jika model user belum punya field ini, default ke false)
    // Pastikan di file models/user.dart sudah ada penanganan nilai default untuk ttmStage dan isFeatureLocked
    // final String currentStage = user?.ttmStage ?? 'precontemplation';
    // Anggap isLocked dibaca dari API (ubah ke user?.isFeatureLocked jika model sudah siap)
    final bool isLocked = user?.isFeatureLocked ?? false;

    // 3. Susun ulang _screens dengan menyisipkan logika adaptif
    final List<Widget> screens = [
      const FoodLogScreen(),  // Tab 0: Selalu tampil agar user bisa lepas dari status 'locked'
      const NewsScreen(),     // Tab 1
      const RecipesScreen(),  // Tab 2
      _buildGroupTab(isLocked), // Tab 3: Terapkan Feature Locking di sini
      const ProfileScreen(),  // Tab 4
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Food Log',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'News',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Recipes',
            ),
            // Berikan tanda visual (gembok) di ikon tab jika sedang terkunci
            BottomNavigationBarItem(
              icon: isLocked ? const Icon(Icons.lock_outline, color: Colors.redAccent) : const Icon(Icons.people_outline),
              activeIcon: isLocked ? const Icon(Icons.lock, color: Colors.redAccent) : const Icon(Icons.people),
              label: 'Groups',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
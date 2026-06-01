import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/activity_log_service.dart';
import '../../providers/auth_provider.dart';

// Import Screen Tabs
import '../food_log/food_log_screen.dart';
import '../insights/insights_screen.dart';
import '../discover/discover_screen.dart';
import '../auth/profile_screen.dart';
import '../food_log/add_food_log_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _logTabChange(_currentIndex);
  }

  void _logTabChange(int index) {
    String screenName = '';
    switch (index) {
      case 0:
        screenName = 'DashboardScreen';
        break;
      case 1:
        screenName = 'InsightsScreen';
        break;
      case 2:
        screenName = 'DiscoverScreen';
        break;
      case 3:
        screenName = 'ProfileScreen';
        break;
    }
    if (screenName.isNotEmpty) {
      ActivityLogService.instance.logEvent('screen_view', screen: screenName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ambil data user dari Provider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // Feature Locking Check (diaplikasikan di tab Discover sekarang)
    final bool isLocked = user?.isFeatureLocked ?? false;

    // 3. Susun ulang screens
    final List<Widget> screens = [
      const FoodLogScreen(),  // Tab 0: Dashboard (Sebelumnya FoodLogScreen)
      const InsightsScreen(), // Tab 1: Insights (Myth, News, Recipes)
      const DiscoverScreen(), // Tab 2: Discover (Misi, Kuis, Groups) - Nanti bisa ditambahkan buildGroupTab
      const ProfileScreen(),  // Tab 3: Profile
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.surface,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
              ),
              _buildTabItem(
                index: 1,
                icon: Icons.lightbulb_outline,
                activeIcon: Icons.lightbulb,
                label: 'Insights',
              ),
              _buildCameraTabItem(),
              _buildTabItem(
                index: 2,
                icon: isLocked ? Icons.lock_outline : Icons.explore_outlined,
                activeIcon: isLocked ? Icons.lock : Icons.explore,
                label: 'Discover',
                iconColor: isLocked ? Colors.redAccent : null,
              ),
              _buildTabItem(
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraTabItem() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddFoodLogScreen()),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.camera_alt_outlined,
            color: AppTheme.textSecondary,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            'Log',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    Color? iconColor,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primary : AppTheme.textSecondary;

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
        _logTabChange(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: iconColor ?? color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/activity_log_service.dart';
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

  final List<Widget> _screens = [
    const FoodLogScreen(),
    const NewsScreen(),
    const RecipesScreen(),
    const GroupListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Log the initial screen view when HomeScreen opens
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
              icon: Icon(Icons.restaurant_menu),
              label: 'Food Log',
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
}


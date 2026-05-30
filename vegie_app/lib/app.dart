import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/food_log_provider.dart';
import 'providers/news_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/group_provider.dart';
import 'services/activity_log_service.dart';
import 'screens/splash_screen.dart';

class LovingHarmonyApp extends StatefulWidget {
  const LovingHarmonyApp({Key? key}) : super(key: key);

  @override
  State<LovingHarmonyApp> createState() => _LovingHarmonyAppState();
}

class _LovingHarmonyAppState extends State<LovingHarmonyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ActivityLogService.instance.logAppClose();
    } else if (state == AppLifecycleState.resumed) {
      ActivityLogService.instance.initializeSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FoodLogProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: MaterialApp(
        title: 'LovingHarmony',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

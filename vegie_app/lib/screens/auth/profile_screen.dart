import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/streak_service.dart';
import '../../models/user.dart';
import '../../models/badge_model.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import '../../providers/recipe_provider.dart';
import '../recipes/recipe_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Reset RecipeProvider in-memory state so the new user doesn't see old saved recipes
    Provider.of<RecipeProvider>(context, listen: false).clearRecipes();
    
    await authProvider.logout();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Grayscale ColorFilter matrix — desaturates any widget to B&W
  static const ColorFilter _grayscaleFilter = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      0.4, 0,
  ]);

  Widget _buildAvatarWidget(String? photo, String name, {double size = 110}) {
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: photo,
          imageBuilder: (context, imageProvider) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          placeholder: (context, url) => SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
          errorWidget: (context, url, error) => _buildDefaultAvatar(name, size),
        );
      } else {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1), width: 1.5),
            image: DecorationImage(
              image: AssetImage('assets/images/avatars/$photo'),
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    }
    return _buildDefaultAvatar(name, size);
  }

  Widget _buildDefaultAvatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryLight,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(fontSize: size * 0.38, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLottieWidget(
    String path, {
    double? width,
    double? height,
    bool repeat = false,
    BoxFit? fit,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (path.startsWith('http') || path.contains('uploads/')) {
      return Lottie.network(
        path,
        width: width,
        height: height,
        repeat: repeat,
        fit: fit ?? BoxFit.contain,
        errorBuilder: errorBuilder,
      );
    } else {
      return Lottie.asset(
        path,
        width: width,
        height: height,
        repeat: repeat,
        fit: fit ?? BoxFit.contain,
        errorBuilder: errorBuilder,
      );
    }
  }



  Widget _buildBmiNutritionCard(User user) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final hasMetrics = user.weight != null && user.height != null && user.age != null && user.gender != null;
    
    if (!hasMetrics) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: const Color(0xFFE8F5E9)),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 36),
            const SizedBox(height: 12),
            Text(
              langProvider.translate('physical_info_incomplete'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              langProvider.translate('physical_info_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showEditProfileSheet(context, user),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(langProvider.translate('complete_profile'), style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
    }

    // Calculations
    final weight = user.weight!;
    final height = user.height!;
    final heightInM = height / 100.0;
    final bmi = weight / (heightInM * heightInM);
    
    String bmiCategory = 'ideal';
    Color bmiColor = AppTheme.primary;
    if (bmi < 18.5) {
      bmiCategory = 'under weight';
      bmiColor = Colors.orange;
    } else if (bmi >= 25.0) {
      bmiCategory = 'over weight';
      bmiColor = Colors.redAccent;
    }

    String bmiCategoryTranslated = bmiCategory;
    if (langProvider.currentLanguage == 'id') {
      if (bmiCategory == 'ideal') bmiCategoryTranslated = 'ideal';
      if (bmiCategory == 'under weight') bmiCategoryTranslated = 'kurang berat badan';
      if (bmiCategory == 'over weight') bmiCategoryTranslated = 'kelebihan berat badan';
    }

    final targets = user.calculateDailyNutritionTargets();
    final calories = targets['calories']!.round();
    final carbs = targets['carbs']!.round();
    final fat = targets['fat']!.round();
    final protein = targets['protein']!.round();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                langProvider.translate('health_nutrition_analysis'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bmiCategoryTranslated.toUpperCase(),
                  style: TextStyle(
                    color: bmiColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14.5,
                color: AppTheme.textPrimary,
                height: 1.6,
                fontFamily: 'Inter',
              ),
              children: langProvider.currentLanguage == 'en'
                ? [
                    const TextSpan(text: 'Hello '),
                    TextSpan(text: user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '! You are currently at a weight of '),
                    TextSpan(text: '${weight.round()} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const TextSpan(text: ' and height of '),
                    TextSpan(text: '${height.round()} cm', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const TextSpan(text: ', which places you in the '),
                    TextSpan(text: bmiCategoryTranslated, style: TextStyle(fontWeight: FontWeight.bold, color: bmiColor)),
                    const TextSpan(text: ' category based on BMI calculation. Therefore, we recommend you to follow the daily calorie and nutrient target of '),
                    TextSpan(
                      text: '$calories kcal (carbohydrates ${carbs}g, fat ${fat}g, and protein ${protein}g)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    const TextSpan(text: ' calculated using the '),
                    const TextSpan(text: 'Mifflin-St Jeor', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                    const TextSpan(text: ' method.'),
                  ]
                : [
                    const TextSpan(text: 'Salam sehat '),
                    TextSpan(text: user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' !. Anda sudah berada pada posisi berat badan '),
                    TextSpan(text: '${weight.round()} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const TextSpan(text: ' dan tinggi badan '),
                    TextSpan(text: '${height.round()} cm', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const TextSpan(text: ' dimana dengan berat ini anda termasuk '),
                    TextSpan(text: bmiCategoryTranslated, style: TextStyle(fontWeight: FontWeight.bold, color: bmiColor)),
                    const TextSpan(text: ' berdasarkan perhitungan BMI. Untuk itu kami sarankan anda untuk mengikuti saran jumlah kalori dan nutrisi (karbohidrat, lemak dan protein) sejumlah '),
                    TextSpan(
                      text: '$calories kkal (karbohidrat ${carbs}g, lemak ${fat}g dan protein ${protein}g)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    const TextSpan(text: ' sesuai dengan perhitungan dengan metode '),
                    const TextSpan(text: 'Mifflin-St Jeor', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                    const TextSpan(text: '.'),
                  ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(langProvider.translate('profile_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: user == null 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // 1. Profile photo & Name Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: _buildAvatarWidget(user.photo, user.name),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => _showEditProfileSheet(context, user),
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primary,
                              child: Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    
                    // TTM Stage Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        langProvider.currentLanguage == 'en'
                            ? 'Stage: ${user.ttmStage.substring(0, 1).toUpperCase()}${user.ttmStage.substring(1)}'
                            : 'Tahap: ${user.ttmStage.substring(0, 1).toUpperCase()}${user.ttmStage.substring(1)}',
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildBmiNutritionCard(user),
              const SizedBox(height: 24),
              
              // 3. Gamification Stats Row
              FutureBuilder<Map<String, dynamic>>(
                future: StreakService().getStreak(),
                builder: (context, snapshot) {
                  final int streakCount = snapshot.data?['streak'] ?? 0;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildGamificationStatCard(
                          langProvider.translate('total_points'),
                          '${user.totalPoints} PTS',
                          Icons.stars_rounded,
                          Colors.orange,
                          langProvider.translate('accumulated_points'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGamificationStatCard(
                          langProvider.translate('streak_days'),
                          langProvider.currentLanguage == 'en'
                              ? '$streakCount ${streakCount == 1 ? 'Day' : 'Days'}'
                              : '$streakCount Hari',
                          Icons.local_fire_department_rounded,
                          Colors.redAccent,
                          langProvider.translate('consecutive_logging'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // 3.5 Card Dampak Ekologis
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          langProvider.translate('ecological_impact'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${langProvider.translate('saved_carbon_msg')} ${user.totalCarbonSaved.toStringAsFixed(2)} kg CO₂e!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      langProvider.translate('saved_carbon_desc'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.white.withValues(alpha: 0.2), height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    // Equivalences
                    _buildEcologicalRow(
                      Icons.directions_car_rounded,
                      Colors.blue.shade100,
                      '${langProvider.translate('gasoline_saved')} ${(user.totalCarbonSaved * 0.43).toStringAsFixed(2)} ${langProvider.translate('gasoline_unit')}',
                    ),
                    const SizedBox(height: 12),
                    _buildEcologicalRow(
                      Icons.forest_rounded,
                      Colors.green.shade100,
                      '${langProvider.translate('tree_saved')} ${(user.totalCarbonSaved / 21.77).toStringAsFixed(4)} ${langProvider.translate('tree_unit')}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              
              // 4. Section Etalase Lencana (Lottie-powered)
              _buildBadgeSection(context),
              
              const SizedBox(height: 36),
              
              // 5. Section Resep Tersimpan
              _buildSavedRecipesSection(context),
              
              const SizedBox(height: 40),
              
              // Logout Button
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: Text(langProvider.translate('logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Badge Section
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildBadgeSection(BuildContext context) {
    final badges = context.watch<AuthProvider>().userBadges;
    final langProvider = Provider.of<LanguageProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              langProvider.translate('badge_showcase'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (badges.isNotEmpty)
              Text(
                '${badges.where((b) => b.isUnlocked).length}/${badges.length} ${langProvider.translate('unlocked')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Empty state — server belum mengembalikan data badge
        if (badges.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Icon(Icons.military_tech_rounded, size: 52, color: Colors.grey.shade300),
                const SizedBox(height: 14),
                Text(
                  langProvider.translate('badge_showcase_empty'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78, // sedikit lebih tinggi agar nama tidak terpotong
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) => _buildBadgeGridItem(badges[index]),
          ),
      ],
    );
  }

  Widget _buildBadgeGridItem(BadgeModel badge) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    return GestureDetector(
      onTap: () {
        if (badge.isUnlocked) {
          // Tampilkan tooltip/detail saat badge sudah terbuka
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLottieWidget(
                    badge.lottieFile,
                    width: 120,
                    height: 120,
                    repeat: false,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.military_tech_rounded,
                      size: 80,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(langProvider.translate('close')),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Tampilkan kemajuan/kriteria saat badge masih terkunci
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grayscale / Lock icon container
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: ColorFiltered(
                          colorFilter: _grayscaleFilter,
                          child: _buildLottieWidget(
                            badge.lottieFile,
                            width: 90,
                            height: 90,
                            repeat: false,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.military_tech_rounded,
                              size: 70,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    langProvider.translate('badge_locked'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Progress Bar & Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              langProvider.translate('your_progress'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              '${badge.currentProgress} / ${badge.targetProgress} ${badge.progressUnit}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: badge.targetProgress > 0 ? (badge.currentProgress / badge.targetProgress) : 0.0,
                            backgroundColor: Colors.grey.shade200,
                            color: AppTheme.primary,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        langProvider.currentLanguage == 'en' ? 'Got It' : 'Mengerti',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.isUnlocked
                ? AppTheme.accent.withValues(alpha: 0.5)
                : Colors.grey.shade100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: badge.isUnlocked
                  ? AppTheme.primary.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Konten utama ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie (atau fallback) dengan ColorFiltered jika locked
                  Expanded(
                    child: badge.isUnlocked
                        ? _buildLottieWidget(
                            badge.lottieFile,
                            fit: BoxFit.contain,
                            repeat: false, // diam di frame terakhir
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.military_tech_rounded,
                              size: 52,
                              color: Color(0xFFFFD700),
                            ),
                          )
                        : ColorFiltered(
                            colorFilter: _grayscaleFilter,
                            child: _buildLottieWidget(
                              badge.lottieFile,
                              fit: BoxFit.contain,
                              repeat: false,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.military_tech_rounded,
                                size: 52,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 6),
                  // Nama badge
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badge.isUnlocked
                          ? AppTheme.textPrimary
                          : Colors.grey.shade400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Gembok di sudut kanan atas (hanya jika locked) ─────
            if (!badge.isUnlocked)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                ),
              ),

            // ── Tanda centang/bintang di sudut kiri atas (jika unlocked) ─
            if (badge.isUnlocked)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationStatCard(String title, String count, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            count,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildEcologicalRow(IconData icon, Color iconColor, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedRecipesSection(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Consumer<RecipeProvider>(
      builder: (context, recipeProv, _) {
        final savedRecipes = recipeProv.recipesList.where((r) => recipeProv.savedRecipeIds.contains(r.id)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  langProvider.currentLanguage == 'en' ? 'Saved Recipes' : 'Resep Tersimpan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (savedRecipes.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${savedRecipes.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (savedRecipes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bookmark_outline_rounded, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      langProvider.currentLanguage == 'en'
                          ? 'No saved recipes yet.\nExplore healthy recipes on the Insight page!'
                          : 'Belum ada resep yang disimpan.\nJelajahi resep sehat di halaman Insight!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: savedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = savedRecipes[index];
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: recipe.photo != null
                                          ? CachedNetworkImage(
                                              imageUrl: recipe.photo!,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(color: AppTheme.accentLight),
                                              errorWidget: (context, url, error) => Container(
                                                color: AppTheme.accentLight,
                                                child: const Icon(Icons.restaurant, color: AppTheme.primary),
                                              ),
                                            )
                                          : Container(
                                              color: AppTheme.accentLight,
                                              child: const Icon(Icons.restaurant, color: AppTheme.primary),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        recipeProv.toggleSaveRecipe(recipe.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(langProvider.currentLanguage == 'en'
                                                ? 'Recipe removed from saved'
                                                : 'Resep dihapus dari simpanan'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                                        radius: 12,
                                        child: const Icon(Icons.close, size: 14, color: AppTheme.error),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                recipe.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
          ],
        );
      },
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final User user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  
  String? _selectedAvatar;
  String? _selectedGender;
  bool _isSaving = false;

  final List<String> _avatars = [
    'abstract-shape.png',
    'camellia.png',
    'clover.png',
    'dahlia (1).png',
    'daisy.png',
    'fax.png',
    'flower (1).png',
    'flower (3).png',
    'flower pink.png',
    'flower.png',
    'flowerbiru.png',
    'flowerputih.png',
    'frangipani.png',
    'garland.png',
    'hibicus.png',
    'hibiscus.png',
    'lily.png',
    'mexican-aster.png',
    'nature.png',
    'pink-cosmos.png',
    'poppy.png',
    'rose (1).png',
    'rose.png',
    'sakura.png',
    'sunflower (1).png',
    'sunflower.png',
    'violet.png',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _ageController = TextEditingController(text: widget.user.age?.toString() ?? '');
    _weightController = TextEditingController(text: widget.user.weight?.round().toString() ?? '');
    _heightController = TextEditingController(text: widget.user.height?.round().toString() ?? '');
    _selectedGender = widget.user.gender ?? 'male';
    
    // Check if the current photo is one of the presets
    final currentPhoto = widget.user.photo;
    if (currentPhoto != null && !currentPhoto.startsWith('http')) {
      _selectedAvatar = currentPhoto;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langProvider.currentLanguage == 'en' ? 'Name cannot be empty!' : 'Nama tidak boleh kosong!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authProvider = context.read<AuthProvider>();
    bool success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      weight: double.tryParse(_weightController.text.trim()),
      height: double.tryParse(_heightController.text.trim()),
      photo: _selectedAvatar,
      gender: _selectedGender,
    );

    setState(() {
      _isSaving = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langProvider.currentLanguage == 'en' ? 'Profile updated successfully! 💖' : 'Profil berhasil diperbarui! 💖'),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langProvider.currentLanguage == 'en' ? 'Failed to update profile. Try again.' : 'Gagal memperbarui profil. Coba lagi.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slide indicator
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              langProvider.currentLanguage == 'en' ? 'Edit Profile & Personal Data' : 'Edit Profil & Data Diri',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              langProvider.currentLanguage == 'en'
                  ? 'Customize your beautiful flower avatar and edit your physical info anytime.'
                  : 'Sesuaikan avatar bunga terindahmu dan ubah info fisikmu kapan saja.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            
            // Avatar Row Selector
            Text(
              langProvider.currentLanguage == 'en' ? 'Choose Avatar Character' : 'Pilih Karakter Avatar',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final isSelected = _selectedAvatar == avatar;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatar;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.15) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                          width: isSelected ? 3.0 : 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage('assets/images/avatars/$avatar'),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Form inputs
            _buildInputField(
              controller: _nameController,
              label: langProvider.currentLanguage == 'en' ? 'Full Name' : 'Nama Lengkap',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _bioController,
              label: langProvider.currentLanguage == 'en' ? 'Tagline / Bio' : 'Slogan / Bio',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            const SizedBox(height: 16),
            
            Text(
              langProvider.currentLanguage == 'en' ? 'Gender' : 'Jenis Kelamin',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'male'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'male'
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedGender == 'male'
                              ? AppTheme.primary
                              : Colors.grey.shade200,
                          width: _selectedGender == 'male' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.male_rounded,
                            size: 20,
                            color: _selectedGender == 'male'
                                ? AppTheme.primary
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            langProvider.currentLanguage == 'en' ? 'Male' : 'Pria',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _selectedGender == 'male'
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'female'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'female'
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedGender == 'female'
                              ? AppTheme.primary
                              : Colors.grey.shade200,
                          width: _selectedGender == 'female' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.female_rounded,
                            size: 20,
                            color: _selectedGender == 'female'
                                ? AppTheme.primary
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            langProvider.currentLanguage == 'en' ? 'Female' : 'Wanita',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _selectedGender == 'female'
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _ageController, 
                    label: langProvider.currentLanguage == 'en' ? 'Age (Yrs)' : 'Usia (Thn)', 
                    icon: Icons.cake_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _heightController, 
                    label: langProvider.currentLanguage == 'en' ? 'Height (cm)' : 'Tinggi (cm)', 
                    icon: Icons.height_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _weightController, 
                    label: langProvider.currentLanguage == 'en' ? 'Weight (kg)' : 'Berat (kg)', 
                    icon: Icons.monitor_weight_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              child: _isSaving 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    langProvider.currentLanguage == 'en' ? 'Save Changes' : 'Simpan Perubahan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

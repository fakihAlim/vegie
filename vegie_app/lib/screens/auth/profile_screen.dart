import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/streak_service.dart';
import '../../models/user.dart';
import '../../models/badge_model.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
            border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 1.5),
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

  Widget _buildProfileDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          )
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profil & Pencapaian', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                color: AppTheme.primary.withOpacity(0.15),
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
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        'Tahap: ${user.ttmStage.substring(0, 1).toUpperCase()}${user.ttmStage.substring(1)}',
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
              
              // 2. Profile Details Grid (Usia, TB, BB)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildProfileDetailCard('Usia', user.age != null ? '${user.age} thn' : '-', Icons.cake_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildProfileDetailCard('Tinggi', user.height != null ? '${user.height!.round()} cm' : '-', Icons.height_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildProfileDetailCard('Berat', user.weight != null ? '${user.weight!.round()} kg' : '-', Icons.monitor_weight_rounded),
                  ),
                ],
              ),
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
                          'Total Poin',
                          '${user.totalPoints} PTS',
                          Icons.stars_rounded,
                          Colors.orange,
                          'Poin terakumulasi',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGamificationStatCard(
                          'Hari Streak',
                          '$streakCount Hari',
                          Icons.local_fire_department_rounded,
                          Colors.redAccent,
                          'Pencatatan berturut',
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
                      color: Colors.green.withOpacity(0.15),
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
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Dampak Ekologis Anda 🌿',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Anda telah menghemat ${user.totalCarbonSaved.toStringAsFixed(2)} kg CO₂e!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pola makan vegetarian Anda secara nyata mengurangi pemanasan global.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.white.withOpacity(0.2), height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    // Equivalences
                    _buildEcologicalRow(
                      Icons.directions_car_rounded,
                      Colors.blue.shade100,
                      'Setara menghemat ${(user.totalCarbonSaved * 0.43).toStringAsFixed(2)} Liter Bensin',
                    ),
                    const SizedBox(height: 12),
                    _buildEcologicalRow(
                      Icons.forest_rounded,
                      Colors.green.shade100,
                      'Setara kemampuan ${(user.totalCarbonSaved / 21.77).toStringAsFixed(4)} Pohon menyerap karbon dalam setahun',
                    ),
                    const SizedBox(height: 12),
                    _buildEcologicalRow(
                      Icons.battery_charging_full_rounded,
                      Colors.amber.shade100,
                      'Setara mengisi daya ${(user.totalCarbonSaved * 121.6).toStringAsFixed(1)} Smartphone',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              
              // 4. Section Etalase Lencana (Lottie-powered)
              _buildBadgeSection(context),
              
              const SizedBox(height: 40),
              
              // Logout Button
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Etalase Lencana',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (badges.isNotEmpty)
              Text(
                '${badges.where((b) => b.isUnlocked).length}/${badges.length} terbuka',
                style: TextStyle(
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
                const Text(
                  'Catat makanan & jawab kuis\nuntuk mendapatkan lencana pertamamu!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                    errorBuilder: (_, __, ___) => const Icon(
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
                      child: const Text('Tutup'),
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
                            errorBuilder: (_, __, ___) => Icon(
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
                    'Lencana Terkunci 🔒',
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
                            const Text(
                              'Kemajuan Anda',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                ? AppTheme.accent.withOpacity(0.5)
                : Colors.grey.shade100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: badge.isUnlocked
                  ? AppTheme.primary.withOpacity(0.06)
                  : Colors.black.withOpacity(0.025),
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
                            errorBuilder: (_, __, ___) => const Icon(
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
                              errorBuilder: (_, __, ___) => const Icon(
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
                        color: Colors.black.withOpacity(0.15),
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
            color: Colors.black.withOpacity(0.02),
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
                  color: color.withOpacity(0.1),
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
            color: Colors.white.withOpacity(0.15),
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
}

class _EditProfileSheet extends StatefulWidget {
  final User user;
  const _EditProfileSheet({Key? key, required this.user}) : super(key: key);

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
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong!'), backgroundColor: AppTheme.error),
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
    );

    setState(() {
      _isSaving = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui! 💖'),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui profil. Coba lagi.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Edit Profil & Data Diri',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Sesuaikan avatar bunga terindahmu dan ubah info fisikmu kapan saja.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            
            // Avatar Row Selector
            const Text(
              'Pilih Karakter Avatar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                        color: isSelected ? AppTheme.primaryLight.withOpacity(0.15) : Colors.transparent,
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
            _buildInputField(controller: _nameController, label: 'Nama Lengkap', icon: Icons.person_outline_rounded),
            const SizedBox(height: 16),
            _buildInputField(controller: _bioController, label: 'Slogan / Bio', icon: Icons.chat_bubble_outline_rounded),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _ageController, 
                    label: 'Usia (Thn)', 
                    icon: Icons.cake_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _heightController, 
                    label: 'Tinggi (cm)', 
                    icon: Icons.height_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _weightController, 
                    label: 'Berat (kg)', 
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
                : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

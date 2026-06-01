import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../models/badge_model.dart';
import '../config/theme.dart';

/// A celebration dialog shown whenever the user unlocks a new badge.
///
/// Usage:
/// ```dart
/// BadgeCelebrationDialog.show(context, badge);
/// ```
class BadgeCelebrationDialog {
  BadgeCelebrationDialog._();

  /// Show the celebration dialog for [badge].
  ///
  /// If [badge.lottieFile] does not exist as an asset the dialog falls back
  /// to a star icon so it never crashes.
  static Future<void> show(BuildContext context, BadgeModel badge) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      barrierDismissible: false,
      builder: (_) => _BadgeCelebrationDialogContent(badge: badge),
    );
  }
}

class _BadgeCelebrationDialogContent extends StatefulWidget {
  final BadgeModel badge;
  const _BadgeCelebrationDialogContent({required this.badge});

  @override
  State<_BadgeCelebrationDialogContent> createState() =>
      _BadgeCelebrationDialogContentState();
}

class _BadgeCelebrationDialogContentState
    extends State<_BadgeCelebrationDialogContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: _buildCard(context),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Gradient latar belakang premium
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B4332), // primaryDark
            Color(0xFF2D6A4F), // primary
            Color(0xFF40916C), // primaryLight
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.5),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ── Decorative circles (latar kedalaman) ──────────────────
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            // ── Konten utama ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label "Lencana Baru" di atas
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 13, color: Color(0xFFFFD700)),
                        const SizedBox(width: 6),
                        Text(
                          'PENCAPAIAN BARU',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Lottie animasi badge ──────────────────────────
                  _buildLottieOrFallback(),

                  const SizedBox(height: 20),

                  // ── Judul selebrasi ───────────────────────────────
                  Text(
                    'Luar Biasa! 🎉',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anda Mendapatkan Lencana Baru!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Kartu info badge ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.badge.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.badge.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Tombol Keren! ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Keren! 🚀',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders `Lottie.asset` with a graceful fallback to a star icon
  /// in case the asset file is missing (e.g. during early development).
  Widget _buildLottieOrFallback() {
    // Container dengan efek glow di belakang Lottie
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: widget.badge.lottieFile.startsWith('http')
          ? Lottie.network(
              widget.badge.lottieFile,
              width: 200,
              height: 200,
              repeat: false,          // animasi berjalan sekali lalu berhenti di frame terakhir
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            )
          : Lottie.asset(
              widget.badge.lottieFile,
              width: 200,
              height: 200,
              repeat: false,          // animasi berjalan sekali lalu berhenti di frame terakhir
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: const Icon(
        Icons.military_tech_rounded,
        size: 96,
        color: Color(0xFFFFD700),
      ),
    );
  }
}

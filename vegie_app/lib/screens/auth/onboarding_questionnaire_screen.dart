import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class OnboardingQuestionnaireScreen extends StatefulWidget {
  const OnboardingQuestionnaireScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingQuestionnaireScreen> createState() => _OnboardingQuestionnaireScreenState();
}

class _OnboardingQuestionnaireScreenState extends State<OnboardingQuestionnaireScreen> {
  final PageController _pageController = PageController();
  
  bool? isPracticing;
  bool? moreThan6Months;
  bool? intend30Days;
  bool? intend6Months;

  bool _isSubmitting = false;

  void _nextPage(int pageIndex) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _triggerSubmit() {
    _nextPage(4); // Pindah ke halaman loading
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _submitAndFinish();
      }
    });
  }

  Future<void> _submitAndFinish() async {
    setState(() {
      _isSubmitting = true;
    });

    String stage = 'PRECONTEMPLATION';

    if (isPracticing == true) {
      if (moreThan6Months == true) {
        stage = 'MAINTENANCE';
      } else {
        stage = 'ACTION';
      }
    } else {
      if (intend30Days == true) {
        stage = 'PREPARATION';
      } else {
        if (intend6Months == true) {
          stage = 'CONTEMPLATION';
        } else {
          stage = 'PRECONTEMPLATION';
        }
      }
    }

    final authProvider = context.read<AuthProvider>();
    bool success = await authProvider.submitOnboardingStage(stage);

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(Constants.keyOnboardingCompleted, true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan preferensi. Coba lagi.')),
      );
      // Kembali ke halaman pertama jika gagal
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeIn);
    }
  }

  Widget _buildQuestionPage({
    required String question,
    required String yesText,
    required String noText,
    required VoidCallback onYes,
    required VoidCallback onNo,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.eco, size: 80, color: AppTheme.primary),
          const SizedBox(height: 32),
          Text(
            question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onYes,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(yesText),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onNo,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: AppTheme.primary,
            ),
            child: Text(
              noText,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 24),
          Text(
            'Menyiapkan profil sehat Anda...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Index 0: Q1
            _buildQuestionPage(
              question: 'Apakah Anda saat ini rutin makan sayur setiap hari?',
              yesText: 'Ya, sudah rutin',
              noText: 'Belum rutin',
              onYes: () {
                setState(() => isPracticing = true);
                _nextPage(1);
              },
              onNo: () {
                setState(() => isPracticing = false);
                _nextPage(2);
              },
            ),
            // Index 1: Q2
            _buildQuestionPage(
              question: 'Wah, hebat! Apakah kebiasaan ini sudah berlangsung lebih dari 6 bulan?',
              yesText: 'Ya, lebih dari 6 bulan',
              noText: 'Belum, baru-baru ini',
              onYes: () {
                setState(() => moreThan6Months = true);
                _triggerSubmit();
              },
              onNo: () {
                setState(() => moreThan6Months = false);
                _triggerSubmit();
              },
            ),
            // Index 2: Q3
            _buildQuestionPage(
              question: 'Apakah Anda berniat untuk mulai rutin makan sayur dalam 30 hari ke depan?',
              yesText: 'Ya, saya berniat',
              noText: 'Belum ada niat',
              onYes: () {
                setState(() => intend30Days = true);
                _triggerSubmit();
              },
              onNo: () {
                setState(() => intend30Days = false);
                _nextPage(3);
              },
            ),
            // Index 3: Q4
            _buildQuestionPage(
              question: 'Bagaimana dengan 6 bulan ke depan? Apakah Anda berniat untuk mulai rutin makan sayur?',
              yesText: 'Ya, mungkin nanti',
              noText: 'Saya tidak tertarik',
              onYes: () {
                setState(() => intend6Months = true);
                _triggerSubmit();
              },
              onNo: () {
                setState(() => intend6Months = false);
                _triggerSubmit();
              },
            ),
            // Index 4: Loading/Submit screen
            _buildLoadingPage(),
          ],
        ),
      ),
    );
  }
}

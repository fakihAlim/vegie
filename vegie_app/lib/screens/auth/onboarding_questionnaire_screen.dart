import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class OnboardingQuestionnaireScreen extends StatefulWidget {
  const OnboardingQuestionnaireScreen({super.key});

  @override
  State<OnboardingQuestionnaireScreen> createState() => _OnboardingQuestionnaireScreenState();
}

class _OnboardingQuestionnaireScreenState extends State<OnboardingQuestionnaireScreen> {
  final PageController _pageController = PageController();
  
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  String? _selectedAvatar;
  String? _selectedGender = 'male';
  
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

  bool? isPracticing;
  bool? moreThan6Months;
  bool? intend30Days;
  bool? intend6Months;



  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextPage(int pageIndex) {
    Future.delayed(const Duration(milliseconds: 200), () {
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
    _nextPage(6); // Pindah ke halaman loading
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _submitAndFinish();
      }
    });
  }

  Future<void> _submitAndFinish() async {
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
    bool success = await authProvider.submitOnboardingStage(
      stage: stage,
      age: int.tryParse(_ageController.text) ?? 0,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      height: double.tryParse(_heightController.text) ?? 0.0,
      photo: _selectedAvatar ?? 'sakura.png',
      gender: _selectedGender,
    );
    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(Constants.keyOnboardingCompleted, true);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil & preferensi. Coba lagi.')),
      );
      // Kembali ke halaman pertama jika gagal
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeIn);
    }
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryLight,
              child: Icon(Icons.person_add_alt_1_rounded, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Yuk, Lengkapi Profil Sehatmu! 🌟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Masukkan data diri Anda untuk membantu menghitung porsi gizi dan streak hidup sehat Anda dengan akurat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36),
          // Gender selector
          const Text(
            'Jenis Kelamin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = 'male'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'male'
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedGender == 'male'
                            ? AppTheme.primary
                            : Colors.grey.shade200,
                        width: _selectedGender == 'male' ? 2 : 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.male_rounded,
                          size: 32,
                          color: _selectedGender == 'male'
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pria',
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
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = 'female'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'female'
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedGender == 'female'
                            ? AppTheme.primary
                            : Colors.grey.shade200,
                        width: _selectedGender == 'female' ? 2 : 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.female_rounded,
                          size: 32,
                          color: _selectedGender == 'female'
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Wanita',
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
          const SizedBox(height: 20),
          // Usia input
          _buildInputField(
            controller: _ageController,
            label: 'Usia (Tahun)',
            hint: 'Contoh: 25',
            icon: Icons.cake_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          // Tinggi Badan input
          _buildInputField(
            controller: _heightController,
            label: 'Tinggi Badan (cm)',
            hint: 'Contoh: 170',
            icon: Icons.height_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          // Berat Badan input
          _buildInputField(
            controller: _weightController,
            label: 'Berat Badan (kg)',
            hint: 'Contoh: 65',
            icon: Icons.monitor_weight_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              if (_ageController.text.trim().isEmpty ||
                  _weightController.text.trim().isEmpty ||
                  _heightController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap isi semua data profil terlebih dahulu!'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              _nextPage(1);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lanjut Pilih Avatar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: AppTheme.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Pilih Karakter Avatarmu! 🌸',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih salah satu karakter bunga indah di bawah ini untuk menjadi representasi profil sehat Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.1) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                      width: isSelected ? 3.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.01),
                        blurRadius: isSelected ? 12 : 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          'assets/images/avatars/$avatar',
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: AppTheme.primary,
                            child: Icon(Icons.check, size: 13, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () {
              if (_selectedAvatar == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap pilih salah satu avatar terlebih dahulu!'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              _nextPage(2);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mulai Kuesioner Tahap TTM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
            icon: const Icon(Icons.arrow_back, size: 16, color: AppTheme.primary),
            label: const Text('Kembali isi profil', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage({
    required String question,
    required String yesText,
    required String noText,
    required VoidCallback onYes,
    required VoidCallback onNo,
    int? backToIndex,
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
          if (backToIndex != null) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _pageController.animateToPage(backToIndex, duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
              icon: const Icon(Icons.arrow_back, size: 16, color: AppTheme.primary),
              label: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ),
          ]
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
            // Index 0: Profile form (Usia, TB, BB)
            _buildProfilePage(),
            
            // Index 1: Choose Avatar
            _buildAvatarPage(),

            // Index 2: Q1
            _buildQuestionPage(
              question: 'Apakah Anda saat ini rutin makan sayur setiap hari?',
              yesText: 'Ya, sudah rutin',
              noText: 'Belum rutin',
              onYes: () {
                setState(() => isPracticing = true);
                _nextPage(3);
              },
              onNo: () {
                setState(() => isPracticing = false);
                _nextPage(4);
              },
              backToIndex: 1,
            ),
            // Index 3: Q2
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
              backToIndex: 2,
            ),
            // Index 4: Q3
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
                _nextPage(5);
              },
              backToIndex: 2,
            ),
            // Index 5: Q4
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
              backToIndex: 4,
            ),
            // Index 6: Loading/Submit screen
            _buildLoadingPage(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../models/news.dart';
import '../../widgets/news_card.dart';
import '../../services/quiz_service.dart';
import '../../models/badge_model.dart';
import '../../widgets/badge_celebration_dialog.dart';
import '../home/home_screen.dart';


class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NewsProvider>(context, listen: false).fetchNews(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
        Provider.of<NewsProvider>(context, listen: false).fetchNews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita & Info Vegetarian', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.newsList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.newsList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal Memuat Berita',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchNews(refresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.newsList.isEmpty) {
            return const Center(child: Text('Belum ada berita.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNews(refresh: true),
            color: AppTheme.primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.newsList.length + (provider.hasMore ? 1 : 0) + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const DailyQuizCard();
                }

                final newsIndex = index - 1;
                if (newsIndex == provider.newsList.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final news = provider.newsList[newsIndex];
                return _buildNewsCard(context, news);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, News news) {
    return NewsCard(news: news);
  }
}

class DailyQuizCard extends StatefulWidget {
  const DailyQuizCard({super.key});

  @override
  State<DailyQuizCard> createState() => _DailyQuizCardState();
}

class _DailyQuizCardState extends State<DailyQuizCard> {
  final QuizService _quizService = QuizService();
  Future<Map<String, dynamic>?>? _quizFuture;
  String? _selectedOption;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _quizFuture = _quizService.getDailyQuiz();
  }

  void _submitAnswer(int quizId, int quizPoints) async {
    if (_selectedOption == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final res = await _quizService.submitAnswer(quizId, _selectedOption!);
      if (res != null) {
        setState(() {
          _result = res['data'];
          _isSubmitting = false;
        });

        final bool isCorrect = res['data']?['is_correct'] == true || res['data']?['is_correct'] == 1;
        if (isCorrect) {
          final pointsEarned = res['data']?['points_earned'] ?? quizPoints;
          if (mounted) {
            Provider.of<AuthProvider>(context, listen: false).addLocalPoints(pointsEarned);
          }
        }

        // 1. Refresh AuthProvider profile and badges to update points and unlocks
        if (mounted) {
          await Provider.of<AuthProvider>(context, listen: false).init();
          if (!mounted) return;
          await Provider.of<AuthProvider>(context, listen: false).refreshBadges();
          if (!mounted) return;
        }

        // 2. Show badge celebration dialogs if any badge was newly unlocked
        final newBadges = res['data']?['newly_unlocked_badges'] ?? res['newly_unlocked_badges'];
        if (newBadges is List && mounted) {
          for (final badgeMap in newBadges) {
            if (!mounted) break;
            final badge = BadgeModel.fromJson(badgeMap);
            await BadgeCelebrationDialog.show(context, badge);
          }
        }
      } else {
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _quizFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.success),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada kuis untuk hari ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kamu sudah menjawab semua kuis! Datang lagi besok ya. 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final quiz = snapshot.data!;
        final int quizId = quiz['id'];
        final String question = quiz['question'];
        final int quizPoints = quiz['points'] ?? 50;

        final options = {
          'a': quiz['option_a'],
          'b': quiz['option_b'],
          'c': quiz['option_c'],
          'd': quiz['option_d'],
        };

        if (_result != null) {
          final bool isCorrect = _result!['is_correct'] == true || _result!['is_correct'] == 1;
          final String explanation = _result!['explanation'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCorrect
                    ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                    : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCorrect ? 'JAWABAN BENAR! 🎉' : 'JAWABAN SALAH 💪',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isCorrect ? 'Luar biasa! Kamu mendapatkan +$quizPoints Poin!' : 'Jangan menyerah! Coba lagi di kuis besok.',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Penjelasan:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    explanation,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _result = null;
                          _selectedOption = null;
                          _quizFuture = _quizService.getDailyQuiz();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Kuis Lagi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 2)),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        side: BorderSide(
                          color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Kembali ke Halaman Discover', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'KUIS NUTRISI HARIAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Jawab dengan benar untuk mendapatkan +$quizPoints Poin!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: options.entries.map((entry) {
                    final key = entry.key;
                    final value = entry.value;
                    final isSelected = _selectedOption == key;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 52),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedOption = key;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
                            side: BorderSide(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.white60,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    key.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.textPrimary : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedOption != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submitAnswer(quizId, quizPoints),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                          : const Text('Kirim Jawaban', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

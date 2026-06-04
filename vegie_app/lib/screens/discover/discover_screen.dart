import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quest_provider.dart';
import '../../services/quiz_service.dart';
import '../groups/group_list_screen.dart';
import '../quizzes/quiz_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final QuizService _quizService = QuizService();
  Map<String, dynamic>? _dailyQuiz;
  bool _isLoadingQuiz = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuestProvider>(context, listen: false).fetchQuests();
      _fetchDailyQuiz();
    });
  }

  Future<void> _fetchDailyQuiz() async {
    setState(() => _isLoadingQuiz = true);
    final quiz = await _quizService.getDailyQuiz();
    setState(() {
      _dailyQuiz = quiz;
      _isLoadingQuiz = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Feature Locking Logic for Community (Groups)
    final user = Provider.of<AuthProvider>(context).user;
    final bool isLocked = user?.isFeatureLocked ?? false;
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(langProvider.translate('nav_discover'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          Provider.of<QuestProvider>(context, listen: false).fetchQuests();
          await _fetchDailyQuiz();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(langProvider.translate('daily_quests')),
              _buildQuestsSection(),
              
              const SizedBox(height: 24),
              _buildSectionTitle(langProvider.translate('todays_quiz')),
              _buildQuizSection(),
              
              const SizedBox(height: 24),
              _buildSectionTitle(langProvider.translate('community_groups')),
              if (isLocked)
                _buildLockedCommunity()
              else
                _buildCommunityPreview(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryDark,
        ),
      ),
    );
  }

  Widget _buildQuestsSection() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Consumer<QuestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.quests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.quests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(langProvider.translate('no_quests_today')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: provider.quests.length,
          itemBuilder: (context, index) {
            final quest = provider.quests[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: quest.isCompleted ? AppTheme.success.withValues(alpha: 0.3) : Colors.transparent),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: quest.isCompleted ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.primaryLight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    quest.isCompleted ? Icons.check_circle : Icons.star_border,
                    color: quest.isCompleted ? AppTheme.success : AppTheme.primary,
                  ),
                ),
                title: Text(
                  quest.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(quest.description, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${quest.progressCount} / ${quest.targetCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: quest.isCompleted ? AppTheme.success : AppTheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${quest.pointsReward} pts',
                            style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuizSection() {
    final langProvider = Provider.of<LanguageProvider>(context);
    if (_isLoadingQuiz) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dailyQuiz == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(langProvider.translate('answered_all_quizzes'), textAlign: TextAlign.center),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(quizId: _dailyQuiz!['id']),
          ),
        ).then((_) {
          // Refresh after returning
          _fetchDailyQuiz();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryLight, AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.lightbulb, size: 120, color: Colors.white.withValues(alpha: 0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(langProvider.translate('new_quiz'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text('+${_dailyQuiz!['points']} pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    langProvider.translate('test_knowledge'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dailyQuiz!['question'],
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(quizId: _dailyQuiz!['id']),
                        ),
                      ).then((_) {
                        _fetchDailyQuiz();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(langProvider.translate('start_quiz')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityPreview() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(langProvider.translate('network_together'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(langProvider.translate('network_desc'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupListScreen()));
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(langProvider.translate('open_community'), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCommunity() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            langProvider.translate('community_locked'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
          ),
          const SizedBox(height: 8),
          Text(
            langProvider.translate('community_locked_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

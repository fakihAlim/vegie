import 'package:flutter/material.dart';
import '../news/news_screen.dart';
import '../../config/theme.dart';

class QuizScreen extends StatelessWidget {
  final int quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Kuis Harian', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: DailyQuizCard(),
      ),
    );
  }
}

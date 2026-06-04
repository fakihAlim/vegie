import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/news_provider.dart';
import '../../config/theme.dart';
import '../../models/news.dart';
import '../../providers/auth_provider.dart';
import '../../models/badge_model.dart';
import '../../widgets/badge_celebration_dialog.dart';
import '../../services/activity_log_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news; // Kirim object utuh dari list

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late News _news;
  bool _isLoadingExtra = false;

  @override
  void initState() {
    super.initState();
    _news = widget.news; // Set data awal secara instan
    _logNewsView();
    _loadExtraDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newsProv = Provider.of<NewsProvider>(context, listen: false);
      if (newsProv.newsList.isEmpty) {
        newsProv.fetchNews(refresh: true);
      }
    });
  }

  Future<void> _logNewsView() async {
    try {
      final newBadges = await ActivityLogService.instance.logEvent('news_view', extraData: {
        'news_id': _news.id,
        'title': _news.title,
      });

      if (newBadges != null && newBadges.isNotEmpty && mounted) {
        // Refresh AuthProvider profile and badges to update points and unlocks
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        await authProv.init();
        if (!mounted) return;
        await authProv.refreshBadges();
        if (!mounted) return;

        // Show badge celebration dialogs one by one
        for (final badgeMap in newBadges) {
          if (!mounted) break;
          final badge = BadgeModel.fromJson(badgeMap);
          await BadgeCelebrationDialog.show(context, badge);
        }
      }
    } catch (e) {
      debugPrint('Error logging news view / showing badge: $e');
    }
  }

  Future<void> _loadExtraDetail() async {
    setState(() { _isLoadingExtra = true; });
    final detail = await Provider.of<NewsProvider>(context, listen: false).getNewsDetail(_news.id);
    if (mounted && detail != null) {
      setState(() {
        _news = detail; // Update dengan data yang lebih lengkap
        _isLoadingExtra = false;
      });
    } else if (mounted) {
      setState(() { _isLoadingExtra = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'news_image_${_news.id}',
                child: _news.image != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: _news.image!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.accentLight,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.accentLight,
                              child: Icon(Icons.article, size: 80, color: AppTheme.primary.withValues(alpha: 0.3)),
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(0.0, 0.5),
                                end: Alignment(0.0, 0.0),
                                colors: <Color>[
                                  Color(0x60000000),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: AppTheme.accentLight,
                        child: Icon(Icons.article, size: 80, color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge/Category (Optional but looks premium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Berita & Info',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _news.title,
                      style: const TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold, 
                        height: 1.3,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.eco, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LovingHarmony Editor',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              DateFormat('dd MMMM yyyy').format(_news.publishedAt),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ),
                    // Content section with loading state
                    if (_isLoadingExtra && (_news.content == null || _news.content!.isEmpty))
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(strokeWidth: 2),
                              SizedBox(height: 12),
                              Text(
                                'Memuat konten...',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_news.content != null && _news.content!.isNotEmpty)
                      MarkdownBody(
                        data: _news.content!,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: const TextStyle(
                            fontSize: 16, 
                            height: 1.8, 
                            color: Color(0xFF374151),
                            letterSpacing: 0.2,
                          ),
                          h1: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                            color: AppTheme.textPrimary,
                          ),
                          h2: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                            color: AppTheme.textPrimary,
                          ),
                          listBullet: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),

                    // Related Articles Section
                    Consumer<NewsProvider>(
                      builder: (context, newsProv, _) {
                        final relatedArticles = newsProv.newsList
                            .where((item) => item.id != _news.id)
                            .take(3)
                            .toList();

                        if (relatedArticles.isEmpty) {
                          if (newsProv.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                            ),
                            const Text(
                              'Artikel Terkait Lainnya',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...relatedArticles.map((article) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NewsDetailScreen(news: article),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF3F4F6)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.01),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              article.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                height: 1.3,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              DateFormat('dd MMMM yyyy').format(article.publishedAt),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: AppTheme.accentLight,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: article.image != null
                                            ? CachedNetworkImage(
                                                imageUrl: article.image!,
                                                fit: BoxFit.cover,
                                                errorWidget: (c, u, e) => const Icon(
                                                  Icons.article_outlined,
                                                  color: AppTheme.primary,
                                                  size: 24,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.article_outlined,
                                                color: AppTheme.primary,
                                                size: 24,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

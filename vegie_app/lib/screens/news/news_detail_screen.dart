import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/news_provider.dart';
import '../../config/theme.dart';
import '../../models/news.dart';
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
    ActivityLogService.instance.logEvent('news_view', extraData: {
      'news_id': _news.id,
      'title': _news.title,
    });
    _loadExtraDetail();
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
                      Text(
                        _news.content!,
                        style: const TextStyle(
                          fontSize: 16, 
                          height: 1.8, 
                          color: Color(0xFF374151),
                          letterSpacing: 0.2,
                        ),
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

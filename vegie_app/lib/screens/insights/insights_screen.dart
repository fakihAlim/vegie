import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../providers/myth_fact_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/myth_fact_service.dart';
import '../../models/news.dart';
import '../../models/recipe.dart';
import '../news/news_detail_screen.dart';
import '../recipes/recipe_detail_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MythFactProvider>(context, listen: false).fetchMyths();
      
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      if (newsProvider.newsList.isEmpty) {
        newsProvider.fetchNews(refresh: true);
      }
      
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      if (recipeProvider.recipesList.isEmpty) {
        recipeProvider.fetchRecipes(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          Provider.of<MythFactProvider>(context, listen: false).fetchMyths();
          Provider.of<NewsProvider>(context, listen: false).fetchNews(refresh: true);
          Provider.of<RecipeProvider>(context, listen: false).fetchRecipes(refresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSectionTitle('Myth vs Fact'),
              _buildMythFactSection(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Berita Terkini'),
              _buildNewsSection(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Resep Pilihan'),
              _buildRecipeSection(),
              
              const SizedBox(height: 40), // Bottom padding
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

  Widget _buildMythFactSection() {
    return Consumer<MythFactProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.myths.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.myths.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Belum ada data Myth vs Fact')),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.myths.length,
            itemBuilder: (context, index) {
              final item = provider.myths[index];
              return _buildMythFactCard(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildMythFactCard(MythFact item) {
    final isMyth = item.type == 'myth';
    final badgeColor = isMyth ? Colors.orange : AppTheme.success;
    
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                isMyth ? Icons.help_outline : Icons.check_circle_outline,
                size: 120,
                color: badgeColor.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.type.toUpperCase(),
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildNewsSection() {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.newsList.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        if (provider.newsList.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: Text('Belum ada berita')));
        }

        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.newsList.length,
            itemBuilder: (context, index) {
              final news = provider.newsList[index];
              return _buildNewsCard(news);
            },
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(News news) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: news.image ?? '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.image)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.publishedAt.toString().split(' ')[0],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficulty(int? minutes) {
    if (minutes == null) return 'Sedang';
    if (minutes <= 20) return 'Mudah';
    if (minutes <= 45) return 'Sedang';
    return 'Sulit';
  }

  Widget _buildRecipeSection() {
    return Consumer<RecipeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.recipesList.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        if (provider.recipesList.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: Text('Belum ada resep')));
        }

        return SizedBox(
          height: 380,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.recipesList.length,
            itemBuilder: (context, index) {
              final recipe = provider.recipesList[index];
              return _buildRecipeCard(recipe);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: recipe.photo ?? '',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: AppTheme.accentLight,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: AppTheme.accentLight,
                      child: Icon(Icons.restaurant, size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficulty(recipe.prepTimeMinutes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<RecipeProvider>(
                    builder: (context, recipeProv, _) {
                      final isSaved = recipeProv.isRecipeSaved(recipe.id);
                      return GestureDetector(
                        onTap: () {
                          recipeProv.toggleSaveRecipe(recipe.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSaved ? 'Resep dihapus dari simpanan' : 'Resep berhasil disimpan! 💚'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.95),
                          radius: 18,
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? AppTheme.primary : AppTheme.textPrimary,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.description ?? 'Resep vegetarian bergizi tinggi dan sehat.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade100, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_outlined, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.calories} kcal',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.prepTimeMinutes ?? 0} mnt',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

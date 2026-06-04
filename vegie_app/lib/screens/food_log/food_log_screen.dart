import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/quest_provider.dart';
import '../../config/theme.dart';
import '../../models/food_log.dart';
import '../../models/user.dart';
import '../../widgets/month_calendar.dart';
import '../auth/settings_screen.dart';
import '../../providers/language_provider.dart';
import 'edit_food_log_screen.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodLogProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final langProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${langProvider.translate('hello')}, ${user?.name.split(' ')[0] ?? 'User'} 👋', style: const TextStyle(fontSize: 16, color: AppTheme.primaryLight)),
            Text(langProvider.translate('your_food_logs'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<FoodLogProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.logs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              await provider.forceSync();
              if (context.mounted) {
                Provider.of<AuthProvider>(context, listen: false).init();
              }
            },
            color: AppTheme.primary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      MonthCalendar(
                        selectedDate: provider.selectedDate,
                        onDateSelected: provider.selectDate,
                        hasLogs: provider.hasLogsOnDate,
                      ),
                      _buildDailyNutritionSummary(provider, user),
                      const SizedBox(height: 16),
                      _buildQuoteCard(provider),
                      const Divider(height: 32, thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${langProvider.translate('food_logs_for')} ${DateFormat('d MMM yyyy').format(provider.selectedDate)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                provider.filteredLogs.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildLogCard(provider.filteredLogs[index]);
                            },
                            childCount: provider.filteredLogs.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            langProvider.translate('no_food_logs'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            langProvider.translate('tap_camera'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyNutritionSummary(FoodLogProvider provider, User? user) {
    final langProvider = Provider.of<LanguageProvider>(context);
    double totalCarbs = 0;
    double totalFat = 0;
    double totalProtein = 0;
    double totalCalories = 0;

    for (var log in provider.filteredLogs) {
      totalCarbs += log.carbs ?? 0;
      totalFat += log.fat ?? 0;
      totalProtein += log.protein ?? 0;
      totalCalories += log.calories ?? 0;
    }

    if (totalCalories == 0) return const SizedBox.shrink();

    final targets = user?.calculateDailyNutritionTargets() ?? {
      'calories': 2000.0,
      'carbs': 250.0,
      'fat': 66.7,
      'protein': 100.0,
    };

    final targetCalories = targets['calories'] ?? 2000.0;
    final targetCarbs = targets['carbs'] ?? 250.0;
    final targetFat = targets['fat'] ?? 66.7;
    final targetProtein = targets['protein'] ?? 100.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(langProvider.translate('today_nutrition'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionCircle(langProvider.translate('calories'), totalCalories, targetCalories, Colors.blue, 'kcal', isInt: true),
              _buildNutritionCircle(langProvider.translate('carbs'), totalCarbs, targetCarbs, Colors.orange, 'g'),
              _buildNutritionCircle(langProvider.translate('fat'), totalFat, targetFat, Colors.yellow.shade700, 'g'),
              _buildNutritionCircle(langProvider.translate('protein'), totalProtein, targetProtein, Colors.red.shade400, 'g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCircle(String label, double value, double target, Color color, String unit, {bool isInt = false}) {
    final displayValue = isInt ? value.toInt().toString() : value.toStringAsFixed(1);
    final displayTarget = isInt ? target.toInt().toString() : target.toStringAsFixed(0);
    final progressValue = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                color: color.withValues(alpha: 0.2),
              ),
            ),
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progressValue,
                strokeWidth: 4,
                color: color,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  unit,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          '/$displayTarget$unit',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.normal),
        ),
      ],
    );
  }




  // Calendar logic moved to MonthCalendar widget

  Widget _buildQuoteCard(FoodLogProvider provider) {
    if (provider.todayQuote == null) return const SizedBox.shrink();
    final langProvider = Provider.of<LanguageProvider>(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentLight, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -10,
            bottom: -10,
            child: Icon(Icons.eco, size: 60, color: AppTheme.accentLight),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_quote, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(langProvider.translate('today_inspiration'), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '"${provider.todayQuote!.quoteText}"',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, height: 1.5),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "— ${provider.todayQuote!.author}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(FoodLog log) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditFoodLogScreen(log: log)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Image + Basic Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildThumbnail(log),
                    ),
                    const SizedBox(width: 16),
                    
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  log.foodName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (log.hasNutrition && log.id != null)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    log.isShared ? Icons.share : Icons.share_outlined,
                                    color: log.isShared ? AppTheme.primary : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  tooltip: log.isShared ? 'Batal bagikan ke Discover' : 'Bagikan ke Discover',
                                  onPressed: () async {
                                    final provider = Provider.of<FoodLogProvider>(context, listen: false);
                                    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                                    final questProvider = Provider.of<QuestProvider>(context, listen: false);
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    final messenger = ScaffoldMessenger.of(context);
 
                                    final success = await provider.toggleShareLog(log);
                                    if (!mounted) return;
                                    if (success) {
                                      // Refresh Discover Feed in background
                                      groupProvider.fetchDiscoverFeed();
                                      
                                      final updatedLog = provider.logs.firstWhere((l) => l.localId == log.localId, orElse: () => log);
                                      if (updatedLog.isShared) {
                                        // Pemicu progres misi
                                        final questUpdated = await questProvider.updateQuestProgress('share_group');
                                        if (questUpdated) {
                                          authProvider.init();
                                        }
                                      }
 
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(log.isShared 
                                              ? 'Batal membagikan jurnal makanan.' 
                                              : 'Berhasil membagikan jurnal makanan ke Discover!'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppTheme.primary,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Gagal mengubah status pembagian jurnal makanan.'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            langProvider.translate('estimate_serving'),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildCategoryPill(log.category),
                              const SizedBox(width: 8),
                              _buildPointsBadge(log.points),
                              const SizedBox(width: 8),
                              Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('HH:mm').format(log.mealTime),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              if (!log.isSynced)
                                const Icon(Icons.cloud_off, size: 14, color: AppTheme.warning)
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider
              Divider(height: 1, color: Colors.blue.shade100),
              
              // Nutrition Data
              Padding(
                padding: const EdgeInsets.all(16),
                child: log.hasNutrition ? _buildNutritionData(log) : _buildNoNutritionData(),
              ),

              // Notes
              if (log.nutritionNotes != null && log.nutritionNotes!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📝 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          log.nutritionNotes!,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(FoodLog log) {
    if (log.photoPath != null && File(log.photoPath!).existsSync()) {
      return Image.file(File(log.photoPath!), fit: BoxFit.cover);
    } else if (log.photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: log.photoUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.restaurant, color: Colors.grey),
      );
    }
    return const Icon(Icons.restaurant, color: Colors.grey);
  }

  Widget _buildNutritionData(FoodLog log) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final maxVal = [log.carbs ?? 0, log.fat ?? 0, log.protein ?? 0, 1.0].reduce((a, b) => a > b ? a : b);
    
    List<dynamic> items = [];
    if (log.rawResponse != null) {
      try {
        final Map<String, dynamic> parsed = Map<String, dynamic>.from(jsonDecode(log.rawResponse!));
        if (parsed['items'] != null && parsed['items'] is List) {
          items = parsed['items'];
        }
      } catch (e) {
        // Ignored
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) ...[
          Text(
            langProvider.translate('ingredient_composition'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map<Widget>((item) {
            final double itemCal = item['kalori'] != null ? (item['kalori'] as num).toDouble() : 0.0;
            final double itemCarbs = item['karbohidrat'] != null ? (item['karbohidrat'] as num).toDouble() : 0.0;
            final double itemFat = item['lemak'] != null ? (item['lemak'] as num).toDouble() : 0.0;
            final double itemProtein = item['protein'] != null ? (item['protein'] as num).toDouble() : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama'] ?? 'Bahan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCompactNutrientBadge('${itemCal.toStringAsFixed(0)} kcal', Colors.blue.shade700, Colors.blue.shade50),
                        _buildCompactNutrientBadge('${itemCarbs.toStringAsFixed(1)}g ${langProvider.translate('carbs')}', Colors.orange.shade700, Colors.orange.shade50),
                        _buildCompactNutrientBadge('${itemFat.toStringAsFixed(1)}g ${langProvider.translate('fat')}', Colors.yellow.shade900, Colors.yellow.shade50),
                        _buildCompactNutrientBadge('${itemProtein.toStringAsFixed(1)}g ${langProvider.translate('protein').substring(0, 4)}', Colors.red.shade700, Colors.red.shade50),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.blue.shade100),
          const SizedBox(height: 8),
        ],
        // Total Energy
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                items.isNotEmpty ? langProvider.translate('total_nutrition_label') : langProvider.translate('total_energy_label'), 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)
              ),
              Text('${log.calories?.toStringAsFixed(0)} kcal', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue.shade700, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Progress Bars
        _buildNutrientRow(langProvider.translate('carbs'), log.carbs ?? 0, maxVal, Colors.orange),
        const SizedBox(height: 8),
        _buildNutrientRow(langProvider.translate('fat'), log.fat ?? 0, maxVal, Colors.yellow.shade700),
        const SizedBox(height: 8),
        _buildNutrientRow(langProvider.translate('protein'), log.protein ?? 0, maxVal, Colors.red.shade400),
      ],
    );
  }

  Widget _buildNoNutritionData() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.pending_actions, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            langProvider.translate('analyzing_nutrition'),
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            langProvider.translate('click_edit_manual'),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, double value, double maxVal, Color color) {
    final percentage = (value / maxVal).clamp(0.0, 1.0);
    
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text('${value.toStringAsFixed(1)}g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildCompactNutrientBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category) {
    Color color;
    switch (category.toLowerCase()) {
      case 'breakfast': color = Colors.orange; break;
      case 'lunch': color = Colors.green; break;
      case 'dinner': color = Colors.blue; break;
      default: color = Colors.purple;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildPointsBadge(int points) {
    final isPositive = points >= 0;
    final color = isPositive ? AppTheme.success : AppTheme.error;
    final text = isPositive ? '+$points pts' : '$points pts';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

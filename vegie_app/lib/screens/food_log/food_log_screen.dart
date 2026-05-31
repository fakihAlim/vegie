import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import '../../models/food_log.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/month_calendar.dart';
import 'add_food_log_screen.dart';
import 'edit_food_log_screen.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({Key? key}) : super(key: key);

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
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${user?.name.split(' ')[0] ?? 'User'} 👋', style: const TextStyle(fontSize: 16, color: AppTheme.primaryLight)),
            const Text('Your Food Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing data...')),
              );
              await Provider.of<FoodLogProvider>(context, listen: false).forceSync();
              if (context.mounted) {
                Provider.of<AuthProvider>(context, listen: false).init();
              }
              ActivityLogService.instance.logEvent('sync_manual');
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
                      _buildHeaderStats(provider.streak),
                      MonthCalendar(
                        selectedDate: provider.selectedDate,
                        onDateSelected: provider.selectDate,
                        hasLogs: provider.hasLogsOnDate,
                      ),
                      _buildQuoteCard(provider),
                      const Divider(height: 32, thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Food Logs for ${DateFormat('d MMM yyyy').format(provider.selectedDate)}',
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'foodLogFab',
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFoodLogScreen()),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No food logs on this date',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a vegetarian meal!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(int streak) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(
            icon: Icons.bolt,
            iconColor: Colors.orange,
            value: '$streak hari',
            label: 'Streak',
          ),
          _buildStatCard(
            icon: Icons.people,
            iconColor: Colors.blue,
            value: '0',
            label: 'Notifikasi Grup',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required Color iconColor, required String value, required String label}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // Calendar logic moved to MonthCalendar widget

  Widget _buildQuoteCard(FoodLogProvider provider) {
    if (provider.todayQuote == null) return const SizedBox.shrink();

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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
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
                children: const [
                  Icon(Icons.format_quote, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Inspirasi Hari Ini', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
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
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
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
                                    final success = await provider.toggleShareLog(log);
                                    if (success) {
                                      // Refresh Discover Feed in background
                                      Provider.of<GroupProvider>(context, listen: false).fetchDiscoverFeed();
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(log.isShared 
                                              ? 'Batal membagikan jurnal makanan.' 
                                              : 'Berhasil membagikan jurnal makanan ke Discover!'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppTheme.primary,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
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
                            'ESTIMASI PER PORSI',
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
            'KOMPOSISI BAHAN',
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
                        _buildCompactNutrientBadge('${itemCarbs.toStringAsFixed(1)}g Karbo', Colors.orange.shade700, Colors.orange.shade50),
                        _buildCompactNutrientBadge('${itemFat.toStringAsFixed(1)}g Lemak', Colors.yellow.shade900, Colors.yellow.shade50),
                        _buildCompactNutrientBadge('${itemProtein.toStringAsFixed(1)}g Prot', Colors.red.shade700, Colors.red.shade50),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
                items.isNotEmpty ? 'Total Nutrisi' : 'Total Energi', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)
              ),
              Text('${log.calories?.toStringAsFixed(0)} kcal', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue.shade700, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Progress Bars
        _buildNutrientRow('Karbohidrat', log.carbs ?? 0, maxVal, Colors.orange),
        const SizedBox(height: 8),
        _buildNutrientRow('Lemak', log.fat ?? 0, maxVal, Colors.yellow.shade700),
        const SizedBox(height: 8),
        _buildNutrientRow('Protein', log.protein ?? 0, maxVal, Colors.red.shade400),
      ],
    );
  }

  Widget _buildNoNutritionData() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.pending_actions, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Sedang Menganalisis Nutrisi...',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Klik untuk edit manual atau melihat hasil',
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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

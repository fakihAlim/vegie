import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../services/activity_log_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe; // Kirim object utuh dari list

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  bool _isLoadingExtra = false;
  List<bool> _ingredientChecked = [];

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe; // Set data awal secara instan
    _ingredientChecked = List.filled(_recipe.ingredients?.length ?? 0, false);
    
    ActivityLogService.instance.logEvent('recipe_view', extraData: {
      'recipe_id': _recipe.id,
      'title': _recipe.title,
    });
    
    _loadExtraDetail();
  }

  Future<void> _loadExtraDetail() async {
    setState(() { _isLoadingExtra = true; });
    final detail = await Provider.of<RecipeProvider>(context, listen: false).getRecipeDetail(_recipe.id);
    if (mounted && detail != null) {
      setState(() {
        _recipe = detail; // Update dengan data yang lebih lengkap (ingredients, steps)
        _isLoadingExtra = false;
        _ingredientChecked = List.filled(detail.ingredients?.length ?? 0, false);
      });
    } else if (mounted) {
      setState(() { _isLoadingExtra = false; });
    }
  }

  String getDifficulty(int? minutes) {
    if (minutes == null) return 'Sedang';
    if (minutes <= 20) return 'Mudah';
    if (minutes <= 45) return 'Sedang';
    return 'Sulit';
  }

  @override
  Widget build(BuildContext context) {
    // Nutritional Info Section (Use DB values or dynamic fallback)
    final int caloriesVal = _recipe.calories ?? 350;
    final int protein = _recipe.protein ?? (caloriesVal * 0.15 / 4).round();
    final int carbs = _recipe.carbs ?? (caloriesVal * 0.55 / 4).round();
    final int fat = _recipe.fat ?? (caloriesVal * 0.30 / 9).round();

    final double proteinProgress = (protein / 50.0).clamp(0.0, 1.0);
    final double carbsProgress = (carbs / 150.0).clamp(0.0, 1.0);
    final double fatProgress = (fat / 50.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
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
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Consumer<RecipeProvider>(
                  builder: (context, recipeProv, _) {
                    final isSaved = recipeProv.isRecipeSaved(_recipe.id);
                    return CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? AppTheme.primary : AppTheme.textPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          recipeProv.toggleSaveRecipe(_recipe.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSaved ? 'Resep dihapus dari simpanan' : 'Resep berhasil disimpan! 💚'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'recipe_image_${_recipe.id}',
                child: _recipe.photo != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: _recipe.photo!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.accentLight,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.accentLight,
                              child: Icon(Icons.restaurant, size: 80, color: AppTheme.primary.withValues(alpha: 0.3)),
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: <Color>[
                                  Colors.black45,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: AppTheme.accentLight,
                        child: Icon(Icons.restaurant, size: 80, color: AppTheme.primary.withValues(alpha: 0.3)),
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
                    // Dynamic Tags Section (Vegan / High Protein / Vegetarian)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: ((_recipe.tags != null && _recipe.tags!.isNotEmpty)
                          ? _recipe.tags!
                          : const ['HIGH PROTEIN', 'VEGAN']).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _recipe.title,
                      style: const TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold, 
                        height: 1.3,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Deskripsi
                    if (_recipe.description != null && _recipe.description!.isNotEmpty) ...[
                      Text(
                        _recipe.description!, 
                        style: TextStyle(
                          fontSize: 14.5, 
                          height: 1.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Info Bar (Waktu, Kalori, Tingkat Kesulitan)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoItem(
                            Icons.timer_outlined,
                            '${_recipe.prepTimeMinutes ?? 0} min',
                            'Prep Time',
                            Colors.blue.shade700,
                          ),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          _buildInfoItem(
                            Icons.local_fire_department_outlined,
                            '${_recipe.calories ?? 0} kcal',
                            'Calories',
                            Colors.orange.shade700,
                          ),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          _buildInfoItem(
                            Icons.restaurant_menu_outlined,
                            getDifficulty(_recipe.prepTimeMinutes),
                            'Difficulty',
                            Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Loading indicator for extra detail (ingredients & steps)
                    if (_isLoadingExtra && (_recipe.ingredients == null) && (_recipe.steps == null))
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(strokeWidth: 2),
                              SizedBox(height: 12),
                              Text(
                                'Memuat bahan & langkah memasak...',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Ingredients
                    if (_recipe.ingredients != null && _recipe.ingredients!.isNotEmpty) ...[
                      const Text(
                        'Ingredients', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: List.generate(_recipe.ingredients!.length, (index) {
                            final ing = _recipe.ingredients![index];
                            if (_ingredientChecked.length <= index) {
                              _ingredientChecked.add(false);
                            }
                            final isChecked = _ingredientChecked[index];

                            return CheckboxListTile(
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  _ingredientChecked[index] = val ?? false;
                                });
                              },
                              activeColor: AppTheme.primary,
                              title: Text(
                                ing.ingredient,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked ? Colors.grey : AppTheme.textPrimary,
                                ),
                              ),
                              secondary: Text(
                                ing.amount ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isChecked ? Colors.grey : AppTheme.primaryDark,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Steps / Instructions
                    if (_recipe.steps != null && _recipe.steps!.isNotEmpty) ...[
                      const Text(
                        'Instructions', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: _recipe.steps!.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC8E6C9), // Light green circle matching reference
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${step.stepNumber}',
                                      style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    step.description, 
                                    style: const TextStyle(
                                      fontSize: 15, 
                                      height: 1.5,
                                      color: AppTheme.textPrimary,
                                    )
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Nutritional Info
                    const Text(
                      'NUTRITIONAL INFO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          _buildNutrientRow('Protein', '${protein}g', proteinProgress, const Color(0xFF2E7D32)),
                          const SizedBox(height: 14),
                          _buildNutrientRow('Carbs', '${carbs}g', carbsProgress, const Color(0xFF1B5E20)),
                          const SizedBox(height: 14),
                          _buildNutrientRow('Fats', '${fat}g', fatProgress, const Color(0xFF81C784)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tip Insight Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Color(0xFF2E7D32), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (_recipe.tips != null && _recipe.tips!.isNotEmpty)
                                  ? _recipe.tips!
                                  : (_recipe.id % 2 == 0
                                      ? "Tip: Konsumsi dengan buah tinggi Vitamin C untuk meningkatkan penyerapan zat besi dari sayuran hijau!"
                                      : "Tip: Tambahkan perasan lemon segar untuk meningkatkan cita rasa dan memaksimalkan nutrisi hidangan!"),
                              style: const TextStyle(
                                color: Color(0xFF1B5E20),
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer2<RecipeProvider, AuthProvider>(
        builder: (context, recipeProv, authProv, _) {
          final isTried = recipeProv.isRecipeTried(_recipe.id);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isTried
                          ? null
                          : () async {
                              // 1. Mark as tried locally
                              await recipeProv.setRecipeTried(_recipe.id);

                              // 2. Trigger quest update
                              if (context.mounted) {
                                final questUpdated = await Provider.of<QuestProvider>(context, listen: false)
                                    .updateQuestProgress('try_recipe');
                                
                                // 3. Refresh user profile / points
                                if (context.mounted) {
                                  await Provider.of<AuthProvider>(context, listen: false).init();
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        questUpdated
                                            ? 'Selamat! Kamu sudah mencoba resep ini dan menyelesaikan misi! +20 Poin 🎉'
                                            : 'Resep berhasil ditandai sebagai dicoba! 👍',
                                      ),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTried ? Colors.grey : AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(isTried ? Icons.check_circle : Icons.thumb_up_alt_outlined),
                      label: Text(
                        isTried ? "Sudah Dicoba 👍" : "Saya Sudah Mencoba Resep Ini",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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

  Widget _buildNutrientRow(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade100,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

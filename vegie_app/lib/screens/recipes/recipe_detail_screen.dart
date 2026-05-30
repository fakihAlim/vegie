import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/recipe_provider.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../services/activity_log_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe; // Kirim object utuh dari list

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  bool _isLoadingExtra = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe; // Set data awal secara instan
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
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
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
                              child: Icon(Icons.restaurant, size: 80, color: AppTheme.primary.withOpacity(0.3)),
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(0.0, 0.5),
                                end: Alignment(0.0, 0.0),
                                colors: <Color>[
                                  Color(0x70000000),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: AppTheme.accentLight,
                        child: Icon(Icons.restaurant, size: 80, color: AppTheme.primary.withOpacity(0.3)),
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
                    const SizedBox(height: 24),
                    
                    // Info Bar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_recipe.prepTimeMinutes != null)
                            _buildInfoItem(Icons.timer_outlined, '${_recipe.prepTimeMinutes} Mnt', 'Waktu', Colors.blue),
                          if (_recipe.prepTimeMinutes != null && _recipe.calories != null)
                            Container(width: 1, height: 40, color: Colors.grey.shade200),
                          if (_recipe.calories != null)
                            _buildInfoItem(Icons.local_fire_department_outlined, '${_recipe.calories}', 'Kalori', Colors.orange),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Deskripsi
                    if (_recipe.description != null && _recipe.description!.isNotEmpty) ...[
                      Text(
                        _recipe.description!, 
                        style: const TextStyle(
                          fontSize: 16, 
                          height: 1.6,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

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
                        'Bahan-bahan', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: _recipe.ingredients!.map((ing) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 20, color: AppTheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ing.ingredient, 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                                  )
                                ),
                                if (ing.amount != null)
                                  Text(
                                    ing.amount!, 
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 15,
                                      color: AppTheme.primaryDark
                                    )
                                  ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Steps
                    if (_recipe.steps != null && _recipe.steps!.isNotEmpty) ...[
                      const Text(
                        'Langkah Memasak', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)
                      ),
                      const SizedBox(height: 24),
                      ..._recipe.steps!.map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primary, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${step.stepNumber}',
                                  style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  step.description, 
                                  style: const TextStyle(
                                    fontSize: 16, 
                                    height: 1.6,
                                    color: Color(0xFF374151),
                                  )
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

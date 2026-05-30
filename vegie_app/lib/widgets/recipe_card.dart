import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/recipe.dart';
import '../screens/recipes/recipe_detail_screen.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, __, ___) => RecipeDetailScreen(recipeId: recipe.id, title: recipe.title),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  Hero(
                    tag: 'recipe_image_${recipe.id}',
                    child: recipe.photo != null
                        ? Image.network(
                            recipe.photo!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  
                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Badges
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        if (recipe.prepTimeMinutes != null)
                          _buildBadge(
                            Icons.timer_outlined, 
                            '${recipe.prepTimeMinutes} mnt',
                            Colors.blue.shade100,
                            Colors.blue.shade900
                          ),
                        if (recipe.prepTimeMinutes != null && recipe.calories != null)
                          const SizedBox(width: 8),
                        if (recipe.calories != null)
                          _buildBadge(
                            Icons.local_fire_department_outlined, 
                            '${recipe.calories} kcal',
                            Colors.orange.shade100,
                            Colors.orange.shade900
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Content Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recipe.description != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        recipe.description!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBadge(IconData icon, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      color: AppTheme.accentLight,
      child: Icon(Icons.restaurant, size: 64, color: AppTheme.primary.withOpacity(0.3)),
    );
  }
}

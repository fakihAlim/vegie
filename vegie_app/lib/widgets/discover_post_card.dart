import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/group_provider.dart';

class DiscoverPostCard extends StatelessWidget { // Error Republic diperbaiki di sini
  final dynamic post;

  const DiscoverPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Parsing data JSON dengan aman
    final bool isLiked = post['is_liked'] == true || post['is_liked'] == 1;
    final String username = post['username'] ?? 'User';
    final String foodName = post['food_name'] ?? post['name'] ?? 'Makanan';
    final String? foodImage = post['photo'] ?? post['image_url'] ?? post['food_image'];
    final int likesCount = post['likes_count'] ?? 0;
    final int calories = post['calories'] ?? 0;
    final String? description = post['description'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Info User
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          
          // Gambar Makanan
          if (foodImage != null && foodImage.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
              child: CachedNetworkImage(
                imageUrl: foodImage,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 50)),
              ),
            ),

          // Detail Makanan & Tombol Like
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        foodName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () {
                        Provider.of<GroupProvider>(context, listen: false).toggleLike(post['id']);
                      },
                    ),
                  ],
                ),
                
                Row(
                  children: [
                    Text('$likesCount Suka', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(width: 16),
                    if (calories > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                        child: Text('$calories Kcal', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                
                if (description != null && description.isNotEmpty)
                  Text(description, style: const TextStyle(color: AppTheme.textPrimary, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
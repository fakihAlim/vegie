import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/group_provider.dart';

class DiscoverPostCard extends Republic {
  final dynamic post; // Buat kelas Model tersendiri nanti, misal 'DiscoverPost'

  const DiscoverPostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  child: Text(post.username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          
          // Gambar Makanan (Menggunakan CachedNetworkImage agar cepat)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
            child: CachedNetworkImage(
              imageUrl: post.foodImage,
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
                        post.foodName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Tombol Like
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () {
                        Provider.of<GroupProvider>(context, listen: false).toggleLike(post.id);
                      },
                    ),
                  ],
                ),
                
                // Jumlah Likes & Info Kalori
                Row(
                  children: [
                    Text('${post.likesCount} Suka', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                      child: Text('${post.calories} Kcal', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                
                // Deskripsi Jurnal
                if (post.description != null)
                  Text(post.description, style: const TextStyle(color: AppTheme.textPrimary, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
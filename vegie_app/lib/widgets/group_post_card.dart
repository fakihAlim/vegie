import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/group_post.dart';

class GroupPostCard extends StatelessWidget {
  final GroupPost post;

  const GroupPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(post.createdAt);
    final typeConfig = _getTypeConfig(post.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeConfig['borderColor'] as Color, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + time
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryLight,
                backgroundImage: post.userPhoto != null
                    ? NetworkImage(post.userPhoto!)
                    : null,
                child: post.userPhoto == null
                    ? Text(
                        post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (typeConfig['bgColor'] as Color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeConfig['icon'] as IconData, size: 14, color: typeConfig['iconColor'] as Color),
                    const SizedBox(width: 4),
                    Text(
                      typeConfig['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: typeConfig['iconColor'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          Text(
            post.content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.textPrimary,
              fontStyle: post.type == 'quote' ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getTypeConfig(String type) {
    switch (type) {
      case 'achievement':
        return {
          'icon': Icons.emoji_events_outlined,
          'label': 'Pencapaian',
          'bgColor': Colors.amber.shade50,
          'iconColor': Colors.amber.shade800,
          'borderColor': Colors.amber.shade100,
        };
      case 'quote':
        return {
          'icon': Icons.format_quote_outlined,
          'label': 'Kutipan',
          'bgColor': Colors.purple.shade50,
          'iconColor': Colors.purple.shade700,
          'borderColor': Colors.purple.shade100,
        };
      default:
        return {
          'icon': Icons.chat_bubble_outline,
          'label': 'Diskusi',
          'bgColor': Colors.blue.shade50,
          'iconColor': Colors.blue.shade700,
          'borderColor': Colors.grey.shade100,
        };
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

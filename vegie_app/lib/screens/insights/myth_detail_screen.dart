import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../config/theme.dart';
import '../../services/myth_fact_service.dart';

class MythDetailScreen extends StatelessWidget {
  final MythFact myth;

  const MythDetailScreen({super.key, required this.myth});

  List<String> _getDynamicTags(MythFact item) {
    final title = item.title.toLowerCase();
    final desc = item.description.toLowerCase();
    
    if (title.contains('protein') || desc.contains('protein')) {
      return ['Bioavailable', 'Fiber-Rich', 'Clean Energy'];
    }
    if (title.contains('besi') || desc.contains('besi') || title.contains('iron') || desc.contains('iron')) {
      return ['Zat Besi', 'Energi', 'Optimal'];
    }
    if (title.contains('kalsium') || desc.contains('kalsium') || title.contains('calcium') || desc.contains('calcium')) {
      return ['Kalsium', 'Tulang Sehat', 'Kekuatan'];
    }
    if (title.contains('lemak') || desc.contains('lemak') || title.contains('fat') || desc.contains('fat')) {
      return ['Lemak Sehat', 'Jantung', 'Bebas Kolesterol'];
    }
    return ['Nutrisi', 'Sehat', 'Sains'];
  }

  @override
  Widget build(BuildContext context) {
    final isMyth = myth.type == 'myth';
    final tags = _getDynamicTags(myth);

    final cardBg = isMyth ? const Color(0xFFFFF5F5) : const Color(0xFFE8F5E9);
    final cardBorder = isMyth ? const Color(0xFFFEE2E2) : const Color(0xFFC8E6C9);
    final watermarkIcon = isMyth ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
    final watermarkColor = isMyth ? Colors.red.shade700 : Colors.green.shade700;
    
    final badgeBg = isMyth ? const Color(0xFFFFEBEE) : const Color(0xFFC8E6C9);
    final badgeIcon = isMyth ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded;
    final badgeTextColor = isMyth ? Colors.red.shade700 : Colors.green.shade700;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Myth vs. Fact',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332), // Dark Green
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4332), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            const Text(
              "There are many stories floating around about plant-based diets. Let's peel back the layers and uncover the science behind your strength.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Card: The Myth
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Stack(
                children: [
                  // faint large Exclamation/Check mark watermark in the top right
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Opacity(
                      opacity: 0.15,
                      child: Icon(
                        watermarkIcon,
                        size: 64,
                        color: watermarkColor,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge: THE MYTH / THE FACT
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, color: badgeTextColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              isMyth ? 'THE MYTH' : 'THE FACT',
                              style: TextStyle(
                                color: badgeTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quote Text
                      Text(
                        '"${myth.title}"',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Section: The Truth Header
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isMyth ? 'The Truth' : 'The Facts',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332), // Dark Green
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card: The Truth details
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image (Optional: shown only if imageUrl is not null/empty)
                  if (myth.imageUrl != null && myth.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: myth.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 180,
                        color: AppTheme.accentLight,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: AppTheme.accentLight,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  
                  // Content padding
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description text
                        MarkdownBody(
                          data: myth.description,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: const TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF4B5563),
                              height: 1.6,
                            ),
                            h1: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                            h2: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                            h3: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2F0D9), // Light Green (matching mockup tag)
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: Color(0xFF548235), // Medium Green
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
}

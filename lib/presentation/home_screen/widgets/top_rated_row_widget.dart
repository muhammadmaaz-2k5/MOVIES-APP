import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';

class TopRatedRowWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const TopRatedRowWidget({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomImageWidget(
                imageUrl: item['posterUrl'] as String?,
                width: 64,
                height: 90,
                fit: BoxFit.cover,
                semanticLabel: item['posterSemanticLabel'] as String?,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE6E6F0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (item['genres'] as List<dynamic>? ?? []).join(' • '),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF888899),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: AppTheme.accent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item['year'] as String? ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF888899),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF888899), size: 20),
          ],
        ),
      ),
    );
  }
}

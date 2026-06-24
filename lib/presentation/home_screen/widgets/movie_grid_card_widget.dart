import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';

class MovieGridCardWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const MovieGridCardWidget({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomImageWidget(
                    imageUrl: item['posterUrl'] as String?,
                    fit: BoxFit.cover,
                    semanticLabel: item['posterSemanticLabel'] as String?,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: AppTheme.accent, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE6E6F0),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['year'] as String? ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF888899),
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

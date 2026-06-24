import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class DetailSimilarTitlesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onTap;

  const DetailSimilarTitlesWidget({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.movie_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Similar Titles',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
              final posterUrl = item['posterUrl'] as String? ?? '';

              return GestureDetector(
                onTap: () => onTap(item),
                child: SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            posterUrl.isNotEmpty
                                ? Image.network(
                                    posterUrl,
                                    width: 120,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    semanticLabel:
                                        item['posterSemanticLabel']
                                            as String? ??
                                        'Movie poster',
                                    errorBuilder: (_, __, ___) =>
                                        _SimilarPosterPlaceholder(),
                                  )
                                : _SimilarPosterPlaceholder(),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(191),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: AppTheme.accent,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title'] as String? ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarPosterPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 160,
      color: AppTheme.surfaceVariantDark,
      child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 32),
    );
  }
}

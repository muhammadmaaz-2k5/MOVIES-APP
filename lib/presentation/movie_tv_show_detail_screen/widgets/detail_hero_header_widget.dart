import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class DetailHeroHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const DetailHeroHeaderWidget({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final type   = item['type'] as String? ?? 'movie';
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;

    return SizedBox(
      height: 380,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Full-width backdrop ──────────────────────────────────────────
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomImageWidget(
                  imageUrl: item['backdropUrl'] as String?,
                  fit: BoxFit.cover,
                  semanticLabel: item['backdropSemanticLabel'] as String?,
                ),
                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(60),
                        Colors.black.withAlpha(100),
                        AppTheme.backgroundDark.withAlpha(220),
                        AppTheme.backgroundDark,
                      ],
                      stops: const [0.0, 0.4, 0.75, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Poster card (bottom-left) ──────────────────────────────────
          Positioned(
            bottom: 16,
            left: 20,
            child: _PosterCard(item: item),
          ),

          // ── Rating + type badge (bottom-right) ────────────────────────
          Positioned(
            bottom: 16,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type badge
                _TypeBadge(type: type),
                const SizedBox(height: 10),
                // Star rating pill
                _RatingPill(rating: rating),
                const SizedBox(height: 10),
                // Favourite button
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isFavorite
                          ? Colors.redAccent.withAlpha(230)
                          : Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFavorite
                            ? Colors.redAccent
                            : Colors.white.withAlpha(50),
                        width: 1.5,
                      ),
                      boxShadow: isFavorite
                          ? [
                              BoxShadow(
                                color: Colors.redAccent.withAlpha(100),
                                blurRadius: 12,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Poster card ──────────────────────────────────────────────────────────────

class _PosterCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _PosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.primary.withAlpha(50),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomImageWidget(
              imageUrl: item['posterUrl'] as String?,
              fit: BoxFit.cover,
              semanticLabel: item['posterSemanticLabel'] as String?,
            ),
            // Subtle inner border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withAlpha(30),
                  width: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Type badge ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isMovie = type == 'movie';
    final color   = isMovie ? AppTheme.primary : AppTheme.secondary;
    final label   = isMovie ? '🎬 Movie' : '📺 TV Show';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Rating pill ──────────────────────────────────────────────────────────────

class _RatingPill extends StatelessWidget {
  final double rating;
  const _RatingPill({required this.rating});

  Color get _color {
    if (rating >= 8.0) return const Color(0xFF00C875);
    if (rating >= 6.5) return AppTheme.accent;
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: _color, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

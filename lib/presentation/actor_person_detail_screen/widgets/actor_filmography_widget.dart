import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class ActorFilmographyWidget extends StatefulWidget {
  final List<Map<String, dynamic>> filmography;
  final void Function(Map<String, dynamic> item) onTap;

  const ActorFilmographyWidget({
    super.key,
    required this.filmography,
    required this.onTap,
  });

  @override
  State<ActorFilmographyWidget> createState() => _ActorFilmographyWidgetState();
}

class _ActorFilmographyWidgetState extends State<ActorFilmographyWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayList = _showAll
        ? widget.filmography
        : widget.filmography.take(4).toList();

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
                'Filmography',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.filmography.length} titles',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF888899),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...displayList.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final rating = (item['rating'] as num).toDouble();
          final ratingColor = AppTheme.ratingColor(rating);

          return _FilmographyRow(
            item: item,
            rating: rating,
            ratingColor: ratingColor,
            isLast: i == displayList.length - 1,
            onTap: () => widget.onTap(item),
          );
        }),
        if (widget.filmography.length > 4)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: GestureDetector(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2A3E)),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAll
                            ? 'Show Less'
                            : 'Show All ${widget.filmography.length} Titles',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _showAll
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilmographyRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final double rating;
  final Color ratingColor;
  final bool isLast;
  final VoidCallback onTap;

  const _FilmographyRow({
    required this.item,
    required this.rating,
    required this.ratingColor,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A3E)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: item['posterUrl'] as String,
                      width: 48,
                      height: 68,
                      fit: BoxFit.cover,
                      semanticLabel: item['posterSemanticLabel'] as String,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'as ${item['character']}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF888899),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StatusBadgeWidget(
                              label: item['year'] as String,
                              backgroundColor: AppTheme.surfaceVariantDark,
                              textColor: const Color(0xFF888899),
                              fontSize: 10,
                            ),
                            const SizedBox(width: 8),
                            StatusBadgeWidget(
                              label: item['type'] == 'movie'
                                  ? 'Movie'
                                  : 'TV Show',
                              backgroundColor: item['type'] == 'movie'
                                  ? AppTheme.primary.withAlpha(38)
                                  : AppTheme.secondary.withAlpha(38),
                              textColor: item['type'] == 'movie'
                                  ? AppTheme.primary
                                  : AppTheme.secondary,
                              fontSize: 10,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: ratingColor,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ratingColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(31),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 6),
      ],
    );
  }
}

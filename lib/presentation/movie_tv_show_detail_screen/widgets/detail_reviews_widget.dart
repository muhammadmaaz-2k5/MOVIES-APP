import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class DetailReviewsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;

  const DetailReviewsWidget({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.rate_review_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reviews',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${reviews.length} review${reviews.length != 1 ? 's' : ''}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF888899),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...reviews.take(2).map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final author = widget.review['author'] as String? ?? 'Anonymous';
    final content = widget.review['content'] as String? ?? '';
    final rating = widget.review['rating'];
    final avatarPath = widget.review['avatarPath'] as String?;
    final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
        ? (avatarPath.startsWith('http')
              ? avatarPath
              : 'https://image.tmdb.org/t/p/w45$avatarPath')
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withAlpha(60),
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          author.isNotEmpty ? author[0].toUpperCase() : '?',
                          style: GoogleFonts.outfit(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (rating != null)
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppTheme.accent,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$rating/10',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFFAAAAAA),
                height: 1.5,
              ),
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (content.length > 150) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show Less' : 'Read More',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

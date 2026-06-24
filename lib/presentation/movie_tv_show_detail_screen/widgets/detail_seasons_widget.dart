import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class DetailSeasonsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> seasons;

  const DetailSeasonsWidget({super.key, required this.seasons});

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.tv_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Seasons',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${seasons.length} season${seasons.length != 1 ? 's' : ''}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF888899),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final season = seasons[i];
              final posterPath = season['poster_path'] as String?;
              final posterUrl = posterPath != null && posterPath.isNotEmpty
                  ? 'https://image.tmdb.org/t/p/w185$posterPath'
                  : null;
              final episodeCount = season['episode_count'] as int? ?? 0;
              final airDate = season['air_date'] as String? ?? '';
              final year = airDate.length >= 4 ? airDate.substring(0, 4) : '';

              return SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: posterUrl != null
                          ? Image.network(
                              posterUrl,
                              width: 110,
                              height: 130,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _PlaceholderPoster(width: 110, height: 130),
                            )
                          : _PlaceholderPoster(width: 110, height: 130),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      season['name'] as String? ?? 'Season',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$episodeCount ep${year.isNotEmpty ? ' · $year' : ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF888899),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceholderPoster extends StatelessWidget {
  final double width;
  final double height;
  const _PlaceholderPoster({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceVariantDark,
      child: const Icon(Icons.tv_rounded, color: Colors.white24, size: 32),
    );
  }
}

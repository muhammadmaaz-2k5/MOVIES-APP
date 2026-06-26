import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class DetailSeasonsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> seasons;
  final int    showId;
  final String showTitle;

  const DetailSeasonsWidget({
    super.key,
    required this.seasons,
    required this.showId,
    required this.showTitle,
  });

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
              Text('Seasons',
                  style: GoogleFonts.outfit(
                      fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              Text('${seasons.length} season${seasons.length != 1 ? 's' : ''}',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF888899))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final season       = seasons[i];
              final posterPath   = season['poster_path'] as String?;
              final posterUrl    = posterPath != null && posterPath.isNotEmpty
                  ? 'https://image.tmdb.org/t/p/w185$posterPath'
                  : null;
              final episodeCount = season['episode_count'] as int? ?? 0;
              final airDate      = season['air_date']      as String? ?? '';
              final year         = airDate.length >= 4 ? airDate.substring(0, 4) : '';
              final seasonName   = season['name']          as String? ?? 'Season';
              final seasonNum    = season['season_number'] as int?    ?? i + 1;

              return GestureDetector(
                onTap: () => context.push(
                  AppRoutes.seasonDetailScreen,
                  extra: {
                    'showId':        showId,
                    'showTitle':     showTitle,
                    'seasonNumber':  seasonNum,
                    'seasonName':    seasonName,
                    'posterPath':    posterPath ?? '',
                    'overview':      season['overview'] ?? '',
                    'airDate':       airDate,
                    'episodeCount':  episodeCount,
                  },
                ),
                child: SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: posterUrl != null
                                ? Image.network(posterUrl,
                                    width: 110, height: 140, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _PlaceholderPoster(width: 110, height: 140))
                                : _PlaceholderPoster(width: 110, height: 140),
                          ),
                          // Play icon overlay
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withAlpha(140),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6, right: 6,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(220),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(seasonName,
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('$episodeCount ep${year.isNotEmpty ? ' · $year' : ''}',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: const Color(0xFF888899)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _PlaceholderPoster extends StatelessWidget {
  final double width;
  final double height;
  const _PlaceholderPoster({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      color: AppTheme.surfaceVariantDark,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.tv_rounded, color: Colors.white24, size: 32),
  );
}

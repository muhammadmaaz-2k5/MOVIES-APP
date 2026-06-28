import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

/// One themed section on the home screen
class _Section {
  final String emoji;
  final String title;
  final Map<String, dynamic> tmdbParams;
  _Section({required this.emoji, required this.title, required this.tmdbParams});
}

class HomeSectionsWidget extends StatefulWidget {
  const HomeSectionsWidget({super.key});

  @override
  State<HomeSectionsWidget> createState() => _HomeSectionsWidgetState();
}

class _HomeSectionsWidgetState extends State<HomeSectionsWidget> {
  final String _tmdbBase = AppConfig.tmdbProxyUrl;
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  

  late final Dio _dio;

  // All themed sections matching the spec
  static final List<_Section> _sections = [
    _Section(
      emoji: '🔥',
      title: 'Trending in Cinema',
      tmdbParams: {'sort_by': 'popularity.desc'},
    ),
    _Section(
      emoji: '🎞️',
      title: 'New Punjabi',
      tmdbParams: {'with_original_language': 'pa', 'sort_by': 'release_date.desc'},
    ),
    _Section(
      emoji: '🏆',
      title: 'Top 20 Movies',
      tmdbParams: {'sort_by': 'vote_average.desc', 'vote_count.gte': '500'},
    ),
    _Section(
      emoji: '🎬',
      title: 'Movies New Release',
      tmdbParams: {
        'sort_by': 'release_date.desc',
        'release_date.lte': DateTime.now().toIso8601String().substring(0, 10),
      },
    ),
    _Section(
      emoji: '👊',
      title: 'One-Person Army Action',
      tmdbParams: {'with_genres': '28', 'sort_by': 'popularity.desc'},
    ),
    _Section(
      emoji: '🪄',
      title: 'Fantastic Adventure Journey',
      tmdbParams: {'with_genres': '12,14', 'sort_by': 'popularity.desc'},
    ),
    _Section(
      emoji: '🧗',
      title: 'Adventure Unfolded',
      tmdbParams: {'with_genres': '12', 'sort_by': 'vote_average.desc', 'vote_count.gte': '200'},
    ),
    _Section(
      emoji: '🪦',
      title: 'Tomb Tales',
      tmdbParams: {'with_genres': '27,9648', 'sort_by': 'popularity.desc'},
    ),
    _Section(
      emoji: '🦸',
      title: 'Super Hero',
      tmdbParams: {'with_keywords': '9715', 'sort_by': 'popularity.desc'},
    ),
    _Section(
      emoji: '🔭',
      title: 'Sci-Fi Future',
      tmdbParams: {'with_genres': '878', 'sort_by': 'popularity.desc'},
    ),
    _Section(
      emoji: '💗',
      title: 'Bollywood Love Stories',
      tmdbParams: {'with_original_language': 'hi', 'with_genres': '10749', 'sort_by': 'popularity.desc'},
    ),
    _Section(
      emoji: '😀',
      title: 'Laugh Out Loud',
      tmdbParams: {'with_genres': '35', 'sort_by': 'popularity.desc'},
    ),
    _Section(
      emoji: '📈',
      title: 'Most Trending',
      tmdbParams: {'sort_by': 'popularity.desc', 'vote_count.gte': '100'},
    ),
  ];

  // Map sectionIndex → list of preview items
  final Map<int, List<Map<String, dynamic>>> _previews = {};
  final Map<int, bool> _loading = {};

  List<Map<String, dynamic>> _customExclusives = [];
  bool _isLoadingCustom = true;

  Future<void> _fetchCustomExclusives() async {
    if (!mounted) return;
    setState(() => _isLoadingCustom = true);
    try {
      final url = '${AppConfig.backendBaseUrl}/api/custom-content?limit=15';
      final resp = await _dio.get(url);
      final rawList = resp.data as List? ?? [];
      final items = rawList.map<Map<String, dynamic>>((r) {
        return {
          'id': r['id'] as int, // tmdb_id
          'custom_id': r['custom_id'] as int, // database auto-increment ID
          'title': r['title'] ?? 'Unknown',
          'type': r['type'] ?? 'movie',
          'posterUrl': r['posterUrl'] ?? '',
          'backdropUrl': r['backdropUrl'] ?? '',
          'rating': (r['rating'] as num?)?.toDouble() ?? 0.0,
          'year': r['year'] ?? '',
          'is_custom': true
        };
      }).toList();
      if (mounted) {
        setState(() {
          _customExclusives = items;
          _isLoadingCustom = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCustom = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _fetchCustomExclusives();
    // Stagger loads to avoid hammering the API
    for (int i = 0; i < _sections.length; i++) {
      Future.delayed(Duration(milliseconds: (i + 1) * 120), () => _fetchPreview(i));
    }
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchPreview(int index) async {
    if (!mounted) return;
    setState(() => _loading[index] = true);
    try {
      final params = <String, dynamic>{
        ..._sections[index].tmdbParams,
        'page': 1,
        'include_adult': false,
      };
      final resp = await _dio.get('$_tmdbBase/discover/movie',
          queryParameters: params);
      final results = (resp.data['results'] as List? ?? []).take(10);
      final items = results.map<Map<String, dynamic>>((r) {
        final posterPath = r['poster_path'] as String?;
        final backdropPath = r['backdrop_path'] as String?;
        final title = r['title'] ?? 'Unknown';
        final releaseDate = r['release_date'] ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        return {
          'id': r['id'],
          'title': title,
          'type': 'movie',
          'posterUrl': posterPath != null ? (posterPath.startsWith('http') ? posterPath : '$_imageBase/w342$posterPath') : '',
          'backdropUrl': backdropPath != null ? (backdropPath.startsWith('http') ? backdropPath : '$_imageBase/w780$backdropPath') : '',
          'posterSemanticLabel': 'Poster for $title',
          'backdropSemanticLabel': 'Backdrop for $title',
          'rating': (r['vote_average'] as num?)?.toDouble() ?? 0.0,
          'year': year,
          'genres': <String>[],
          'runtime': '',
          'overview': r['overview'] ?? '',
          'voteCount': r['vote_count'] ?? 0,
        };
      }).toList();
      if (mounted) {
        setState(() {
          _previews[index] = items;
          _loading[index] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading[index] = false);
    }
  }

  void _onMore(BuildContext context, _Section section) {
    context.push(AppRoutes.categorySectionScreen, extra: {
      'emoji': section.emoji,
      'title': section.title,
      'tmdbParams': section.tmdbParams,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isLoadingCustom)
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Custom Exclusives',
                          style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(height: 200, child: _buildSkeletonRow()),
              ],
            ),
          )
        else if (_customExclusives.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Custom Exclusives',
                          style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _customExclusives.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, j) =>
                        _SectionCard(item: _customExclusives[j]),
                  ),
                ),
              ],
            ),
          ),
        ...List.generate(_sections.length, (i) {
          final section = _sections[i];
          final items = _previews[i] ?? [];
          final isLoading = _loading[i] ?? true;

          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header with More button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(section.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          section.title,
                          style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _onMore(context, section),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primary.withAlpha(80)),
                          ),
                          child: Text(
                            'More',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Horizontal card strip
                SizedBox(
                  height: 200,
                  child: isLoading
                      ? _buildSkeletonRow()
                      : items.isEmpty
                          ? Center(
                              child: Text('No results',
                                  style: GoogleFonts.outfit(
                                      color: const Color(0xFF444466))))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, j) =>
                                  _SectionCard(item: items[j]),
                            ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSkeletonRow() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, __) => Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantDark,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ─── Card in the horizontal strip ─────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _SectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.movieTvShowDetailScreen, extra: item),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomImageWidget(
                      imageUrl: item['posterUrl'] as String?,
                      fit: BoxFit.cover,
                      semanticLabel: item['posterSemanticLabel'] as String?,
                    ),
                    if (rating > 0)
                      Positioned(
                        bottom: 6, right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  color: AppTheme.accent, size: 11),
                              const SizedBox(width: 2),
                              Text(rating.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['title'] as String? ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE6E6F0)),
            ),
            if ((item['year'] as String? ?? '').isNotEmpty)
              Text(item['year'] as String,
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: const Color(0xFF888899))),
          ],
        ),
      ),
    );
  }
}

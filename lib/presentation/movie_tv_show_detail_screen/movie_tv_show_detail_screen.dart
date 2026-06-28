import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../utils/app_actions.dart';
import './widgets/detail_bottom_action_bar_widget.dart';
import './widgets/detail_cast_section_widget.dart';
import './widgets/detail_genre_chips_widget.dart';
import './widgets/detail_hero_header_widget.dart';
import './widgets/detail_info_card_widget.dart';
import './widgets/detail_overview_widget.dart';
import './widgets/detail_reviews_widget.dart';
import './widgets/detail_seasons_widget.dart';
import './widgets/detail_similar_titles_widget.dart';
import './widgets/detail_stats_row_widget.dart';
import './widgets/detail_trailers_widget.dart';

class MovieTvShowDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? item;

  const MovieTvShowDetailScreen({super.key, this.item});

  @override
  State<MovieTvShowDetailScreen> createState() =>
      _MovieTvShowDetailScreenState();
}

class _MovieTvShowDetailScreenState extends State<MovieTvShowDetailScreen> {
  bool _isInWatchlist = false;
  bool _isFavorite = false;
  bool _isOverviewExpanded = false;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  // TMDB data
  bool _isLoading = true;
  Map<String, dynamic> _details = {};
  List<Map<String, dynamic>> _cast = [];
  List<Map<String, dynamic>> _similar = [];
  List<Map<String, dynamic>> _trailers = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _seasons = [];

  final String _tmdbBase = AppConfig.tmdbProxyUrl;
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  

  late final Dio _dio;

  Map<String, dynamic> get _item =>
      widget.item ??
      {
        'id': 693134,
        'title': 'Dune: Part Two',
        'type': 'movie',
        'rating': 7.7,
        'year': '2024',
        'genres': ['Sci-Fi', 'Adventure', 'Drama'],
        'runtime': '166 min',
        'overview':
            'Paul Atreides unites with the Fremen while on a path of revenge against the conspirators who destroyed his family.',
        'voteCount': 4821,
        'status': 'Released',
      };

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 200;
      if (show != _showAppBarTitle) {
        setState(() => _showAppBarTitle = show);
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final item = _item;
    final id = item['id'] as int? ?? 0;
    final type = item['type'] as String? ?? 'movie';
    final endpoint = type == 'tv' ? 'tv' : 'movie';

    try {
      final futures = await Future.wait([
        _dio.get('$_tmdbBase/$endpoint/$id'),
        _dio.get('$_tmdbBase/$endpoint/$id/credits'),
        _dio.get('$_tmdbBase/$endpoint/$id/videos'),
        _dio.get('$_tmdbBase/$endpoint/$id/similar'),
        _dio.get('$_tmdbBase/$endpoint/$id/reviews'),
      ]);

      final detailData = futures[0].data as Map<String, dynamic>;
      final creditsData = futures[1].data as Map<String, dynamic>;
      final videosData = futures[2].data as Map<String, dynamic>;
      final similarData = futures[3].data as Map<String, dynamic>;
      final reviewsData = futures[4].data as Map<String, dynamic>;

      // Cast
      final castList = (creditsData['cast'] as List? ?? []).take(15).map((c) {
        final profilePath = c['profile_path'] as String?;
        return {
          'id': c['id'],
          'name': c['name'] ?? '',
          'character': c['character'] ?? '',
          'photoUrl': profilePath != null ? '$_imageBase/w185$profilePath' : '',
          'semanticLabel': 'Profile photo of ${c['name'] ?? 'actor'}',
        };
      }).toList();

      // Trailers
      final videoList = (videosData['results'] as List? ?? [])
          .where(
            (v) =>
                v['site'] == 'YouTube' &&
                (v['type'] == 'Trailer' || v['type'] == 'Teaser'),
          )
          .take(5)
          .map(
            (v) => {
              'key': v['key'] ?? '',
              'name': v['name'] ?? 'Trailer',
              'type': v['type'] ?? 'Trailer',
            },
          )
          .toList();

      // Similar
      final similarList = (similarData['results'] as List? ?? []).take(10).map((
        s,
      ) {
        final posterPath = s['poster_path'] as String?;
        final title = s['title'] ?? s['name'] ?? 'Unknown';
        final releaseDate = s['release_date'] ?? s['first_air_date'] ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        return {
          'id': s['id'],
          'title': title,
          'type': type,
          'posterUrl': posterPath != null ? '$_imageBase/w342$posterPath' : '',
          'rating': (s['vote_average'] as num?)?.toDouble() ?? 0.0,
          'year': year,
          'genres': <String>[],
          'runtime': '',
          'overview': s['overview'] ?? '',
          'voteCount': s['vote_count'] ?? 0,
          'posterSemanticLabel': 'Movie poster for $title',
        };
      }).toList();

      // Reviews
      final reviewList = (reviewsData['results'] as List? ?? []).take(5).map((
        r,
      ) {
        final authorDetails = r['author_details'] as Map? ?? {};
        final avatarPath = authorDetails['avatar_path'] as String?;
        final cleanAvatar = avatarPath?.startsWith('/https') == true
            ? avatarPath!.substring(1)
            : avatarPath;
        return {
          'author': r['author'] ?? 'Anonymous',
          'content': r['content'] ?? '',
          'rating': authorDetails['rating'],
          'avatarPath': cleanAvatar ?? '',
        };
      }).toList();

      // Seasons (TV only)
      List<Map<String, dynamic>> seasonsList = [];
      if (type == 'tv') {
        seasonsList = (detailData['seasons'] as List? ?? [])
            .where((s) => (s['season_number'] as int? ?? 0) > 0)
            .map(
              (s) => {
                'name': s['name'] ?? 'Season',
                'season_number': s['season_number'],
                'episode_count': s['episode_count'],
                'air_date': s['air_date'] ?? '',
                'poster_path': s['poster_path'] ?? '',
                'overview': s['overview'] ?? '',
              },
            )
            .toList();
      }

      // Build enriched details map
      final backdropPath = detailData['backdrop_path'] as String?;
      final posterPath = detailData['poster_path'] as String?;
      final title = detailData['title'] ?? detailData['name'] ?? _item['title'];
      final releaseDate =
          detailData['release_date'] ?? detailData['first_air_date'] ?? '';
      final year = releaseDate.length >= 4
          ? releaseDate.substring(0, 4)
          : (_item['year'] ?? '');
      final runtime = detailData['runtime'] as int?;
      final episodeRuntime =
          (detailData['episode_run_time'] as List?)?.isNotEmpty == true
          ? (detailData['episode_run_time'] as List).first as int?
          : null;
      final runtimeStr = runtime != null
          ? '$runtime min'
          : (episodeRuntime != null ? '$episodeRuntime min/ep' : '');
      final genres = (detailData['genres'] as List? ?? [])
          .map((g) => g['name'] as String)
          .toList();
      final director =
          (creditsData['crew'] as List? ?? []).firstWhere(
                (c) => c['job'] == 'Director',
                orElse: () => <String, dynamic>{},
              )['name']
              as String?;
      final budget = detailData['budget'] as int?;
      final revenue = detailData['revenue'] as int?;
      final spokenLanguages = (detailData['spoken_languages'] as List? ?? []);
      final language = spokenLanguages.isNotEmpty
          ? spokenLanguages.first['english_name'] as String? ?? ''
          : '';

      final enriched = {
        ..._item,
        'id': detailData['id'] ?? _item['id'],
        'title': title,
        'backdropUrl': backdropPath != null
            ? '$_imageBase/w1280$backdropPath'
            : '',
        'posterUrl': posterPath != null ? '$_imageBase/w500$posterPath' : '',
        'backdropSemanticLabel': 'Backdrop image for $title',
        'posterSemanticLabel': 'Poster for $title',
        'rating':
            (detailData['vote_average'] as num?)?.toDouble() ??
            (_item['rating'] as num?)?.toDouble() ??
            0.0,
        'voteCount': detailData['vote_count'] ?? _item['voteCount'] ?? 0,
        'year': year,
        'genres': genres.isNotEmpty ? genres : (_item['genres'] ?? <String>[]),
        'runtime': runtimeStr.isNotEmpty
            ? runtimeStr
            : (_item['runtime'] ?? ''),
        'overview': detailData['overview'] ?? _item['overview'] ?? '',
        'status': detailData['status'] ?? _item['status'] ?? 'Released',
        'director': director,
        'language': language.isNotEmpty ? language : null,
        'budget': budget != null && budget > 0
            ? '\$${_formatMoney(budget)}'
            : null,
        'revenue': revenue != null && revenue > 0
            ? '\$${_formatMoney(revenue)}'
            : null,
        'tagline': detailData['tagline'] as String?,
        'numberOfSeasons': detailData['number_of_seasons'],
        'numberOfEpisodes': detailData['number_of_episodes'],
        'type': type,
      };

      if (mounted) {
        setState(() {
          _details = enriched;
          _cast = castList.cast<Map<String, dynamic>>();
          _trailers = videoList.cast<Map<String, dynamic>>();
          _similar = similarList.cast<Map<String, dynamic>>();
          _reviews = reviewList.cast<Map<String, dynamic>>();
          _seasons = seasonsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)}M';
    }
    return amount.toString();
  }

  Map<String, dynamic> get _displayItem =>
      _details.isNotEmpty ? _details : _item;

  @override
  Widget build(BuildContext context) {
    final item = _displayItem;
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: _buildDetailAppBar(item),
      body: _isLoading
          ? _buildLoadingState()
          : Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero header with TMDB backdrop + poster
                          DetailHeroHeaderWidget(
                            item: item,
                            isFavorite: _isFavorite,
                            onFavoriteToggle: () =>
                                setState(() => _isFavorite = !_isFavorite),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              item['title'] as String? ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if ((item['tagline'] as String?)?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                              child: Text(
                                '"${item['tagline']}"',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF888899),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.accent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${_formatVoteCount(item['voteCount'] as int? ?? 0)})',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: const Color(0xFF888899),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats row
                          DetailStatsRowWidget(item: item),
                          const SizedBox(height: 20),
                          // Genre chips
                          DetailGenreChipsWidget(
                            genres: (item['genres'] as List? ?? [])
                                .cast<String>(),
                          ),
                          const SizedBox(height: 20),
                          // Overview
                          DetailOverviewWidget(
                            overview: item['overview'] as String? ?? '',
                            isExpanded: _isOverviewExpanded,
                            onToggle: () => setState(
                              () => _isOverviewExpanded = !_isOverviewExpanded,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Trailers
                          if (_trailers.isNotEmpty) ...[
                            DetailTrailersWidget(trailers: _trailers),
                            const SizedBox(height: 24),
                          ],
                          // Cast
                          if (_cast.isNotEmpty) ...[
                            DetailCastSectionWidget(
                              cast: _cast,
                              onPersonTap: (person) => context.push(
                                AppRoutes.actorPersonDetailScreen,
                                extra: person,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Seasons (TV only)
                          if (_seasons.isNotEmpty) ...[
                            DetailSeasonsWidget(
                              seasons:   _seasons,
                              showId:    (item['id'] as int? ?? 0),
                              showTitle: (item['title'] as String? ?? ''),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Info card
                          DetailInfoCardWidget(item: item),
                          const SizedBox(height: 24),
                          // Reviews
                          if (_reviews.isNotEmpty) ...[
                            DetailReviewsWidget(reviews: _reviews),
                            const SizedBox(height: 24),
                          ],
                          // Similar Titles
                          if (_similar.isNotEmpty) ...[
                            DetailSimilarTitlesWidget(
                              items: _similar,
                              onTap: (similar) => context.push(
                                AppRoutes.movieTvShowDetailScreen,
                                extra: similar,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
                // Bottom action bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: DetailBottomActionBarWidget(
                    isInWatchlist: _isInWatchlist,
                    onWatchlistToggle: () =>
                        setState(() => _isInWatchlist = !_isInWatchlist),
                    item:    item,
                    seasons: _seasons,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Backdrop shimmer
          Container(
            height: 300,
            color: AppTheme.surfaceDark,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDetailAppBar(Map<String, dynamic> item) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: ClipRect(
        child: BackdropFilter(
          filter: _showAppBarTitle
              ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            color: _showAppBarTitle
                ? AppTheme.backgroundDark.withAlpha(204)
                : Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _CircleNavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: _showAppBarTitle ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          item['title'] as String? ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    _CircleNavButton(icon: Icons.share_rounded,
                        onTap: () => shareItem(item, context: context)),
                    const SizedBox(width: 8),
                    _CircleNavButton(icon: Icons.more_vert_rounded,
                        onTap: () => showMoreMenu(context, item)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatVoteCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _CircleNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(115),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(31)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

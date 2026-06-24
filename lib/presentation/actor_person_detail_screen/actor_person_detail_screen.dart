import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import './widgets/actor_bio_widget.dart';
import './widgets/actor_bottom_bar_widget.dart';
import './widgets/actor_filmography_widget.dart';
import './widgets/actor_hero_header_widget.dart';
import './widgets/actor_known_for_widget.dart';
import './widgets/actor_stats_row_widget.dart';

class ActorPersonDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? person;

  const ActorPersonDetailScreen({super.key, this.person});

  @override
  State<ActorPersonDetailScreen> createState() => _ActorPersonDetailScreenState();
}

class _ActorPersonDetailScreenState extends State<ActorPersonDetailScreen> {
  bool _isFollowing = false;
  bool _isBioExpanded = false;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  bool _isLoading = false;
  Map<String, dynamic> _enrichedPerson = {};
  List<Map<String, dynamic>> _knownFor = [];
  List<Map<String, dynamic>> _filmography = [];

  static const String _tmdbBase = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  static const String _bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1YmM0ZDAzZGU2MzY1YTBlZWY3ZDBhNGM0YTdkMDAyYiIsIm5iZiI6MTc1NTg2NzY0NS40ODg5OTk4LCJzdWIiOiI2OGE4NjlmZGI0NWEzOGEyNWMyNjEzYWEiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0._zPoKSHku3D5XAsfQ-L46MTKvJTs6cOB07Ij386z4OA';

  late final Dio _dio;

  Map<String, dynamic> get _fallbackPerson => widget.person ?? {
    'id': 1190668,
    'name': 'Timothée Chalamet',
    'photoUrl': 'https://image.tmdb.org/t/p/w185/BE2sdjpgsa2rNTFa66f7upkaOP.jpg',
    'semanticLabel': 'Actor profile photo',
    'department': 'Acting',
    'biography': '',
    'popularity': 0.0,
    'knownForDepartment': 'Acting',
  };

  Map<String, dynamic> get _displayPerson =>
      _enrichedPerson.isNotEmpty ? _enrichedPerson : _fallbackPerson;

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $_bearerToken'}));
    _scrollController.addListener(() {
      final show = _scrollController.offset > 180;
      if (show != _showAppBarTitle) setState(() => _showAppBarTitle = show);
    });
    _loadPersonData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _loadPersonData() async {
    final personId = _fallbackPerson['id'] as int?;
    if (personId == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _dio.get('$_tmdbBase/person/$personId'),
        _dio.get('$_tmdbBase/person/$personId/combined_credits'),
      ]);

      final detail = results[0].data as Map<String, dynamic>;
      final credits = results[1].data as Map<String, dynamic>;

      final profilePath = detail['profile_path'] as String?;
      final birthday = detail['birthday'] as String? ?? '';
      final birthplace = detail['place_of_birth'] as String? ?? '';

      final castList = (credits['cast'] as List? ?? []);

      // Known for: top 6 by vote_count
      final knownForList = castList
          .where((c) => c['poster_path'] != null)
          .toList()
        ..sort((a, b) => ((b['vote_count'] as num?) ?? 0)
            .compareTo((a['vote_count'] as num?) ?? 0));

      final knownFor = knownForList.take(6).map((c) {
        final poster = c['poster_path'] as String?;
        final title = c['title'] ?? c['name'] ?? 'Unknown';
        final type = c['media_type'] as String? ?? (c['title'] != null ? 'movie' : 'tv');
        final releaseDate = c['release_date'] ?? c['first_air_date'] ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        return <String, dynamic>{
          'id': c['id'],
          'title': title,
          'type': type,
          'posterUrl': poster != null ? '$_imageBase/w342$poster' : '',
          'rating': (c['vote_average'] as num?)?.toDouble() ?? 0.0,
          'year': year,
          'genres': <String>[],
          'runtime': '',
          'overview': c['overview'] ?? '',
          'voteCount': c['vote_count'] ?? 0,
          'posterSemanticLabel': 'Poster for $title',
        };
      }).toList();

      // Filmography: sorted by date descending
      final filmList = castList
          .where((c) => (c['release_date'] ?? c['first_air_date'] ?? '').isNotEmpty)
          .toList()
        ..sort((a, b) {
          final dateA = a['release_date'] ?? a['first_air_date'] ?? '';
          final dateB = b['release_date'] ?? b['first_air_date'] ?? '';
          return (dateB as String).compareTo(dateA as String);
        });

      final filmography = filmList.take(20).map((c) {
        final poster = c['poster_path'] as String?;
        final title = c['title'] ?? c['name'] ?? 'Unknown';
        final type = c['media_type'] as String? ?? (c['title'] != null ? 'movie' : 'tv');
        final releaseDate = c['release_date'] ?? c['first_air_date'] ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        return <String, dynamic>{
          'id': c['id'],
          'title': title,
          'year': year,
          'character': c['character'] ?? '',
          'type': type,
          'rating': (c['vote_average'] as num?)?.toDouble() ?? 0.0,
          'posterUrl': poster != null ? '$_imageBase/w185$poster' : '',
          'posterSemanticLabel': 'Thumbnail for $title',
          'genres': <String>[],
          'runtime': '',
          'overview': c['overview'] ?? '',
          'voteCount': c['vote_count'] ?? 0,
        };
      }).toList();

      final enriched = <String, dynamic>{
        ..._fallbackPerson,
        'id': detail['id'],
        'name': detail['name'] ?? _fallbackPerson['name'],
        'photoUrl': profilePath != null
            ? '$_imageBase/w400$profilePath'
            : (_fallbackPerson['photoUrl'] ?? ''),
        'backdropUrl': profilePath != null ? '$_imageBase/original$profilePath' : '',
        'semanticLabel': 'Profile photo of ${detail['name'] ?? ''}',
        'backdropSemanticLabel': 'Backdrop for ${detail['name'] ?? ''}',
        'department': detail['known_for_department'] ?? 'Acting',
        'birthday': birthday,
        'birthplace': birthplace,
        'biography': detail['biography'] ?? '',
        'popularity': (detail['popularity'] as num?)?.toDouble() ?? 0.0,
        'knownForDepartment': detail['known_for_department'] ?? 'Acting',
      };

      if (mounted) {
        setState(() {
          _enrichedPerson = enriched;
          _knownFor = knownFor;
          _filmography = filmography;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = _displayPerson;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: _buildActorAppBar(person),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ActorHeroHeaderWidget(person: person),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              person['name'] as String? ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(
                              child: StatusBadgeWidget(
                                label: person['department'] as String? ?? 'Acting',
                                backgroundColor: AppTheme.primary.withAlpha(51),
                                textColor: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ActorStatsRowWidget(person: person),
                          const SizedBox(height: 20),
                          if ((person['biography'] as String? ?? '').isNotEmpty)
                            ActorBioWidget(
                              bio: person['biography'] as String,
                              isExpanded: _isBioExpanded,
                              onToggle: () =>
                                  setState(() => _isBioExpanded = !_isBioExpanded),
                            ),
                          if (_knownFor.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            ActorKnownForWidget(
                              items: _knownFor,
                              onTap: (item) => context.push(
                                AppRoutes.movieTvShowDetailScreen,
                                extra: item,
                              ),
                            ),
                          ],
                          if (_filmography.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            ActorFilmographyWidget(
                              filmography: _filmography,
                              onTap: (item) => context.push(
                                AppRoutes.movieTvShowDetailScreen,
                                extra: item,
                              ),
                            ),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ActorBottomBarWidget(
                    isFollowing: _isFollowing,
                    onFollowToggle: () =>
                        setState(() => _isFollowing = !_isFollowing),
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildActorAppBar(Map<String, dynamic> person) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _CircleBackButton(onTap: () => context.pop()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: _showAppBarTitle ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          person['name'] as String? ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    _CircleBackButton(icon: Icons.share_rounded, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBackButton({
    this.icon = Icons.arrow_back_ios_new_rounded,
    required this.onTap,
  });

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

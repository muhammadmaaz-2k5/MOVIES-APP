import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../search_screen/filter_sheet.dart';
import '../search_screen/search_filters.dart';
import './widgets/featured_banner_widget.dart';
import './widgets/movie_grid_card_widget.dart';
import './widgets/home_sections_widget.dart';
import './widgets/section_header_widget.dart';
import './widgets/trending_card_widget.dart';

// ─── Category definition ──────────────────────────────────────────────────────

class _Category {
  final String label;
  final String emoji;
  // TMDB discover params for trending row
  final Map<String, dynamic> trendingParams;
  // TMDB discover params for popular grid
  final Map<String, dynamic> popularParams;
  // media type: 'movie' | 'tv' | 'all'
  final String mediaType;

  const _Category({
    required this.label,
    required this.emoji,
    required this.trendingParams,
    required this.popularParams,
    this.mediaType = 'movie',
  });
}

// ─── Home screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarBlurred = false;
  SearchFilters _activeFilters = const SearchFilters();

  static const String _tmdbBase = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  static const String _bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1YmM0ZDAzZGU2MzY1YTBlZWY3ZDBhNGM0YTdkMDAyYiIsIm5iZiI6MTc1NTg2NzY0NS40ODg5OTk4LCJzdWIiOiI2OGE4NjlmZGI0NWEzOGEyNWMyNjEzYWEiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0._zPoKSHku3D5XAsfQ-L46MTKvJTs6cOB07Ij386z4OA';

  late final Dio _dio;

  // Categories — each fetches its own TMDB data
  static const List<_Category> _categories = [
    _Category(label: 'All',        emoji: '🌐', mediaType: 'all',
      trendingParams: {},
      popularParams:  {'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Hollywood',  emoji: '🇺🇸', mediaType: 'movie',
      trendingParams: {'with_original_language': 'en', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'en', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Bollywood',  emoji: '🇮🇳', mediaType: 'movie',
      trendingParams: {'with_original_language': 'hi', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'hi', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Punjabi',    emoji: '🎵', mediaType: 'movie',
      trendingParams: {'with_original_language': 'pa', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'pa', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'KDrama',     emoji: '🇰🇷', mediaType: 'tv',
      trendingParams: {'with_original_language': 'ko', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'ko', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Anime',      emoji: '🇯🇵', mediaType: 'tv',
      trendingParams: {'with_original_language': 'ja', 'with_genres': '16', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'ja', 'with_genres': '16', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Turkish',    emoji: '🇹🇷', mediaType: 'tv',
      trendingParams: {'with_original_language': 'tr', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'tr', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Arabic',     emoji: '🇸🇦', mediaType: 'movie',
      trendingParams: {'with_original_language': 'ar', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'ar', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Chinese',    emoji: '🇨🇳', mediaType: 'movie',
      trendingParams: {'with_original_language': 'zh', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'zh', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Spanish',    emoji: '🇪🇸', mediaType: 'movie',
      trendingParams: {'with_original_language': 'es', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'es', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'French',     emoji: '🇫🇷', mediaType: 'movie',
      trendingParams: {'with_original_language': 'fr', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'fr', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Tamil',      emoji: '🎞️', mediaType: 'movie',
      trendingParams: {'with_original_language': 'ta', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'ta', 'sort_by': 'popularity.desc', 'include_adult': false}),
    _Category(label: 'Telugu',     emoji: '🎥', mediaType: 'movie',
      trendingParams: {'with_original_language': 'te', 'sort_by': 'popularity.desc', 'include_adult': false},
      popularParams:  {'with_original_language': 'te', 'sort_by': 'popularity.desc', 'include_adult': false}),
  ];

  int _selectedCategory = 0;

  // Per-category cached data: index → list
  final Map<int, List<Map<String, dynamic>>> _trendingByCategory = {};
  final Map<int, List<Map<String, dynamic>>> _popularByCategory  = {};
  final Map<int, bool> _loadingTrending = {};
  final Map<int, bool> _loadingPopular  = {};

  // Featured banner uses the "All" trending (category 0)
  List<Map<String, dynamic>> get _featured =>
      (_trendingByCategory[0] ?? []).take(3).toList();

  static String get _monthStart {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  }

  static String get _monthEnd {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month + 1, 0);
    return '${last.year}-${last.month.toString().padLeft(2, '0')}-${last.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $_bearerToken'}));
    _scrollController.addListener(() {
      final shouldBlur = _scrollController.offset > 10;
      if (shouldBlur != _isAppBarBlurred) {
        setState(() => _isAppBarBlurred = shouldBlur);
      }
    });
    // Pre-fetch All (index 0)
    _fetchCategory(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchCategory(int idx) async {
    if ((_loadingTrending[idx] ?? false) || (_loadingPopular[idx] ?? false)) return;
    await Future.wait([_fetchTrending(idx), _fetchPopular(idx)]);
  }

  Future<void> _fetchTrending(int idx) async {
    if (!mounted) return;
    setState(() => _loadingTrending[idx] = true);
    final cat = _categories[idx];
    try {
      List<Map<String, dynamic>> items;
      if (cat.mediaType == 'all') {
        // All: use /trending/all/week
        final resp = await _dio.get('$_tmdbBase/trending/all/week',
            queryParameters: {'page': 1});
        items = _parseItems(resp.data['results'] as List? ?? [], defaultType: 'movie');
      } else {
        final endpoint = cat.mediaType == 'tv' ? 'tv' : 'movie';
        final resp = await _dio.get('$_tmdbBase/discover/$endpoint',
            queryParameters: {...cat.trendingParams, 'page': 1});
        items = _parseItems(resp.data['results'] as List? ?? [],
            defaultType: cat.mediaType);
      }
      if (mounted) {
        setState(() {
          _trendingByCategory[idx] = items;
          _loadingTrending[idx] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTrending[idx] = false);
    }
  }

  Future<void> _fetchPopular(int idx) async {
    if (!mounted) return;
    setState(() => _loadingPopular[idx] = true);
    final cat = _categories[idx];
    try {
      List<Map<String, dynamic>> items;
      if (cat.mediaType == 'all') {
        // All popular: discover movies released this month
        final resp = await _dio.get('$_tmdbBase/discover/movie', queryParameters: {
          ...cat.popularParams,
          'release_date.gte': _monthStart,
          'release_date.lte': _monthEnd,
          'page': 1,
        });
        items = _parseItems(resp.data['results'] as List? ?? [], defaultType: 'movie');
        // Fallback to all-time popular if month is sparse
        if (items.length < 4) {
          final fb = await _dio.get('$_tmdbBase/discover/movie',
              queryParameters: {...cat.popularParams, 'page': 1});
          items = _parseItems(fb.data['results'] as List? ?? [], defaultType: 'movie');
        }
      } else {
        final endpoint = cat.mediaType == 'tv' ? 'tv' : 'movie';
        final resp = await _dio.get('$_tmdbBase/discover/$endpoint',
            queryParameters: {...cat.popularParams, 'page': 1});
        items = _parseItems(resp.data['results'] as List? ?? [],
            defaultType: cat.mediaType);
      }
      if (mounted) {
        setState(() {
          _popularByCategory[idx] = items.take(8).toList();
          _loadingPopular[idx] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPopular[idx] = false);
    }
  }

  List<Map<String, dynamic>> _parseItems(List raw, {required String defaultType}) {
    return raw.map<Map<String, dynamic>>((r) {
      final mediaType    = r['media_type']    as String? ?? defaultType;
      final posterPath   = r['poster_path']   as String?;
      final backdropPath = r['backdrop_path'] as String?;
      final title        = (r['title'] ?? r['name'] ?? 'Unknown') as String;
      final dateRaw      = (r['release_date'] ?? r['first_air_date'] ?? '') as String;
      final year         = dateRaw.length >= 4 ? dateRaw.substring(0, 4) : '';
      return {
        'id':          r['id'],
        'title':       title,
        'type':        mediaType == 'tv' ? 'tv' : 'movie',
        'posterUrl':   posterPath   != null ? '$_imageBase/w342$posterPath'   : '',
        'backdropUrl': backdropPath != null ? '$_imageBase/w780$backdropPath' : '',
        'posterSemanticLabel':   'Poster for $title',
        'backdropSemanticLabel': 'Backdrop for $title',
        'rating':   (r['vote_average'] as num?)?.toDouble() ?? 0.0,
        'year':      year,
        'genres':   <String>[],
        'runtime':  '',
        'overview':  r['overview'] ?? '',
        'voteCount': r['vote_count'] ?? 0,
      };
    }).toList();
  }

  void _onCategorySelected(int idx) {
    setState(() => _selectedCategory = idx);
    // Lazy-fetch if not yet loaded
    if ((_trendingByCategory[idx] == null) || (_popularByCategory[idx] == null)) {
      _fetchCategory(idx);
    }
  }

  Future<void> _onRefresh() async {
    // Clear cache for current category and re-fetch
    _trendingByCategory.remove(_selectedCategory);
    _popularByCategory.remove(_selectedCategory);
    await _fetchCategory(_selectedCategory);
    // Also refresh "All" for banner
    if (_selectedCategory != 0) {
      _trendingByCategory.remove(0);
      await _fetchTrending(0);
    }
  }

  List<Map<String, dynamic>> get _currentTrending =>
      _trendingByCategory[_selectedCategory] ?? [];

  List<Map<String, dynamic>> get _currentPopular =>
      _popularByCategory[_selectedCategory] ?? [];

  bool get _isTrendingLoading => _loadingTrending[_selectedCategory] ?? true;
  bool get _isPopularLoading  => _loadingPopular[_selectedCategory]  ?? true;

  String get _trendingLabel {
    final cat = _categories[_selectedCategory];
    if (cat.label == 'All')       return 'Trending This Week';
    if (cat.label == 'KDrama')    return 'Trending KDramas';
    return 'Trending ${cat.label}';
  }

  String get _popularLabel {
    final cat = _categories[_selectedCategory];
    if (cat.label == 'All')       return 'Popular This Month';
    if (cat.label == 'KDrama')    return 'Popular KDramas';
    return 'Popular ${cat.label}';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surfaceDark,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: kToolbarHeight + 56),
                  // ── Featured banner (always from "All" trending) ──
                  if (_featured.isNotEmpty)
                    FeaturedBannerWidget(
                      items: _featured,
                      onTap: (item) => context.push(
                        AppRoutes.movieTvShowDetailScreen,
                        extra: item,
                      ),
                    )
                  else if (_loadingTrending[0] ?? true)
                    const SizedBox(height: 200),
                  const SizedBox(height: 20),
                  // ── Category chips ──
                  _CategoryChipsRow(
                    categories: _categories,
                    selectedIndex: _selectedCategory,
                    onSelected: _onCategorySelected,
                  ),
                  const SizedBox(height: 24),
                  // ── Trending row ──
                  SectionHeaderWidget(
                    title: _trendingLabel,
                    iconName: 'local_fire_department_rounded',
                    onSeeMore: _currentTrending.isEmpty ? null : () => context.push(
                      AppRoutes.seeAllScreen,
                      extra: {'title': _trendingLabel, 'items': _currentTrending},
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isTrendingLoading)
                    _HorizontalSkeleton()
                  else if (_currentTrending.isEmpty)
                    _EmptySection(label: _trendingLabel)
                  else
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _currentTrending.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final item = _currentTrending[i];
                          return TrendingCardWidget(
                            item: item,
                            index: i,
                            onTap: () => context.push(
                              AppRoutes.movieTvShowDetailScreen,
                              extra: item,
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 28),
                  // ── Popular grid ──
                  SectionHeaderWidget(
                    title: _popularLabel,
                    iconName: 'trending_up_rounded',
                    onSeeMore: _currentPopular.isEmpty ? null : () => context.push(
                      AppRoutes.seeAllScreen,
                      extra: {'title': _popularLabel, 'items': _currentPopular},
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isPopularLoading)
                    _GridSkeleton()
                  else if (_currentPopular.isEmpty)
                    _EmptySection(label: _popularLabel)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 3 : 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _currentPopular.length,
                        itemBuilder: (context, i) {
                          final item = _currentPopular[i];
                          return MovieGridCardWidget(
                            item: item,
                            onTap: () => context.push(
                              AppRoutes.movieTvShowDetailScreen,
                              extra: item,
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 28),
                  // ── Browse by Language banner ──
                  _LanguageBrowseBanner(
                    onTap: () => context.push(AppRoutes.languageBrowseScreen),
                  ),
                  const SizedBox(height: 28),
                  const HomeSectionsWidget(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _isAppBarBlurred ? 20 : 0,
            sigmaY: _isAppBarBlurred ? 20 : 0,
          ),
          child: Container(
            color: _isAppBarBlurred
                ? AppTheme.backgroundDark.withAlpha(191)
                : Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'CineTrack',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    _GlassIconButton(
                      iconName: 'language_rounded',
                      onTap: () => context.push(AppRoutes.languageBrowseScreen),
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      iconName: 'search_rounded',
                      onTap: () => context.push(AppRoutes.searchScreen),
                    ),
                    const SizedBox(width: 8),
                    _GlassFilterButton(
                      activeCount: _activeFilters.activeCount,
                      onTap: () async {
                        final result = await showModalBottomSheet<SearchFilters>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => FilterSheet(current: _activeFilters),
                        );
                        if (result != null) setState(() => _activeFilters = result);
                      },
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      iconName: 'download_rounded',
                      onTap: () => context.push(AppRoutes.downloadsScreen),
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(iconName: 'notifications_none_rounded', onTap: () {}),
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

// ─── Skeletons ────────────────────────────────────────────────────────────────

class _HorizontalSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 140,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantDark,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantDark,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String label;
  const _EmptySection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Text(
          'No results found for $label',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF888899),
          ),
        ),
      ),
    );
  }
}

// ─── Glass buttons ────────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final String iconName;
  final VoidCallback onTap;
  const _GlassIconButton({required this.iconName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: CustomIconWidget(iconName: iconName, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GlassFilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  const _GlassFilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withAlpha(40) : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.primary.withAlpha(120) : Colors.white.withAlpha(26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 16,
                color: isActive ? AppTheme.primary : Colors.white),
            if (isActive) ...[
              const SizedBox(width: 4),
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text('$activeCount',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Category chips ───────────────────────────────────────────────────────────

class _CategoryChipsRow extends StatelessWidget {
  final List<_Category> categories;
  final int selectedIndex;
  final void Function(int) onSelected;

  const _CategoryChipsRow({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat      = categories[i];
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent.withAlpha(220) : AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.accent : const Color(0xFF444466),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    cat.label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? Colors.black : const Color(0xFF888899),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Language browse banner ───────────────────────────────────────────────────

class _LanguageBrowseBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _LanguageBrowseBanner({required this.onTap});

  static const _previews = ['🇺🇸', '🇮🇳', '🇰🇷', '🇯🇵', '🇨🇳', '🇹🇷', '🇸🇦', '🇪🇸'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F3460),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(20), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withAlpha(100)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.language_rounded,
                        color: AppTheme.primary, size: 14),
                    const SizedBox(width: 5),
                    Text('20+ Languages', style: GoogleFonts.outfit(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
                  ]),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white54, size: 14),
              ]),
              const SizedBox(height: 10),
              Text('Browse by Language',
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text('Hollywood · Bollywood · KDrama · Anime · Turkish · Arabic & more',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.white.withAlpha(160), height: 1.4),
                  maxLines: 2),
              const SizedBox(height: 14),
              // Flag preview row
              Row(children: [
                ..._previews.map((f) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: Center(child: Text(f,
                      style: const TextStyle(fontSize: 16))),
                )),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Browse All', style: GoogleFonts.outfit(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

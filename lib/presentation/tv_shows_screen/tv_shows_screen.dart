import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../search_screen/search_filters.dart';
import '../shared/media_filter_sheet.dart';

class TvShowsScreen extends StatefulWidget {
  const TvShowsScreen({super.key});

  @override
  State<TvShowsScreen> createState() => _TvShowsScreenState();
}

class _TvShowsScreenState extends State<TvShowsScreen>
    with SingleTickerProviderStateMixin {
  final String _tmdbBase = AppConfig.tmdbProxyUrl;
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  

  late final Dio _dio;
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Active filters
  SearchFilters _filters = const SearchFilters();

  static const List<_TvTab> _tabs = [
    _TvTab(label: 'All', sortBy: 'popularity.desc', genreId: null),
    _TvTab(label: '🔥 Trending', sortBy: 'popularity.desc', genreId: null, trending: true),
    _TvTab(label: '⭐ Top Rated', sortBy: 'vote_average.desc', genreId: null),
    _TvTab(label: '🎭 Drama', sortBy: 'popularity.desc', genreId: 18),
    _TvTab(label: '😂 Comedy', sortBy: 'popularity.desc', genreId: 35),
    _TvTab(label: '🔪 Crime', sortBy: 'popularity.desc', genreId: 80),
    _TvTab(label: '🌌 Sci-Fi', sortBy: 'popularity.desc', genreId: 10765),
    _TvTab(label: '👨‍👩‍👧 Family', sortBy: 'popularity.desc', genreId: 10751),
    _TvTab(label: '🔮 Mystery', sortBy: 'popularity.desc', genreId: 9648),
    _TvTab(label: '💗 Romance', sortBy: 'popularity.desc', genreId: 10749),
    _TvTab(label: '📺 Reality', sortBy: 'popularity.desc', genreId: 10764),
    _TvTab(label: '🗺️ Documentary', sortBy: 'popularity.desc', genreId: 99),
  ];

  final Map<int, List<Map<String, dynamic>>> _itemsByTab = {};
  final Map<int, int> _pageByTab = {};
  final Map<int, int> _totalPagesByTab = {};
  final Map<int, bool> _loadingByTab = {};
  final Map<int, bool> _fetchingMoreByTab = {};
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final idx = _tabController.index;
        setState(() => _currentTab = idx);
        if ((_itemsByTab[idx] ?? []).isEmpty) _fetchPage(idx, 1);
      }
    });
    _fetchPage(0, 1);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _dio.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 400 &&
        !(_fetchingMoreByTab[_currentTab] ?? false)) {
      final page = _pageByTab[_currentTab] ?? 1;
      final total = _totalPagesByTab[_currentTab] ?? 1;
      if (page < total) _fetchPage(_currentTab, page + 1);
    }
  }

  Future<void> _fetchPage(int tabIdx, int page) async {
    final tab = _tabs[tabIdx];
    if (page == 1) {
      setState(() => _loadingByTab[tabIdx] = true);
    } else {
      setState(() => _fetchingMoreByTab[tabIdx] = true);
    }

    try {
      Future<List<Map<String, dynamic>>> customFuture;
      if (page == 1) {
        final Map<String, dynamic> customParams = {'type': 'tv'};
        if (tab.genreId != null) {
          customParams['genre'] = tab.genreId;
        } else if (_filters.genre != 'All') {
          final gid = SearchFilters.genreIds[_filters.genre];
          if (gid != null) customParams['genre'] = gid;
        }
        customFuture = _fetchCustomContent(customParams);
      } else {
        customFuture = Future.value(<Map<String, dynamic>>[]);
      }

      Future<Response> tmdbFuture;
      if (tab.trending && _filters.isDefault) {
        tmdbFuture = _dio.get('$_tmdbBase/trending/tv/week',
            queryParameters: {'page': page});
      } else {
        tmdbFuture = _dio.get('$_tmdbBase/discover/tv',
            queryParameters: _buildParams(tabIdx, page));
      }

      final results = await Future.wait([tmdbFuture, customFuture]);
      final resp = results[0] as Response;
      final customItems = results[1] as List<Map<String, dynamic>>;

      final tmdbResults = (resp.data['results'] as List? ?? []);
      final totalPages = resp.data['total_pages'] as int? ?? 1;

      List<Map<String, dynamic>> items = tmdbResults.map<Map<String, dynamic>>((r) {
        final posterPath = r['poster_path'] as String?;
        final backdropPath = r['backdrop_path'] as String?;
        final title = r['name'] ?? r['title'] ?? 'Unknown';
        final airDate = r['first_air_date'] ?? '';
        final year = airDate.length >= 4 ? airDate.substring(0, 4) : '';
        return {
          'id': r['id'],
          'title': title,
          'type': 'tv',
          'posterUrl': posterPath != null ? '$_imageBase/w342$posterPath' : '',
          'backdropUrl': backdropPath != null ? '$_imageBase/w780$backdropPath' : '',
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

      if (page == 1 && customItems.isNotEmpty) {
        final customTmdbIds = customItems.map((c) => c['id'] as int).toSet();
        items = items.where((item) => !customTmdbIds.contains(item['id'] as int)).toList();
        items = [...customItems, ...items];
      }

      if (mounted) {
        setState(() {
          if (page == 1) {
            _itemsByTab[tabIdx] = items;
          } else {
            _itemsByTab[tabIdx] = [...(_itemsByTab[tabIdx] ?? []), ...items];
          }
          _pageByTab[tabIdx] = page;
          _totalPagesByTab[tabIdx] = totalPages;
          _loadingByTab[tabIdx] = false;
          _fetchingMoreByTab[tabIdx] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingByTab[tabIdx] = false;
          _fetchingMoreByTab[tabIdx] = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCustomContent(Map<String, dynamic> params) async {
    try {
      final url = '${AppConfig.backendBaseUrl}/api/custom-content';
      final resp = await _dio.get(url, queryParameters: params);
      final rawList = resp.data as List? ?? [];
      return rawList.map<Map<String, dynamic>>((r) {
        return {
          'id': r['id'] as int, // tmdb_id
          'custom_id': r['custom_id'] as int,
          'title': r['title'] ?? 'Unknown',
          'type': r['type'] ?? 'tv',
          'posterUrl': r['posterUrl'] ?? '',
          'backdropUrl': r['backdropUrl'] ?? '',
          'rating': (r['rating'] as num?)?.toDouble() ?? 0.0,
          'year': r['year'] ?? '',
          'is_custom': true
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _onRefresh() async {
    _itemsByTab[_currentTab] = [];
    await _fetchPage(_currentTab, 1);
  }

  Map<String, dynamic> _buildParams(int tabIdx, int page) {
    final tab    = _tabs[tabIdx];
    final params = <String, dynamic>{
      'page': page, 'include_adult': false,
    };

    // sort
    switch (_filters.sortBy) {
      case 'Rating':
        params['sort_by'] = 'vote_average.desc';
        params['vote_count.gte'] = 200;
      case 'Latest':
        params['sort_by'] = 'first_air_date.desc';
      default:
        params['sort_by'] = tab.sortBy;
        if (tab.sortBy.contains('vote_average')) params['vote_count.gte'] = 200;
    }

    // genre: tab overrides filter genre when tab has own genre
    if (tab.genreId != null) {
      params['with_genres'] = tab.genreId;
    } else if (_filters.genre != 'All') {
      final gid = tvGenreIdForName(_filters.genre)
          ?? SearchFilters.genreIds[_filters.genre];
      if (gid != null) params['with_genres'] = gid;
    }

    // country
    if (_filters.country != 'All' && _filters.country != 'Other') {
      final code = SearchFilters.countryCodes[_filters.country];
      if (code != null) params['with_origin_country'] = code;
    }

    // language
    if (_filters.language != 'All') {
      final code = SearchFilters.languageCodes[_filters.language];
      if (code != null) params['with_original_language'] = code;
    }

    // year
    final yr = _filters.year;
    if (yr != 'All' && yr != 'Other') {
      if (yr.endsWith('s')) {
        final decade = int.tryParse(yr.replaceAll('s', ''));
        if (decade != null) {
          params['first_air_date.gte'] = '$decade-01-01';
          params['first_air_date.lte'] = '${decade + 9}-12-31';
        }
      } else {
        params['first_air_date.gte'] = '$yr-01-01';
        params['first_air_date.lte'] = '$yr-12-31';
      }
    }

    return params;
  }

  void _applyFilters(SearchFilters f) {
    setState(() {
      _filters = f;
      _itemsByTab.clear();
      _pageByTab.clear();
      _totalPagesByTab.clear();
    });
    _fetchPage(_currentTab, 1);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaFilterSheet(current: _filters, mediaType: 'tv'),
    );
    if (result != null) _applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Container(
            color: AppTheme.surfaceDark,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF888899),
              labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w400),
              dividerColor: const Color(0xFF2A2A3E),
              tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
            ),
          ),
          if (!_filters.isDefault)
            _TvActiveFilterStrip(
              filters: _filters,
              onClear: () => _applyFilters(const SearchFilters()),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (i) => _buildTabContent(i)),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final active = _filters.activeCount;
    return AppBar(
      backgroundColor: AppTheme.surfaceDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Text('📺 ', style: TextStyle(fontSize: 20)),
          Text('TV Shows',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _openFilters,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active > 0 ? AppTheme.primary.withAlpha(30) : AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: active > 0 ? AppTheme.primary : const Color(0xFF444466)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.tune_rounded, size: 15,
                  color: active > 0 ? AppTheme.primary : const Color(0xFF888899)),
              const SizedBox(width: 5),
              Text(active > 0 ? 'Filters ($active)' : 'Filters',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: active > 0 ? FontWeight.w600 : FontWeight.w400,
                      color: active > 0 ? AppTheme.primary : const Color(0xFF888899))),
            ]),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFF2A2A3E)),
      ),
    );
  }

  Widget _buildTabContent(int tabIdx) {
    final isLoading = _loadingByTab[tabIdx] ?? true;
    final isFetchingMore = _fetchingMoreByTab[tabIdx] ?? false;
    final items = _itemsByTab[tabIdx] ?? [];
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off_rounded, color: const Color(0xFF444466), size: 56),
            const SizedBox(height: 16),
            Text('No shows found',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            if (!_filters.isDefault) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _applyFilters(const SearchFilters()),
                child: Text('Clear filters',
                    style: GoogleFonts.outfit(
                        color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.surfaceDark,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        // Only the active tab uses the shared scroll controller for infinite scroll
        controller: tabIdx == _currentTab ? _scrollController : null,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 3,
                childAspectRatio: 0.58,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _TvCard(item: items[i]),
                childCount: items.length,
              ),
            ),
          ),
          if (isFetchingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2),
                ),
              ),
            ),
          // Auto-load sentinel — invisible item at bottom
          if (!isFetchingMore &&
              (_pageByTab[tabIdx] ?? 1) < (_totalPagesByTab[tabIdx] ?? 1))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      final page = _pageByTab[tabIdx] ?? 1;
                      _fetchPage(tabIdx, page + 1);
                    },
                    icon: const Icon(Icons.expand_more_rounded,
                        color: AppTheme.primary),
                    label: Text('Load more',
                        style: GoogleFonts.outfit(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ─── TV card ──────────────────────────────────────────────────────────────────

class _TvCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TvCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.movieTvShowDetailScreen, extra: item),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomImageWidget(
                    imageUrl: item['posterUrl'] as String?,
                    fit: BoxFit.cover,
                    semanticLabel: item['posterSemanticLabel'] as String?,
                  ),
                  // Gradient at bottom
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(200),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // TV badge
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('TV',
                          style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  // Rating
                  if (rating > 0)
                    Positioned(
                      bottom: 6, right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: AppTheme.accent, size: 11),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE6E6F0))),
                  if ((item['year'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item['year'] as String,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: const Color(0xFF888899))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab model ────────────────────────────────────────────────────────────────

class _TvTab {
  final String label;
  final String sortBy;
  final int? genreId;
  final bool trending;

  const _TvTab({
    required this.label,
    required this.sortBy,
    required this.genreId,
    this.trending = false,
  });
}

// ─── Active filter strip ──────────────────────────────────────────────────────

class _TvActiveFilterStrip extends StatelessWidget {
  final SearchFilters filters;
  final VoidCallback onClear;
  const _TvActiveFilterStrip({required this.filters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filters.genre    != 'All') chips.add(filters.genre);
    if (filters.country  != 'All') chips.add(filters.country);
    if (filters.year     != 'All') chips.add(filters.year);
    if (filters.language != 'All') chips.add(filters.language);
    if (filters.sortBy   != 'Hottest') chips.add('↕ ${filters.sortBy}');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      color: AppTheme.surfaceDark,
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((c) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withAlpha(80)),
                ),
                child: Text(c, style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary)),
              )).toList(),
            ),
          ),
        ),
        GestureDetector(
          onTap: onClear,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('Clear', style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: const Color(0xFF888899))),
          ),
        ),
      ]),
    );
  }
}

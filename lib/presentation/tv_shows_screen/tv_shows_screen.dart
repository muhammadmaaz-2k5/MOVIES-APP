import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class TvShowsScreen extends StatefulWidget {
  const TvShowsScreen({super.key});

  @override
  State<TvShowsScreen> createState() => _TvShowsScreenState();
}

class _TvShowsScreenState extends State<TvShowsScreen>
    with SingleTickerProviderStateMixin {
  static const String _tmdbBase = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  static const String _bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1YmM0ZDAzZGU2MzY1YTBlZWY3ZDBhNGM0YTdkMDAyYiIsIm5iZiI6MTc1NTg2NzY0NS40ODg5OTk4LCJzdWIiOiI2OGE4NjlmZGI0NWEzOGEyNWMyNjEzYWEiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0._zPoKSHku3D5XAsfQ-L46MTKvJTs6cOB07Ij386z4OA';

  late final Dio _dio;
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

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
    _dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $_bearerToken'}));
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
      Response resp;
      if (tab.trending) {
        resp = await _dio.get('$_tmdbBase/trending/tv/week',
            queryParameters: {'page': page});
      } else {
        final params = <String, dynamic>{
          'sort_by': tab.sortBy,
          'page': page,
          'include_adult': false,
          'vote_count.gte': tab.sortBy.contains('vote_average') ? 200 : 0,
        };
        if (tab.genreId != null) params['with_genres'] = tab.genreId;
        resp = await _dio.get('$_tmdbBase/discover/tv', queryParameters: params);
      }

      final results = (resp.data['results'] as List? ?? []);
      final totalPages = resp.data['total_pages'] as int? ?? 1;

      final items = results.map<Map<String, dynamic>>((r) {
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

  Future<void> _onRefresh() async {
    _itemsByTab[_currentTab] = [];
    await _fetchPage(_currentTab, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Genre/type tab bar
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
              labelStyle: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w400),
              dividerColor: const Color(0xFF2A2A3E),
              tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
            ),
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
    return AppBar(
      backgroundColor: AppTheme.surfaceDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Text('📺 ', style: TextStyle(fontSize: 20)),
          Text('Watch TV Series',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
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

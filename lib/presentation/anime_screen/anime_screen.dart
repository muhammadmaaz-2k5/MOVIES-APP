import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

// ─── Filter model ─────────────────────────────────────────────────────────────

class AnimeFilters {
  final String country;
  final String year;
  final String sortBy;

  const AnimeFilters({
    this.country = 'All',
    this.year = 'All',
    this.sortBy = 'ForYou',
  });

  bool get isDefault =>
      country == 'All' && year == 'All' && sortBy == 'ForYou';

  int get activeCount {
    int c = 0;
    if (country != 'All') c++;
    if (year != 'All') c++;
    if (sortBy != 'ForYou') c++;
    return c;
  }

  AnimeFilters copyWith({String? country, String? year, String? sortBy}) =>
      AnimeFilters(
        country: country ?? this.country,
        year: year ?? this.year,
        sortBy: sortBy ?? this.sortBy,
      );

  static const List<String> countries = [
    'All',
    'United States',
    'United Kingdom',
    'France',
    'Japan',
    'China',
    'Korea',
    'Other',
  ];

  static const List<String> years = [
    'All',
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2010s',
    '2000s',
    '1990s',
    '1980s',
    'Other',
  ];

  static const List<String> sortOptions = [
    'ForYou',
    'Hottest',
    'Latest',
    'Rating',
  ];

  static const Map<String, String> countryCodes = {
    'United States': 'US',
    'United Kingdom': 'GB',
    'France': 'FR',
    'Japan': 'JP',
    'China': 'CN',
    'Korea': 'KR',
  };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnimeScreen extends StatefulWidget {
  const AnimeScreen({super.key});

  @override
  State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen>
    with SingleTickerProviderStateMixin {
  static const String _tmdbBase = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  static const String _bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1YmM0ZDAzZGU2MzY1YTBlZWY3ZDBhNGM0YTdkMDAyYiIsIm5iZiI6MTc1NTg2NzY0NS40ODg5OTk4LCJzdWIiOiI2OGE4NjlmZGI0NWEzOGEyNWMyNjEzYWEiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0._zPoKSHku3D5XAsfQ-L46MTKvJTs6cOB07Ij386z4OA';

  late final Dio _dio;
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  AnimeFilters _filters = const AnimeFilters();
  bool _filterSheetOpen = false;

  // Two content types: Movies and Shows
  static const List<_AnimeTab> _tabs = [
    _AnimeTab(label: '🎬 Movies', type: 'movie'),
    _AnimeTab(label: '📺 Shows', type: 'tv'),
  ];

  final Map<int, List<Map<String, dynamic>>> _items = {};
  final Map<int, int> _page = {};
  final Map<int, int> _totalPages = {};
  final Map<int, bool> _loading = {};
  final Map<int, bool> _loadingMore = {};
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
        if ((_items[idx] ?? []).isEmpty) _fetchPage(idx, 1);
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
        !(_loadingMore[_currentTab] ?? false)) {
      final p = _page[_currentTab] ?? 1;
      final total = _totalPages[_currentTab] ?? 1;
      if (p < total) _fetchPage(_currentTab, p + 1);
    }
  }

  Map<String, dynamic> _buildParams(int tabIdx, int page) {
    final type = _tabs[tabIdx].type;
    final params = <String, dynamic>{
      'page': page,
      'include_adult': false,
      // Anime = animation genre (16) + Japanese origin is the classic combo,
      // but we allow country filter to override origin language.
      'with_genres': '16',
      'with_keywords': '210024', // TMDB keyword id for "anime"
    };

    // Country → origin country
    final country = _filters.country;
    if (country != 'All' && country != 'Other') {
      final code = AnimeFilters.countryCodes[country];
      if (code != null) {
        if (type == 'movie') {
          params['with_origin_country'] = code;
        } else {
          params['with_origin_country'] = code;
        }
      }
    }

    // Year
    final year = _filters.year;
    if (year != 'All' && year != 'Other') {
      if (year.endsWith('s')) {
        // decade
        final decade = int.tryParse(year.replaceAll('s', ''));
        if (decade != null) {
          final dateField = type == 'movie' ? 'release_date' : 'first_air_date';
          params['$dateField.gte'] = '$decade-01-01';
          params['$dateField.lte'] = '${decade + 9}-12-31';
        }
      } else {
        final dateField = type == 'movie' ? 'release_date' : 'first_air_date';
        params['$dateField.gte'] = '$year-01-01';
        params['$dateField.lte'] = '$year-12-31';
      }
    }

    // Sort
    switch (_filters.sortBy) {
      case 'Rating':
        params['sort_by'] = 'vote_average.desc';
        params['vote_count.gte'] = 100;
      case 'Latest':
        params['sort_by'] = type == 'movie'
            ? 'release_date.desc'
            : 'first_air_date.desc';
      case 'Hottest':
      case 'ForYou':
      default:
        params['sort_by'] = 'popularity.desc';
    }

    return params;
  }

  Future<void> _fetchPage(int tabIdx, int page) async {
    final type = _tabs[tabIdx].type;
    if (page == 1) {
      setState(() => _loading[tabIdx] = true);
    } else {
      setState(() => _loadingMore[tabIdx] = true);
    }
    try {
      final resp = await _dio.get(
        '$_tmdbBase/discover/$type',
        queryParameters: _buildParams(tabIdx, page),
      );
      final results = (resp.data['results'] as List? ?? []);
      final totalPages = resp.data['total_pages'] as int? ?? 1;

      final items = results.map<Map<String, dynamic>>((r) {
        final posterPath = r['poster_path'] as String?;
        final backdropPath = r['backdrop_path'] as String?;
        final title = (r['title'] ?? r['name'] ?? 'Unknown') as String;
        final dateRaw = (r['release_date'] ?? r['first_air_date'] ?? '') as String;
        final year2 = dateRaw.length >= 4 ? dateRaw.substring(0, 4) : '';
        return {
          'id': r['id'],
          'title': title,
          'type': type,
          'posterUrl': posterPath != null ? '$_imageBase/w342$posterPath' : '',
          'backdropUrl': backdropPath != null ? '$_imageBase/w780$backdropPath' : '',
          'posterSemanticLabel': 'Anime poster for $title',
          'backdropSemanticLabel': 'Anime backdrop for $title',
          'rating': (r['vote_average'] as num?)?.toDouble() ?? 0.0,
          'year': year2,
          'genres': <String>[],
          'runtime': '',
          'overview': r['overview'] ?? '',
          'voteCount': r['vote_count'] ?? 0,
        };
      }).toList();

      if (mounted) {
        setState(() {
          if (page == 1) {
            _items[tabIdx] = items;
          } else {
            _items[tabIdx] = [...(_items[tabIdx] ?? []), ...items];
          }
          _page[tabIdx] = page;
          _totalPages[tabIdx] = totalPages;
          _loading[tabIdx] = false;
          _loadingMore[tabIdx] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading[tabIdx] = false;
          _loadingMore[tabIdx] = false;
        });
      }
    }
  }

  void _applyFilters(AnimeFilters f) {
    setState(() {
      _filters = f;
      _items.clear();
      _page.clear();
      _totalPages.clear();
    });
    _fetchPage(_currentTab, 1);
  }

  Future<void> _onRefresh() async {
    _items[_currentTab] = [];
    await _fetchPage(_currentTab, 1);
  }

  Future<void> _openFilterSheet() async {
    if (_filterSheetOpen) return;
    _filterSheetOpen = true;
    final result = await showModalBottomSheet<AnimeFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnimeFilterSheet(current: _filters),
    );
    _filterSheetOpen = false;
    if (result != null) _applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppTheme.surfaceDark,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFF6B9D),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF888899),
              labelStyle:
                  GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w400),
              dividerColor: const Color(0xFF2A2A3E),
              tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
            ),
          ),
          // Active filter strip
          if (!_filters.isDefault) _ActiveFilterStrip(filters: _filters, onClear: () => _applyFilters(const AnimeFilters())),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (i) => _buildContent(i)),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final activeCount = _filters.activeCount;
    return AppBar(
      backgroundColor: AppTheme.surfaceDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Text('⛩️ ', style: TextStyle(fontSize: 20)),
          Text(
            'Anime',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _openFilterSheet,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: activeCount > 0
                  ? const Color(0xFFFF6B9D).withAlpha(30)
                  : AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: activeCount > 0
                    ? const Color(0xFFFF6B9D)
                    : const Color(0xFF444466),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded,
                    size: 15,
                    color: activeCount > 0
                        ? const Color(0xFFFF6B9D)
                        : const Color(0xFF888899)),
                const SizedBox(width: 5),
                Text(
                  activeCount > 0 ? 'Filters ($activeCount)' : 'Filters',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: activeCount > 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: activeCount > 0
                        ? const Color(0xFFFF6B9D)
                        : const Color(0xFF888899),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFF2A2A3E)),
      ),
    );
  }

  Widget _buildContent(int idx) {
    final isLoading = _loading[idx] ?? true;
    final isFetchingMore = _loadingMore[idx] ?? false;
    final items = _items[idx] ?? [];
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (isLoading) {
      return Center(
          child:
              CircularProgressIndicator(color: const Color(0xFFFF6B9D)));
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎌', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No anime found',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Try adjusting your filters',
                style: GoogleFonts.outfit(
                    fontSize: 14, color: const Color(0xFF888899))),
            if (!_filters.isDefault) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _applyFilters(const AnimeFilters()),
                child: Text('Clear filters',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF6B9D))),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFF6B9D),
      backgroundColor: AppTheme.surfaceDark,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: idx == _currentTab ? _scrollController : null,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 3,
                childAspectRatio: 0.58,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _AnimeCard(item: items[i]),
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
                      color: const Color(0xFFFF6B9D), strokeWidth: 2),
                ),
              ),
            ),
          if (!isFetchingMore &&
              (_page[idx] ?? 1) < (_totalPages[idx] ?? 1))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      final p = _page[idx] ?? 1;
                      _fetchPage(idx, p + 1);
                    },
                    icon: const Icon(Icons.expand_more_rounded,
                        color: Color(0xFFFF6B9D)),
                    label: Text('Load more',
                        style: GoogleFonts.outfit(
                            color: const Color(0xFFFF6B9D),
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

// ─── Active filter strip ──────────────────────────────────────────────────────

class _ActiveFilterStrip extends StatelessWidget {
  final AnimeFilters filters;
  final VoidCallback onClear;
  const _ActiveFilterStrip({required this.filters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filters.country != 'All') chips.add(filters.country);
    if (filters.year != 'All') chips.add(filters.year);
    if (filters.sortBy != 'ForYou') chips.add(filters.sortBy);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips
                    .map((c) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF6B9D).withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFFF6B9D)
                                    .withAlpha(80)),
                          ),
                          child: Text(c,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFFF6B9D))),
                        ))
                    .toList(),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('Clear',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF888899))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Anime card ───────────────────────────────────────────────────────────────

class _AnimeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _AnimeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    final type = item['type'] as String;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.movieTvShowDetailScreen, extra: item),
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
                  // Bottom gradient
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
                  // Type badge
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: type == 'movie'
                            ? const Color(0xFFFF6B9D).withAlpha(200)
                            : const Color(0xFF9B59B6).withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type == 'movie' ? 'MOVIE' : 'SHOW',
                        style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  // Rating
                  if (rating > 0)
                    Positioned(
                      bottom: 6, right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 11),
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
                  Text(
                    item['title'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE6E6F0)),
                  ),
                  if ((item['year'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['year'] as String,
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: const Color(0xFF888899)),
                    ),
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

class _AnimeTab {
  final String label;
  final String type; // 'movie' | 'tv'
  const _AnimeTab({required this.label, required this.type});
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _AnimeFilterSheet extends StatefulWidget {
  final AnimeFilters current;
  const _AnimeFilterSheet({required this.current});

  @override
  State<_AnimeFilterSheet> createState() => _AnimeFilterSheetState();
}

class _AnimeFilterSheetState extends State<_AnimeFilterSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late AnimeFilters _filters;

  static const _tabs = ['Country', 'Year', 'Sort by'];

  @override
  void initState() {
    super.initState();
    _filters = widget.current;
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _handle(),
          _header(),
          _tabBar(),
          Expanded(child: _tabViews()),
          _footer(context),
        ],
      ),
    );
  }

  Widget _handle() => Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF444466),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            Text('Anime Filters',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _filters = const AnimeFilters()),
              child: Text('Reset',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF6B9D))),
            ),
          ],
        ),
      );

  Widget _tabBar() => TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFFFF6B9D),
        indicatorWeight: 2,
        labelColor: const Color(0xFFFF6B9D),
        unselectedLabelColor: const Color(0xFF888899),
        labelStyle:
            GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w400),
        dividerColor: const Color(0xFF2A2A3E),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      );

  Widget _tabViews() => TabBarView(
        controller: _tab,
        children: [
          _optionGrid(
            options: AnimeFilters.countries,
            selected: _filters.country,
            onTap: (v) =>
                setState(() => _filters = _filters.copyWith(country: v)),
          ),
          _optionGrid(
            options: AnimeFilters.years,
            selected: _filters.year,
            onTap: (v) =>
                setState(() => _filters = _filters.copyWith(year: v)),
          ),
          _optionGrid(
            options: AnimeFilters.sortOptions,
            selected: _filters.sortBy,
            onTap: (v) =>
                setState(() => _filters = _filters.copyWith(sortBy: v)),
          ),
        ],
      );

  Widget _optionGrid({
    required List<String> options,
    required String selected,
    required void Function(String) onTap,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: options.length,
      itemBuilder: (_, i) => _chip(options[i], selected, onTap),
    );
  }

  Widget _chip(String label, String selected, void Function(String) onTap) {
    final isSelected = label == selected;
    return GestureDetector(
      onTap: () => onTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B9D)
              : AppTheme.surfaceVariantDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B9D)
                : const Color(0xFF444466),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFFCCCCDD),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _filters),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text('Apply Filters',
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

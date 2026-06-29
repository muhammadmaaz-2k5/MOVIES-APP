import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import 'filter_sheet.dart';
import 'search_filters.dart';

// ─── Popular quick search tags ────────────────────────────────────────────────

const List<String> _kSuggestions = [
  '🔥 Trending',
  '🦸 Avengers',
  '🧙 Harry Potter',
  '🚀 Interstellar',
  '🕷️ Spider-Man',
  '🦁 The Lion King',
  '🎭 Breaking Bad',
  '🤖 Transformers',
  '🧟 The Walking Dead',
  '🧊 Game of Thrones',
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool _isLoading = false;
  String _query = '';
  List<Map<String, dynamic>> _results = [];
  String _selectedType = 'all';
  SearchFilters _filters = const SearchFilters();

  final String _tmdbBase = AppConfig.tmdbProxyUrl;
  static const String _imageBase = 'https://image.tmdb.org/t/p';

  late final Dio _dio;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  static const List<_TypeOption> _typeFilters = [
    _TypeOption(label: 'All', icon: Icons.apps_rounded, value: 'all'),
    _TypeOption(label: 'Movies', icon: Icons.movie_outlined, value: 'movie'),
    _TypeOption(label: 'TV Shows', icon: Icons.tv_outlined, value: 'tv'),
    _TypeOption(
      label: 'People',
      icon: Icons.person_outline_rounded,
      value: 'person',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    _dio.close();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _query = '';
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(value.trim()),
    );
  }

  Map<String, dynamic> _buildQueryParams(String q) {
    final params = <String, dynamic>{
      'query': q,
      'include_adult': false,
      'page': 1,
    };
    if (_filters.genre != 'All') {
      final gid = SearchFilters.genreIds[_filters.genre];
      if (gid != null) params['with_genres'] = gid;
    }
    if (_filters.country != 'All' && _filters.country != 'Other') {
      final code = SearchFilters.countryCodes[_filters.country];
      if (code != null) params['region'] = code;
    }
    if (_filters.language != 'All') {
      final code = SearchFilters.languageCodes[_filters.language];
      if (code != null) params['language'] = code;
    }
    if (_filters.year != 'All' && _filters.year != 'Other') {
      if (!_filters.year.contains('s')) {
        params['year'] = _filters.year;
      }
    }
    return params;
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _isLoading = true;
    });
    _animCtrl.reset();
    try {
      final endpoint = _selectedType == 'all'
          ? 'search/multi'
          : 'search/$_selectedType';
      final resp = await _dio.get(
        '$_tmdbBase/$endpoint',
        queryParameters: _buildQueryParams(q),
      );

      var items = (resp.data['results'] as List? ?? []).map((r) {
        final mediaType = r['media_type'] as String? ?? _selectedType;
        final isPerson = mediaType == 'person';
        final posterPath = isPerson
            ? r['profile_path'] as String?
            : r['poster_path'] as String?;
        final title = r['title'] ?? r['name'] ?? 'Unknown';
        final releaseDate = r['release_date'] ?? r['first_air_date'] ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        return <String, dynamic>{
          'id': r['id'],
          'title': title,
          'type': isPerson ? 'person' : (mediaType == 'tv' ? 'tv' : 'movie'),
          'posterUrl': posterPath != null
              ? (posterPath.startsWith('http')
                    ? posterPath
                    : '$_imageBase/w342$posterPath')
              : '',
          'posterSemanticLabel': 'Search result for $title',
          'rating': (r['vote_average'] as num?)?.toDouble() ?? 0.0,
          'year': year,
          'genres': <String>[],
          'runtime': '',
          'overview': r['overview'] ?? '',
          'voteCount': r['vote_count'] ?? 0,
          'popularity': (r['popularity'] as num?)?.toDouble() ?? 0.0,
          'photoUrl': isPerson && posterPath != null
              ? '$_imageBase/w185$posterPath'
              : '',
          'semanticLabel': 'Photo of $title',
          'department': r['known_for_department'] ?? 'Acting',
          'biography': '',
          'knownForDepartment': r['known_for_department'] ?? 'Acting',
        };
      }).toList();

      // Client-side sort
      switch (_filters.sortBy) {
        case 'Rating':
          items.sort(
            (a, b) =>
                ((b['rating'] as double).compareTo(a['rating'] as double)),
          );
        case 'Latest':
          items.sort(
            (a, b) => (b['year'] as String).compareTo(a['year'] as String),
          );
        default:
          items.sort(
            (a, b) => ((b['popularity'] as double).compareTo(
              a['popularity'] as double,
            )),
          );
      }

      if (mounted) {
        setState(() {
          _results = items;
          _isLoading = false;
        });
        _animCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      _results = [];
    });
    if (_query.isNotEmpty) _search(_query);
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(current: _filters),
    );
    if (result != null) {
      setState(() => _filters = result);
      if (_query.isNotEmpty) _search(_query);
    }
  }

  void _onResultTap(Map<String, dynamic> item) {
    final type = item['type'] as String;
    if (type == 'person') {
      context.push(AppRoutes.actorPersonDetailScreen, extra: item);
    } else {
      context.push(AppRoutes.movieTvShowDetailScreen, extra: item);
    }
  }

  void _onSuggestionTap(String suggestion) {
    // Strip emoji prefix
    final q = suggestion
        .replaceAll(
          RegExp(
            r'^[\p{Emoji_Presentation}\p{Extended_Pictographic}\s]+',
            unicode: true,
          ),
          '',
        )
        .trim();
    final clean = q.isNotEmpty ? q : suggestion;
    _controller.text = clean;
    _onQueryChanged(clean);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildTypeFilterRow(),
            const _Divider(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ─── Header with animated search bar ────────────────────────────────────────

  Widget _buildSearchHeader() {
    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF444466)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Search input
          Expanded(
            child: _SearchInputBox(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              onClear: () {
                _controller.clear();
                _onQueryChanged('');
              },
            ),
          ),
          const SizedBox(width: 10),
          // Filter button
          _FilterBtn(
            activeCount: _filters.activeCount,
            onTap: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  // ─── Type chips row ──────────────────────────────────────────────────────────

  Widget _buildTypeFilterRow() {
    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.only(bottom: 10),
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _typeFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _typeFilters[i];
          final selected = _selectedType == f.value;
          return GestureDetector(
            onTap: () => _onTypeChanged(f.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? AppTheme.primary : const Color(0xFF444466),
                  width: 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f.icon,
                    size: 13,
                    color: selected ? Colors.white : const Color(0xFF888899),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    f.label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? Colors.white : const Color(0xFF888899),
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

  // ─── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_query.isEmpty) return _buildEmptyState();
    if (_isLoading) return _buildLoadingState();
    if (_results.isEmpty) return _buildNoResults();
    return _buildResults();
  }

  // ─── Empty state with suggestion chips ──────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 40,
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'What are you looking for?',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Search movies, shows, actors and more',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF888899),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Popular Searches',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFBBBBCC),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kSuggestions.map((s) {
              return GestureDetector(
                onTap: () => _onSuggestionTap(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF444466)),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (!_filters.isDefault) ...[
            const SizedBox(height: 24),
            _ActiveFiltersRow(
              filters: _filters,
              onClear: () => setState(() => _filters = const SearchFilters()),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Loading skeleton ────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _SkeletonTile(),
    );
  }

  // ─── No results ──────────────────────────────────────────────────────────────

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: Color(0xFF444466),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No results for',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF888899),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"$_query"',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Try a different spelling or search term',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF888899),
              ),
              textAlign: TextAlign.center,
            ),
            if (!_filters.isDefault) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() => _filters = const SearchFilters());
                  _search(_query);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Clear filters & retry',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Results list ────────────────────────────────────────────────────────────

  Widget _buildResults() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          // Result count + active filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_results.length} result${_results.length == 1 ? '' : 's'} for "$_query"',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF888899),
                    ),
                  ),
                ),
                if (!_filters.isDefault)
                  GestureDetector(
                    onTap: () {
                      setState(() => _filters = const SearchFilters());
                      _search(_query);
                    },
                    child: Text(
                      'Clear filters',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!_filters.isDefault)
            _ActiveFiltersRow(
              filters: _filters,
              onClear: () {
                setState(() => _filters = const SearchFilters());
                _search(_query);
              },
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _SearchResultTile(
                item: _results[i],
                onTap: () => _onResultTap(_results[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search input box ─────────────────────────────────────────────────────────

class _SearchInputBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchInputBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchInputBox> createState() => _SearchInputBoxState();
}

class _SearchInputBoxState extends State<_SearchInputBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? AppTheme.primary.withValues(alpha: 0.7)
              : const Color(0xFF444466),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            color: _focused ? AppTheme.primary : const Color(0xFF888899),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
              cursorColor: AppTheme.primary,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search movies, shows, people…',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFF888899),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: widget.controller.text.isNotEmpty
                ? GestureDetector(
                    key: const ValueKey('clear'),
                    onTap: widget.onClear,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF444466),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}

// ─── Filter button ────────────────────────────────────────────────────────────

class _FilterBtn extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterBtn({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withValues(alpha: 0.15)
              : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.6)
                : const Color(0xFF444466),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 20,
              color: active ? AppTheme.primary : const Color(0xFF888899),
            ),
            if (active)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1E1E2E),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: const Color(0xFF2A2A3E));
}

// ─── Active filters summary strip ────────────────────────────────────────────

class _ActiveFiltersRow extends StatelessWidget {
  final SearchFilters filters;
  final VoidCallback onClear;
  const _ActiveFiltersRow({required this.filters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filters.genre != 'All') chips.add(filters.genre);
    if (filters.country != 'All') chips.add(filters.country);
    if (filters.year != 'All') chips.add(filters.year);
    if (filters.language != 'All') chips.add(filters.language);
    if (filters.sortBy != 'Hottest') chips.add('↕ ${filters.sortBy}');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips
                    .map(
                      (c) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.label_outline_rounded,
                              size: 10,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              c,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Clear all',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF888899),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton tile ────────────────────────────────────────────────────────────

class _SkeletonTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 74,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 11,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _TypeOption {
  final String label;
  final String value;
  final IconData icon;
  const _TypeOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _SearchResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String;
    final isPerson = type == 'person';
    final imageUrl = isPerson
        ? (item['photoUrl'] as String? ?? '')
        : (item['posterUrl'] as String? ?? '');
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    final year = item['year'] as String? ?? '';
    final overview = item['overview'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A3E)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppTheme.primary.withValues(alpha: 0.08),
            highlightColor: AppTheme.primary.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Poster / Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isPerson ? 30 : 10),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: isPerson ? 60 : 54,
                            height: isPerson ? 60 : 78,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _Placeholder(isPerson: isPerson),
                          )
                        : _Placeholder(isPerson: isPerson),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String? ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _TypeBadge(type: type),
                            if (year.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 11,
                                color: const Color(0xFF888899),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                year,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF888899),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!isPerson && rating > 0) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFCC00),
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFFCC00),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (overview.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    overview,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF888899),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (isPerson &&
                            (item['department'] as String? ?? '')
                                .isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.work_outline_rounded,
                                size: 11,
                                color: const Color(0xFF888899),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['department'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF888899),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF888899),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool isPerson;
  const _Placeholder({required this.isPerson});

  @override
  Widget build(BuildContext context) => Container(
    width: isPerson ? 60 : 54,
    height: isPerson ? 60 : 78,
    decoration: BoxDecoration(
      color: AppTheme.surfaceVariantDark,
      borderRadius: BorderRadius.circular(isPerson ? 30 : 10),
    ),
    child: Icon(
      isPerson ? Icons.person_rounded : Icons.movie_rounded,
      color: Colors.white24,
      size: 26,
    ),
  );
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;
    switch (type) {
      case 'movie':
        bg = AppTheme.primary.withAlpha(38);
        fg = AppTheme.primary;
        label = 'Movie';
        icon = Icons.movie_outlined;
      case 'tv':
        bg = AppTheme.secondary.withAlpha(38);
        fg = AppTheme.secondary;
        label = 'TV Show';
        icon = Icons.tv_outlined;
      default:
        bg = AppTheme.accent.withAlpha(38);
        fg = AppTheme.accent;
        label = 'Person';
        icon = Icons.person_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

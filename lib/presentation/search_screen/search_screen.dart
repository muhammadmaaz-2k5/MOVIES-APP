import 'dart:async';

import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import 'filter_sheet.dart';
import 'search_filters.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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

  static const List<_TypeOption> _typeFilters = [
    _TypeOption(label: 'All', value: 'all'),
    _TypeOption(label: 'Movies', value: 'movie'),
    _TypeOption(label: 'TV Shows', value: 'tv'),
    _TypeOption(label: 'People', value: 'person'),
  ];

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
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
        const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Map<String, dynamic> _buildQueryParams(String q) {
    final params = <String, dynamic>{
      'query': q,
      'include_adult': false,
      'page': 1,
    };

    // Genre
    if (_filters.genre != 'All') {
      final gid = SearchFilters.genreIds[_filters.genre];
      if (gid != null) params['with_genres'] = gid;
    }
    // Country
    if (_filters.country != 'All' && _filters.country != 'Other') {
      final code = SearchFilters.countryCodes[_filters.country];
      if (code != null) params['region'] = code;
    }
    // Language
    if (_filters.language != 'All') {
      final code = SearchFilters.languageCodes[_filters.language];
      if (code != null) params['language'] = code;
    }
    // Year
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
    try {
      final endpoint =
          _selectedType == 'all' ? 'search/multi' : 'search/$_selectedType';
      final resp = await _dio.get('$_tmdbBase/$endpoint',
          queryParameters: _buildQueryParams(q));

      var items = (resp.data['results'] as List? ?? []).map((r) {
        final mediaType = r['media_type'] as String? ?? _selectedType;
        final isPerson = mediaType == 'person';
        final posterPath =
            isPerson ? r['profile_path'] as String? : r['poster_path'] as String?;
        final title = r['title'] ?? r['name'] ?? 'Unknown';
        final releaseDate = r['release_date'] ?? r['first_air_date'] ?? '';
        final year =
            releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        return <String, dynamic>{
          'id': r['id'],
          'title': title,
          'type': isPerson ? 'person' : (mediaType == 'tv' ? 'tv' : 'movie'),
          'posterUrl': posterPath != null ? (posterPath.startsWith('http') ? posterPath : '$_imageBase/w342$posterPath') : '',
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
          items.sort((a, b) => ((b['rating'] as double)
              .compareTo(a['rating'] as double)));
        case 'Latest':
          items.sort(
              (a, b) => (b['year'] as String).compareTo(a['year'] as String));
        default: // Hottest = popularity (default TMDB order)
          items.sort((a, b) =>
              ((b['popularity'] as double)
                  .compareTo(a['popularity'] as double)));
      }

      if (mounted) {
        setState(() {
          _results = items;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTypeAndFilterRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF444466)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF888899), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onQueryChanged,
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 15),
                      cursorColor: AppTheme.primary,
                      decoration: InputDecoration(
                        hintText: 'Search movies, shows, people…',
                        hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFF888899), fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        _onQueryChanged('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.close_rounded,
                            color: Color(0xFF888899), size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.pop(),
            child: Text('Cancel',
                style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeAndFilterRow() {
    final activeCount = _filters.activeCount;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: _typeFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _typeFilters[i];
                  final selected = _selectedType == f.value;
                  return GestureDetector(
                    onTap: () => _onTypeChanged(f.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : const Color(0xFF444466),
                        ),
                      ),
                      child: Text(f.label,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF888899),
                          )),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            // Filter button
            GestureDetector(
              onTap: _openFilterSheet,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: activeCount > 0
                      ? AppTheme.primary.withAlpha(30)
                      : AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: activeCount > 0
                        ? AppTheme.primary
                        : const Color(0xFF444466),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 15,
                        color: activeCount > 0
                            ? AppTheme.primary
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
                              ? AppTheme.primary
                              : const Color(0xFF888899)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) return _buildEmptyState();
    if (_isLoading) return _buildLoadingState();
    if (_results.isEmpty) return _buildNoResults();
    return _buildResults();
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded,
                color: const Color(0xFF444466), size: 64),
            const SizedBox(height: 16),
            Text('Search for anything',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Movies, TV shows, actors and more',
                style: GoogleFonts.outfit(
                    fontSize: 14, color: const Color(0xFF888899))),
            if (!_filters.isDefault) ...[
              const SizedBox(height: 16),
              _ActiveFiltersRow(filters: _filters,
                  onClear: () => setState(() => _filters = const SearchFilters())),
            ],
          ],
        ),
      );

  Widget _buildLoadingState() =>
      Center(child: CircularProgressIndicator(color: AppTheme.primary));

  Widget _buildNoResults() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded,
                color: const Color(0xFF444466), size: 64),
            const SizedBox(height: 16),
            Text('No results for "$_query"',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Try a different search or adjust filters',
                style: GoogleFonts.outfit(
                    fontSize: 14, color: const Color(0xFF888899))),
            if (!_filters.isDefault) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() => _filters = const SearchFilters());
                  _search(_query);
                },
                child: Text('Clear filters',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
              ),
            ],
          ],
        ),
      );

  Widget _buildResults() {
    return Column(
      children: [
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _SearchResultTile(
              item: _results[i],
              onTap: () => _onResultTap(_results[i]),
            ),
          ),
        ),
      ],
    );
  }
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
    if (filters.sortBy != 'Hottest') chips.add('Sort: ${filters.sortBy}');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
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
                  child: Text(c,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary)),
                )).toList(),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _TypeOption {
  final String label;
  final String value;
  const _TypeOption({required this.label, required this.value});
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(isPerson ? 28 : 8),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      width: isPerson ? 56 : 52,
                      height: isPerson ? 56 : 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _Placeholder(isPerson: isPerson))
                  : _Placeholder(isPerson: isPerson),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] as String? ?? '',
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    _TypeBadge(type: type),
                    if (year.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(year,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF888899))),
                    ],
                  ]),
                  if (!isPerson && rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.star_rounded,
                          color: AppTheme.accent, size: 13),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent)),
                    ]),
                  ],
                  if (isPerson &&
                      (item['department'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item['department'] as String,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF888899))),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF444466), size: 20),
          ],
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
        width: isPerson ? 56 : 52,
        height: isPerson ? 56 : 74,
        color: AppTheme.surfaceVariantDark,
        child: Icon(isPerson ? Icons.person_rounded : Icons.movie_rounded,
            color: Colors.white24, size: 24),
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
    switch (type) {
      case 'movie':
        bg = AppTheme.primary.withAlpha(38);
        fg = AppTheme.primary;
        label = 'Movie';
      case 'tv':
        bg = AppTheme.secondary.withAlpha(38);
        fg = AppTheme.secondary;
        label = 'TV Show';
      default:
        bg = AppTheme.accent.withAlpha(38);
        fg = AppTheme.accent;
        label = 'Person';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

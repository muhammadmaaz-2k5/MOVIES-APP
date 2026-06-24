import 'dart:async';

import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

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
  String _selectedType = 'all'; // 'all' | 'movie' | 'tv' | 'person'

  static const String _tmdbBase = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  static const String _bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1YmM0ZDAzZGU2MzY1YTBlZWY3ZDBhNGM0YTdkMDAyYiIsIm5iZiI6MTc1NTg2NzY0NS40ODg5OTk4LCJzdWIiOiI2OGE4NjlmZGI0NWEzOGEyNWMyNjEzYWEiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0._zPoKSHku3D5XAsfQ-L46MTKvJTs6cOB07Ij386z4OA';

  late final Dio _dio;

  static const List<_FilterOption> _filters = [
    _FilterOption(label: 'All', value: 'all'),
    _FilterOption(label: 'Movies', value: 'movie'),
    _FilterOption(label: 'TV Shows', value: 'tv'),
    _FilterOption(label: 'People', value: 'person'),
  ];

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $_bearerToken'}));
    // Auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
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
      setState(() { _query = ''; _results = []; _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Future<void> _search(String q) async {
    setState(() { _query = q; _isLoading = true; });
    try {
      final endpoint = _selectedType == 'all' ? 'search/multi' : 'search/$_selectedType';
      final resp = await _dio.get('$_tmdbBase/$endpoint', queryParameters: {
        'query': q,
        'include_adult': false,
        'page': 1,
      });
      final items = (resp.data['results'] as List? ?? []).map((r) {
        final mediaType = r['media_type'] as String? ?? _selectedType;
        final isPerson = mediaType == 'person';
        final posterPath = isPerson
            ? r['profile_path'] as String?
            : r['poster_path'] as String?;
        final title = r['title'] ?? r['name'] ?? 'Unknown';
        final releaseDate = r['release_date'] ?? r['first_air_date'] ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        return {
          'id': r['id'],
          'title': title,
          'type': mediaType == 'person' ? 'person' : (mediaType == 'tv' ? 'tv' : 'movie'),
          'posterUrl': posterPath != null ? '$_imageBase/w342$posterPath' : '',
          'posterSemanticLabel': 'Search result poster for $title',
          'rating': (r['vote_average'] as num?)?.toDouble() ?? 0.0,
          'year': year,
          'genres': <String>[],
          'runtime': '',
          'overview': r['overview'] ?? '',
          'voteCount': r['vote_count'] ?? 0,
          'popularity': (r['popularity'] as num?)?.toDouble() ?? 0.0,
          // person-specific
          'photoUrl': isPerson && posterPath != null ? '$_imageBase/w185$posterPath' : '',
          'semanticLabel': 'Photo of $title',
          'department': r['known_for_department'] ?? 'Acting',
          'biography': '',
          'knownForDepartment': r['known_for_department'] ?? 'Acting',
        };
      }).toList();

      if (mounted) setState(() { _results = items.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(String type) {
    setState(() { _selectedType = type; _results = []; });
    if (_query.isNotEmpty) _search(_query);
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
            _buildFilterChips(),
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
                  const Icon(Icons.search_rounded, color: Color(0xFF888899), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onQueryChanged,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                      cursorColor: AppTheme.primary,
                      decoration: InputDecoration(
                        hintText: 'Search movies, shows, people…',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF888899), fontSize: 15),
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
                        child: Icon(Icons.close_rounded, color: Color(0xFF888899), size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = _filters[i];
            final selected = _selectedType == f.value;
            return GestureDetector(
              onTap: () => _onFilterChanged(f.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.primary : const Color(0xFF444466),
                  ),
                ),
                child: Text(
                  f.label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : const Color(0xFF888899),
                  ),
                ),
              ),
            );
          },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, color: const Color(0xFF444466), size: 64),
          const SizedBox(height: 16),
          Text(
            'Search for anything',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Movies, TV shows, actors and more',
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF888899)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied_rounded, color: const Color(0xFF444466), size: 64),
          const SizedBox(height: 16),
          Text(
            'No results for "$_query"',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF888899)),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _SearchResultTile(
        item: _results[i],
        onTap: () => _onResultTap(_results[i]),
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final String value;
  const _FilterOption({required this.label, required this.value});
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
                  ? Image.network(
                      imageUrl,
                      width: isPerson ? 56 : 52,
                      height: isPerson ? 56 : 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Placeholder(isPerson: isPerson),
                    )
                  : _Placeholder(isPerson: isPerson),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TypeBadge(type: type),
                      if (year.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(year, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888899))),
                      ],
                    ],
                  ),
                  if (!isPerson && rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: AppTheme.accent, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accent),
                        ),
                      ],
                    ),
                  ],
                  if (isPerson && (item['department'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['department'] as String,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888899)),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF444466), size: 20),
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
  Widget build(BuildContext context) {
    return Container(
      width: isPerson ? 56 : 52,
      height: isPerson ? 56 : 74,
      color: AppTheme.surfaceVariantDark,
      child: Icon(
        isPerson ? Icons.person_rounded : Icons.movie_rounded,
        color: Colors.white24,
        size: 24,
      ),
    );
  }
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

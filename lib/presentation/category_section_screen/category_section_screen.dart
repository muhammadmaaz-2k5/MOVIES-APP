import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class CategorySectionScreen extends StatefulWidget {
  final String emoji;
  final String title;
  final Map<String, dynamic> tmdbParams;

  const CategorySectionScreen({
    super.key,
    required this.emoji,
    required this.title,
    required this.tmdbParams,
  });

  @override
  State<CategorySectionScreen> createState() => _CategorySectionScreenState();
}

class _CategorySectionScreenState extends State<CategorySectionScreen> {
  final String _tmdbBase = AppConfig.tmdbProxyUrl;
  static const String _imageBase = 'https://image.tmdb.org/t/p';

  late final Dio _dio;
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _page = 1;
  int _totalPages = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _fetchPage(1);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isFetchingMore &&
          _page < _totalPages) {
        _fetchPage(_page + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchPage(int page) async {
    if (page == 1) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isFetchingMore = true);
    }

    try {
      final params = <String, dynamic>{
        ...widget.tmdbParams,
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
      };
      final resp = await _dio.get(
        '$_tmdbBase/discover/movie',
        queryParameters: params,
      );
      final results = (resp.data['results'] as List? ?? []);
      _totalPages = resp.data['total_pages'] as int? ?? 1;
      _page = page;

      final mapped = results.map<Map<String, dynamic>>((r) {
        final posterPath = r['poster_path'] as String?;
        final backdropPath = r['backdrop_path'] as String?;
        final title = r['title'] ?? r['name'] ?? 'Unknown';
        final releaseDate = r['release_date'] ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        return {
          'id': r['id'],
          'title': title,
          'type': 'movie',
          'posterUrl': posterPath != null
              ? (posterPath.startsWith('http')
                    ? posterPath
                    : '$_imageBase/w342$posterPath')
              : '',
          'backdropUrl': backdropPath != null
              ? (backdropPath.startsWith('http')
                    ? backdropPath
                    : '$_imageBase/w780$backdropPath')
              : '',
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
          _items.addAll(mapped);
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        title: Row(
          children: [
            Text('${widget.emoji} ', style: const TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                widget.title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2A2A3E)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, i) => _MovieCard(item: _items[i]),
                  ),
                ),
                if (_isFetchingMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
              ],
            ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MovieCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.movieTvShowDetailScreen, extra: item),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
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
                  if (rating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppTheme.accent,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE6E6F0),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['year'] as String? ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF888899),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

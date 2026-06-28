import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

// ─── Language definition ──────────────────────────────────────────────────────

class _Lang {
  final String  code;       // TMDB language code
  final String  label;      // display name
  final String  flag;       // emoji flag
  final String  nativeName;
  final String  mediaType;  // 'movie' | 'tv' | 'both'
  final Color   accentColor;

  const _Lang({
    required this.code,
    required this.label,
    required this.flag,
    required this.nativeName,
    required this.mediaType,
    required this.accentColor,
  });
}

// ─── Language browse screen ───────────────────────────────────────────────────

class LanguageBrowseScreen extends StatefulWidget {
  const LanguageBrowseScreen({super.key});

  @override
  State<LanguageBrowseScreen> createState() => _LanguageBrowseScreenState();
}

class _LanguageBrowseScreenState extends State<LanguageBrowseScreen> {
  final String _tmdbBase = AppConfig.tmdbProxyUrl;
  static const String _imageBase  = 'https://image.tmdb.org/t/p';
  

  late final Dio _dio;

  int _selectedLang = 0;
  String _selectedType = 'all'; // 'all' | 'movie' | 'tv'

  static const List<_Lang> _languages = [
    _Lang(code: 'en', label: 'English',    flag: '🇺🇸', nativeName: 'English',    mediaType: 'both', accentColor: Color(0xFF0984E3)),
    _Lang(code: 'hi', label: 'Hindi',      flag: '🇮🇳', nativeName: 'हिन्दी',      mediaType: 'both', accentColor: Color(0xFFFF6B35)),
    _Lang(code: 'pa', label: 'Punjabi',    flag: '🎵',  nativeName: 'ਪੰਜਾਬੀ',      mediaType: 'movie',accentColor: Color(0xFFFFBC00)),
    _Lang(code: 'ko', label: 'Korean',     flag: '🇰🇷', nativeName: '한국어',       mediaType: 'tv',   accentColor: Color(0xFFFF4B9E)),
    _Lang(code: 'ja', label: 'Japanese',   flag: '🇯🇵', nativeName: '日本語',       mediaType: 'both', accentColor: Color(0xFFE84393)),
    _Lang(code: 'zh', label: 'Chinese',    flag: '🇨🇳', nativeName: '中文',        mediaType: 'both', accentColor: Color(0xFFEE2A2A)),
    _Lang(code: 'es', label: 'Spanish',    flag: '🇪🇸', nativeName: 'Español',     mediaType: 'both', accentColor: Color(0xFFF39C12)),
    _Lang(code: 'fr', label: 'French',     flag: '🇫🇷', nativeName: 'Français',    mediaType: 'both', accentColor: Color(0xFF4834D4)),
    _Lang(code: 'tr', label: 'Turkish',    flag: '🇹🇷', nativeName: 'Türkçe',      mediaType: 'tv',   accentColor: Color(0xFFE74C3C)),
    _Lang(code: 'ar', label: 'Arabic',     flag: '🇸🇦', nativeName: 'العربية',     mediaType: 'both', accentColor: Color(0xFF00B894)),
    _Lang(code: 'ta', label: 'Tamil',      flag: '🎞️',  nativeName: 'தமிழ்',       mediaType: 'movie',accentColor: Color(0xFF6C5CE7)),
    _Lang(code: 'te', label: 'Telugu',     flag: '🎥',  nativeName: 'తెలుగు',      mediaType: 'movie',accentColor: Color(0xFFBD5AF4)),
    _Lang(code: 'ml', label: 'Malayalam',  flag: '🌴',  nativeName: 'മലയാളം',      mediaType: 'movie',accentColor: Color(0xFF00CEC9)),
    _Lang(code: 'de', label: 'German',     flag: '🇩🇪', nativeName: 'Deutsch',     mediaType: 'both', accentColor: Color(0xFF636E72)),
    _Lang(code: 'pt', label: 'Portuguese', flag: '🇵🇹', nativeName: 'Português',   mediaType: 'both', accentColor: Color(0xFF55A630)),
    _Lang(code: 'ru', label: 'Russian',    flag: '🇷🇺', nativeName: 'Русский',     mediaType: 'both', accentColor: Color(0xFF1E88E5)),
    _Lang(code: 'th', label: 'Thai',       flag: '🇹🇭', nativeName: 'ภาษาไทย',     mediaType: 'both', accentColor: Color(0xFF6AB04C)),
    _Lang(code: 'id', label: 'Indonesian', flag: '🇮🇩', nativeName: 'Bahasa',      mediaType: 'both', accentColor: Color(0xFFEB4D4B)),
    _Lang(code: 'ur', label: 'Urdu',       flag: '🇵🇰', nativeName: 'اردو',        mediaType: 'movie',accentColor: Color(0xFF01CBC6)),
    _Lang(code: 'bn', label: 'Bengali',    flag: '🇧🇩', nativeName: 'বাংলা',        mediaType: 'movie',accentColor: Color(0xFFF9CA24)),
  ];

  // Cached results per lang index
  final Map<int, List<Map<String, dynamic>>> _movies   = {};
  final Map<int, List<Map<String, dynamic>>> _tvShows  = {};
  final Map<int, bool> _loadingMovies  = {};
  final Map<int, bool> _loadingTv      = {};

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _fetchForLang(0);
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchForLang(int idx) async {
    if ((_movies[idx] != null) && (_tvShows[idx] != null)) return;
    final lang = _languages[idx];
    await Future.wait([
      _fetchMovies(idx, lang.code),
      _fetchTv(idx, lang.code),
    ]);
  }

  Future<void> _fetchMovies(int idx, String code) async {
    if (_loadingMovies[idx] == true) return;
    setState(() => _loadingMovies[idx] = true);
    try {
      final resp = await _dio.get('$_tmdbBase/discover/movie', queryParameters: {
        'with_original_language': code,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'page': 1,
      });
      final items = _parse(resp.data['results'] as List? ?? [], 'movie');
      if (mounted) setState(() { _movies[idx] = items; _loadingMovies[idx] = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMovies[idx] = false);
    }
  }

  Future<void> _fetchTv(int idx, String code) async {
    if (_loadingTv[idx] == true) return;
    setState(() => _loadingTv[idx] = true);
    try {
      final resp = await _dio.get('$_tmdbBase/discover/tv', queryParameters: {
        'with_original_language': code,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'page': 1,
      });
      final items = _parse(resp.data['results'] as List? ?? [], 'tv');
      if (mounted) setState(() { _tvShows[idx] = items; _loadingTv[idx] = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTv[idx] = false);
    }
  }

  List<Map<String, dynamic>> _parse(List raw, String type) =>
      raw.map<Map<String, dynamic>>((r) {
        final poster = r['poster_path']   as String?;
        final backdrop = r['backdrop_path'] as String?;
        final title = (r['title'] ?? r['name'] ?? 'Unknown') as String;
        final date  = (r['release_date'] ?? r['first_air_date'] ?? '') as String;
        return {
          'id': r['id'], 'title': title, 'type': type,
          'posterUrl':   poster   != null ? '$_imageBase/w342$poster'   : '',
          'backdropUrl': backdrop != null ? '$_imageBase/w780$backdrop' : '',
          'posterSemanticLabel': 'Poster for $title',
          'backdropSemanticLabel': 'Backdrop for $title',
          'rating': (r['vote_average'] as num?)?.toDouble() ?? 0.0,
          'year': date.length >= 4 ? date.substring(0, 4) : '',
          'genres': <String>[], 'runtime': '',
          'overview': r['overview'] ?? '', 'voteCount': r['vote_count'] ?? 0,
        };
      }).toList();

  void _onLangTap(int idx) {
    setState(() => _selectedLang = idx);
    _fetchForLang(idx);
  }

  List<Map<String, dynamic>> get _currentItems {
    final movies = _movies[_selectedLang] ?? [];
    final tv     = _tvShows[_selectedLang] ?? [];
    if (_selectedType == 'movie') return movies;
    if (_selectedType == 'tv')    return tv;
    // 'all': interleave movie + tv
    final all = <Map<String, dynamic>>[];
    final len = movies.length > tv.length ? movies.length : tv.length;
    for (int i = 0; i < len; i++) {
      if (i < movies.length) all.add(movies[i]);
      if (i < tv.length)     all.add(tv[i]);
    }
    return all;
  }

  bool get _isLoading =>
      (_loadingMovies[_selectedLang] ?? true) ||
      (_loadingTv[_selectedLang] ?? true);

  @override
  Widget build(BuildContext context) {
    final lang        = _languages[_selectedLang];
    final accentColor = lang.accentColor;
    final isTablet    = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(lang, accentColor),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Language selector chips ──────────────────────────────
          _LangSelectorRow(
            languages:     _languages,
            selectedIndex: _selectedLang,
            onTap:         _onLangTap,
          ),
          const SizedBox(height: 4),
          // ── Type filter (All / Movies / TV) ──────────────────────
          _TypeFilterRow(
            selected:    _selectedType,
            accentColor: accentColor,
            onTap: (t) => setState(() => _selectedType = t),
          ),
          const Divider(color: Color(0xFF2A2A3E), height: 1),
          // ── Content grid ─────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : _currentItems.isEmpty
                    ? _EmptyState(lang: lang)
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 4 : 3,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 10,
                          mainAxisSpacing:  10,
                        ),
                        itemCount: _currentItems.length,
                        itemBuilder: (context, i) => _LangCard(
                          item:        _currentItems[i],
                          accentColor: accentColor,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(_Lang lang, Color accent) => AppBar(
    backgroundColor: AppTheme.surfaceDark,
    elevation: 0,
    automaticallyImplyLeading: false,
    leading: GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 16),
      ),
    ),
    title: Row(children: [
      Text(lang.flag, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(lang.label,
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(lang.nativeName,
              style: GoogleFonts.outfit(
                  fontSize: 11, color: const Color(0xFF888899))),
        ],
      ),
    ]),
    actions: [
      GestureDetector(
        onTap: () => context.push(AppRoutes.searchScreen),
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
        ),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: const Color(0xFF2A2A3E)),
    ),
  );
}

// ─── Language selector horizontal chips ──────────────────────────────────────

class _LangSelectorRow extends StatelessWidget {
  final List<_Lang> languages;
  final int         selectedIndex;
  final void Function(int) onTap;

  const _LangSelectorRow({
    required this.languages,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final lang     = languages[i];
          final selected = i == selectedIndex;
          final accent   = lang.accentColor;

          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? accent.withAlpha(200) : AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? accent : const Color(0xFF444466),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: accent.withAlpha(80), blurRadius: 8)]
                    : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(lang.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(lang.label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? Colors.white : const Color(0xFF888899),
                    )),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Type filter row ──────────────────────────────────────────────────────────

class _TypeFilterRow extends StatelessWidget {
  final String   selected;
  final Color    accentColor;
  final void Function(String) onTap;

  const _TypeFilterRow({
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        _TypeChip(label: 'All',    value: 'all',   icon: Icons.apps_rounded,          selected: selected, onTap: onTap, accent: accentColor),
        const SizedBox(width: 8),
        _TypeChip(label: 'Movies', value: 'movie', icon: Icons.movie_rounded,          selected: selected, onTap: onTap, accent: accentColor),
        const SizedBox(width: 8),
        _TypeChip(label: 'TV',     value: 'tv',    icon: Icons.tv_rounded,             selected: selected, onTap: onTap, accent: accentColor),
        const Spacer(),
        // Item count hint
      ]),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final String   selected;
  final Color    accent;
  final void Function(String) onTap;

  const _TypeChip({
    required this.label,   required this.value,
    required this.icon,    required this.selected,
    required this.onTap,   required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : const Color(0xFF444466),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13,
              color: isSelected ? accent : const Color(0xFF888899)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? accent : const Color(0xFF888899),
              )),
        ]),
      ),
    );
  }
}

// ─── Content card ─────────────────────────────────────────────────────────────

class _LangCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accentColor;
  const _LangCard({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    final type   = item['type'] as String? ?? 'movie';

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
              child: Stack(fit: StackFit.expand, children: [
                CustomImageWidget(
                  imageUrl: item['posterUrl'] as String?,
                  fit: BoxFit.cover,
                  semanticLabel: item['posterSemanticLabel'] as String?,
                ),
                // Gradient
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(height: 48,
                    decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(200), Colors.transparent])))),
                // Type badge
                Positioned(top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(4)),
                    child: Text(type == 'tv' ? 'TV' : 'FILM',
                        style: GoogleFonts.outfit(
                            fontSize: 8, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: 0.5)))),
                // Rating
                if (rating > 0)
                  Positioned(bottom: 6, right: 6,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, color: AppTheme.accent, size: 11),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(fontSize: 10,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                    ])),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['title'] as String? ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 11,
                        fontWeight: FontWeight.w600, color: const Color(0xFFE6E6F0))),
                if ((item['year'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item['year'] as String,
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: const Color(0xFF888899))),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Lang lang;
  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(lang.flag, style: const TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text('No results for ${lang.label}',
          style: GoogleFonts.outfit(fontSize: 16,
              fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 8),
      Text('Try switching to Movies or TV',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF888899))),
    ]),
  );
}

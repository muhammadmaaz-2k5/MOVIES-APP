import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../search_screen/search_filters.dart';

// TV genre TMDB IDs — top-level so both the sheet and tv_shows_screen can use them
const Map<String, int> _kTvGenreIds = {
  'Action & Adventure': 10759, 'Animation': 16, 'Comedy': 35,
  'Crime': 80, 'Documentary': 99, 'Drama': 18, 'Family': 10751,
  'Kids': 10762, 'Mystery': 9648, 'News': 10763, 'Reality': 10764,
  'Romance': 10749, 'Sci-Fi & Fantasy': 10765, 'Soap': 10766,
  'Talk': 10767, 'War & Politics': 10768, 'Western': 37,
};
/// [mediaType] is 'movie' or 'tv' — controls which genre list is shown.
class MediaFilterSheet extends StatefulWidget {
  final SearchFilters current;
  final String mediaType; // 'movie' | 'tv'

  const MediaFilterSheet({
    super.key,
    required this.current,
    required this.mediaType,
  });

  @override
  State<MediaFilterSheet> createState() => _MediaFilterSheetState();
}

class _MediaFilterSheetState extends State<MediaFilterSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late SearchFilters _filters;

  static const _tabs = ['Country', 'Year', 'Language', 'Sort by'];

  // Movie genre list (TMDB IDs)
  static const List<String> _movieGenres = [
    'All', 'Action', 'Adventure', 'Animation', 'Comedy', 'Crime',
    'Documentary', 'Drama', 'Family', 'Fantasy', 'History', 'Horror',
    'Music', 'Mystery', 'Romance', 'Sci-Fi', 'Thriller', 'War', 'Western',
  ];

  // TV genre list (TMDB IDs differ from movies)
  static const List<String> _tvGenres = [
    'All', 'Action & Adventure', 'Animation', 'Comedy', 'Crime', 'Documentary',
    'Drama', 'Family', 'Kids', 'Mystery', 'News', 'Reality', 'Romance',
    'Sci-Fi & Fantasy', 'Soap', 'Talk', 'War & Politics', 'Western',
  ];

  List<String> get _genres =>
      widget.mediaType == 'tv' ? _tvGenres : _movieGenres;

  @override
  void initState() {
    super.initState();
    _filters = widget.current;
    // Genre is tab 0, so shift tabs
    _tab = TabController(length: _tabs.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        _handle(),
        _header(),
        _tabBar(),
        Expanded(child: _tabViews()),
        _footer(context),
      ]),
    );
  }

  Widget _handle() => Container(
    width: 40, height: 4,
    margin: const EdgeInsets.only(top: 12, bottom: 4),
    decoration: BoxDecoration(color: const Color(0xFF444466), borderRadius: BorderRadius.circular(2)),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Row(children: [
      Text('Filters', style: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      const Spacer(),
      GestureDetector(
        onTap: () => setState(() => _filters = const SearchFilters()),
        child: Text('Reset', style: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
      ),
    ]),
  );

  Widget _tabBar() => TabBar(
    controller: _tab,
    isScrollable: true,
    tabAlignment: TabAlignment.start,
    indicatorColor: AppTheme.primary,
    indicatorWeight: 2,
    labelColor: AppTheme.primary,
    unselectedLabelColor: const Color(0xFF888899),
    labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
    unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w400),
    dividerColor: const Color(0xFF2A2A3E),
    tabs: ['Genre', ..._tabs].map((t) => Tab(text: t)).toList(),
  );

  Widget _tabViews() => TabBarView(
    controller: _tab,
    children: [
      // Genre
      _optionGrid(
        options: _genres,
        selected: _filters.genre,
        onTap: (v) => setState(() => _filters = _filters.copyWith(genre: v)),
      ),
      // Country
      _optionGrid(
        options: SearchFilters.countries,
        selected: _filters.country,
        onTap: (v) => setState(() => _filters = _filters.copyWith(country: v)),
      ),
      // Year
      _optionGrid(
        options: SearchFilters.years,
        selected: _filters.year,
        onTap: (v) => setState(() => _filters = _filters.copyWith(year: v)),
      ),
      // Language
      _optionGrid(
        options: SearchFilters.languages,
        selected: _filters.language,
        onTap: (v) => setState(() => _filters = _filters.copyWith(language: v)),
        wrap: true,
      ),
      // Sort by
      _optionGrid(
        options: SearchFilters.sortOptions,
        selected: _filters.sortBy,
        onTap: (v) => setState(() => _filters = _filters.copyWith(sortBy: v)),
      ),
    ],
  );

  Widget _optionGrid({
    required List<String> options,
    required String selected,
    required void Function(String) onTap,
    bool wrap = false,
  }) {
    if (wrap) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((o) => _chip(o, selected, onTap)).toList(),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 2.6, crossAxisSpacing: 8, mainAxisSpacing: 8,
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
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariantDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFF444466)),
        ),
        child: Text(label,
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFFCCCCDD),
          )),
      ),
    );
  }

  Widget _footer(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
    child: SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, _filters),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text('Apply Filters',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    ),
  );

}

// Top-level helper so tv_shows_screen can look up TV genre IDs without
// accessing the private state class.
int? tvGenreIdForName(String genre) => _kTvGenreIds[genre];

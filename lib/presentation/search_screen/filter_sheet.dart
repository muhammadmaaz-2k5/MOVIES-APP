import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import 'search_filters.dart';

class FilterSheet extends StatefulWidget {
  final SearchFilters current;
  const FilterSheet({super.key, required this.current});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late SearchFilters _filters;

  static const _tabs = ['Genre', 'Country', 'Year', 'Language', 'Sort by'];

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
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildTabViews()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHandle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF444466),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            Text('Filters',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _filters = const SearchFilters()),
              child: Text('Reset',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary)),
            ),
          ],
        ),
      );

  Widget _buildTabBar() => TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2,
        labelColor: AppTheme.primary,
        unselectedLabelColor: const Color(0xFF888899),
        labelStyle:
            GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w400),
        dividerColor: const Color(0xFF2A2A3E),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      );

  Widget _buildTabViews() => TabBarView(
        controller: _tab,
        children: [
          _optionGrid(
            options: SearchFilters.genres,
            selected: _filters.genre,
            onTap: (v) => setState(() => _filters = _filters.copyWith(genre: v)),
          ),
          _optionGrid(
            options: SearchFilters.countries,
            selected: _filters.country,
            onTap: (v) => setState(
                () => _filters = _filters.copyWith(country: v)),
          ),
          _optionGrid(
            options: SearchFilters.years,
            selected: _filters.year,
            onTap: (v) =>
                setState(() => _filters = _filters.copyWith(year: v)),
          ),
          _optionGrid(
            options: SearchFilters.languages,
            selected: _filters.language,
            onTap: (v) => setState(
                () => _filters = _filters.copyWith(language: v)),
            wrap: true,
          ),
          _optionGrid(
            options: SearchFilters.sortOptions,
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
    bool wrap = false,
  }) {
    if (wrap) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) => _chip(o, selected, onTap)).toList(),
        ),
      );
    }
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
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariantDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFF444466),
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

  Widget _buildFooter() => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _filters),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
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

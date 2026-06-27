import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class DetailBottomActionBarWidget extends StatelessWidget {
  final bool isInWatchlist;
  final VoidCallback onWatchlistToggle;
  final Map<String, dynamic> item;
  // For TV/Anime — list of season maps from TMDB
  final List<Map<String, dynamic>> seasons;

  const DetailBottomActionBarWidget({
    super.key,
    required this.isInWatchlist,
    required this.onWatchlistToggle,
    required this.item,
    this.seasons = const [],
  });

  @override
  Widget build(BuildContext context) {
    final type   = item['type'] as String? ?? 'movie';
    final isTV   = type == 'tv';
    final tmdbId = item['id']        as int?    ?? 0;
    final title  = item['title']     as String? ?? '';
    final poster = item['posterUrl'] as String? ?? '';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark.withAlpha(217),
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  _IconActionBtn(
                    icon: isInWatchlist
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    isActive:    isInWatchlist,
                    activeColor: AppTheme.primary,
                    onTap:       onWatchlistToggle,
                    tooltip:     isInWatchlist ? 'In Watchlist' : 'Watchlist',
                  ),
                  const SizedBox(width: 10),
                  DownloadButton(
                    tmdbId:    tmdbId,
                    title:     title,
                    type:      isTV ? 'tv_episode' : 'movie',
                    posterUrl: poster,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WatchButton(item: item, seasons: seasons),
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

// ─── Watch button ─────────────────────────────────────────────────────────────

class _WatchButton extends StatelessWidget {
  final Map<String, dynamic>       item;
  final List<Map<String, dynamic>> seasons;
  const _WatchButton({required this.item, required this.seasons});

  void _onTap(BuildContext context) {
    final type = item['type'] as String? ?? 'movie';
    if (type == 'tv') {
      _showEpisodePicker(context);
    } else {
      // Movie or anime movie — go straight to player
      context.push(AppRoutes.moviePlayerScreen, extra: item);
    }
  }

  void _showEpisodePicker(BuildContext context) {
    final title = item['title'] as String? ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EpisodePickerSheet(
        item:    item,
        seasons: seasons,
        title:   title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type  = item['type'] as String? ?? 'movie';
    final isTV  = type == 'tv';
    final label = isTV ? 'Select Episode' : 'Watch Now';
    final icon  = isTV ? Icons.video_library_rounded : Icons.play_arrow_rounded;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withAlpha(200)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Episode picker bottom sheet ──────────────────────────────────────────────

class _EpisodePickerSheet extends StatefulWidget {
  final Map<String, dynamic>       item;
  final List<Map<String, dynamic>> seasons;
  final String                     title;

  const _EpisodePickerSheet({
    required this.item,
    required this.seasons,
    required this.title,
  });

  @override
  State<_EpisodePickerSheet> createState() => _EpisodePickerSheetState();
}

class _EpisodePickerSheetState extends State<_EpisodePickerSheet> {
  int _selectedSeason = 0;  // index into widget.seasons

  // Build the list of seasons — fallback to S1–SN using numberOfSeasons
  List<_SeasonInfo> get _seasonList {
    if (widget.seasons.isNotEmpty) {
      return widget.seasons.map((s) {
        final num = s['season_number'] as int? ?? 1;
        final ep  = s['episode_count'] as int? ?? 1;
        final name = s['name'] as String? ?? 'Season $num';
        return _SeasonInfo(number: num, episodeCount: ep, label: name);
      }).toList();
    }
    // Fallback: use numberOfSeasons from item
    final count = widget.item['numberOfSeasons'] as int? ?? 1;
    return List.generate(count, (i) =>
        _SeasonInfo(number: i + 1, episodeCount: 12, label: 'Season ${i + 1}'));
  }

  void _play(int episodeNumber) {
    final season = _seasonList[_selectedSeason];
    Navigator.pop(context);
    context.push(AppRoutes.moviePlayerScreen, extra: {
      ...widget.item,
      'season':  season.number,
      'episode': episodeNumber,
      'title':   '${widget.title} · S${season.number}E$episodeNumber',
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _seasonList;
    final current = list.isEmpty ? null : list[_selectedSeason];

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize:     0.45,
      maxChildSize:     0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFF444466),
                  borderRadius: BorderRadius.circular(2))),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('Select a season & episode',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: const Color(0xFF888899))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ),

            // Season selector
            if (list.length > 1)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final s        = list[i];
                    final selected = i == _selectedSeason;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSeason = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
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
                        child: Text(s.label,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
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

            const SizedBox(height: 10),
            const Divider(color: Color(0xFF2A2A3E), height: 1),

            // Episode grid
            Expanded(
              child: current == null
                  ? const Center(
                      child: Text('No episodes found',
                          style: TextStyle(color: Color(0xFF888899))))
                  : GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: current.episodeCount,
                      itemBuilder: (context, i) {
                        final ep = i + 1;
                        return GestureDetector(
                          onTap: () => _play(ep),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF2A2A3E)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text('E$ep',
                                        style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ],
                                ),
                                // Play icon overlay
                                Positioned(
                                  bottom: 4, right: 4,
                                  child: Icon(Icons.play_arrow_rounded,
                                      color: AppTheme.primary
                                          .withAlpha(180),
                                      size: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonInfo {
  final int    number;
  final int    episodeCount;
  final String label;
  const _SeasonInfo({
    required this.number,
    required this.episodeCount,
    required this.label,
  });
}

// ─── Icon action button ───────────────────────────────────────────────────────

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final bool     isActive;
  final Color    activeColor;
  final VoidCallback onTap;
  final String   tooltip;

  const _IconActionBtn({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withAlpha(40)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFF444466),
            ),
          ),
          child: Icon(icon,
              color: isActive ? activeColor : const Color(0xFF888899),
              size: 22),
        ),
      ),
    );
  }
}

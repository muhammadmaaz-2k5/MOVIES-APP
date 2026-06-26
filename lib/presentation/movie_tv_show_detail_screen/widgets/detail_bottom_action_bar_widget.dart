import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class DetailBottomActionBarWidget extends StatelessWidget {
  final bool isInWatchlist;
  final VoidCallback onWatchlistToggle;
  /// Full item map — needed to open the player and start downloads
  final Map<String, dynamic> item;

  const DetailBottomActionBarWidget({
    super.key,
    required this.isInWatchlist,
    required this.onWatchlistToggle,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final type    = item['type'] as String? ?? 'movie';
    final isMovie = type == 'movie';
    final tmdbId  = item['id']       as int?    ?? 0;
    final title   = item['title']    as String? ?? '';
    final poster  = item['posterUrl'] as String? ?? '';

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
                  // ── Watchlist toggle ─────────────────────────────
                  _IconActionBtn(
                    icon: isInWatchlist
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    isActive:  isInWatchlist,
                    activeColor: AppTheme.primary,
                    onTap: onWatchlistToggle,
                    tooltip: isInWatchlist ? 'In Watchlist' : 'Watchlist',
                  ),
                  const SizedBox(width: 10),

                  // ── Download button ──────────────────────────────
                  DownloadButton(
                    tmdbId:    tmdbId,
                    title:     title,
                    type:      isMovie ? 'movie' : 'tv_episode',
                    posterUrl: poster,
                  ),
                  const SizedBox(width: 10),

                  // ── Watch / Play button ──────────────────────────
                  Expanded(
                    child: _WatchButton(item: item),
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
  final Map<String, dynamic> item;
  const _WatchButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.moviePlayerScreen,
        extra: item,
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary,
              AppTheme.primary.withAlpha(200),
            ],
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
              const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                'Watch Now',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withAlpha(40)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFF444466),
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? activeColor : const Color(0xFF888899),
            size: 22,
          ),
        ),
      ),
    );
  }
}

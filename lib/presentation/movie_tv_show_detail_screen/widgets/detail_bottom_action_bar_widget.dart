import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DetailBottomActionBarWidget extends StatelessWidget {
  final bool isInWatchlist;
  final VoidCallback onWatchlistToggle;

  const DetailBottomActionBarWidget({
    super.key,
    required this.isInWatchlist,
    required this.onWatchlistToggle,
  });

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  // Bookmark icon button
                  GestureDetector(
                    onTap: onWatchlistToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isInWatchlist
                            ? AppTheme.primary.withAlpha(51)
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isInWatchlist
                              ? AppTheme.primary
                              : const Color(0xFF444466),
                        ),
                      ),
                      child: Icon(
                        isInWatchlist
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isInWatchlist
                            ? AppTheme.primary
                            : const Color(0xFF888899),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Watchlist CTA button
                  Expanded(
                    child: GestureDetector(
                      onTap: onWatchlistToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isInWatchlist
                              ? AppTheme.primary
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isInWatchlist
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isInWatchlist
                                    ? 'In Watchlist'
                                    : 'Add to Watchlist',
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

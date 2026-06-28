import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../utils/app_actions.dart';

class ActorBottomBarWidget extends StatefulWidget {
  final bool isFollowing;
  final VoidCallback onFollowToggle;
  final Map<String, dynamic> person;

  const ActorBottomBarWidget({
    super.key,
    required this.isFollowing,
    required this.onFollowToggle,
    required this.person,
  });

  @override
  State<ActorBottomBarWidget> createState() => _ActorBottomBarWidgetState();
}

class _ActorBottomBarWidgetState extends State<ActorBottomBarWidget> {
  bool _isFavorite = false;

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // ── Favorite button ────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isFavorite
                                ? '❤️ Added to favourites'
                                : 'Removed from favourites',
                            style: GoogleFonts.outfit(),
                          ),
                          backgroundColor: AppTheme.surfaceDark,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: _isFavorite
                            ? Colors.redAccent.withAlpha(30)
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isFavorite
                              ? Colors.redAccent.withAlpha(180)
                              : const Color(0xFF444466),
                        ),
                      ),
                      child: Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorite
                            ? Colors.redAccent
                            : const Color(0xFF888899),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Share button ───────────────────────────────────
                  GestureDetector(
                    onTap: () => sharePerson(widget.person, context: context),
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF444466)),
                      ),
                      child: const Icon(Icons.share_rounded,
                          color: Color(0xFF888899), size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Follow / Unfollow button ───────────────────────
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onFollowToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.isFollowing
                              ? AppTheme.surfaceDark
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                          border: widget.isFollowing
                              ? Border.all(color: AppTheme.primary)
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.isFollowing
                                    ? Icons.check_rounded
                                    : Icons.notifications_active_outlined,
                                color: widget.isFollowing
                                    ? AppTheme.primary
                                    : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isFollowing ? 'Following' : 'Follow',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isFollowing
                                      ? AppTheme.primary
                                      : Colors.white,
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

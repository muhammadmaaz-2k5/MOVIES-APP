import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ActorBottomBarWidget extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onFollowToggle;

  const ActorBottomBarWidget({
    super.key,
    required this.isFollowing,
    required this.onFollowToggle,
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
                  // Favorite button
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF444466)),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: Color(0xFF888899),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Follow / Unfollow button
                  Expanded(
                    child: GestureDetector(
                      onTap: onFollowToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? AppTheme.surfaceDark
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                          border: isFollowing
                              ? Border.all(color: AppTheme.primary)
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFollowing
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                color: isFollowing
                                    ? AppTheme.primary
                                    : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isFollowing ? 'Following' : 'Follow Actor',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isFollowing
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

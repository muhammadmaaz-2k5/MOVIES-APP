import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ActorBioWidget extends StatelessWidget {
  final String bio;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ActorBioWidget({
    super.key,
    required this.bio,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biography',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: Text(
              bio,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFFAAAAAA),
                height: 1.6,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              bio,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFFAAAAAA),
                height: 1.6,
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              isExpanded ? 'Show Less' : 'Read More',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

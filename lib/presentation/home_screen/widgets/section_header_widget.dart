import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/custom_icon_widget.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final String iconName;
  final VoidCallback? onSeeMore;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    required this.iconName,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: const Color(0xFF6C5CE7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (onSeeMore != null)
            GestureDetector(
              onTap: onSeeMore,
              child: Text(
                'See all',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6C5CE7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

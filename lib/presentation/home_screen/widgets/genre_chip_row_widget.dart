import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';

class GenreChipRowWidget extends StatelessWidget {
  final List<String> genres;

  const GenreChipRowWidget({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF444466)),
            ),
            child: Text(
              genres[i],
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFCCCCDD),
              ),
            ),
          );
        },
      ),
    );
  }
}

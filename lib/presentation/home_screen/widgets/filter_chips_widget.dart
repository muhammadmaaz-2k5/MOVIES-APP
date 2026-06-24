import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';

class FilterChipsWidget extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final void Function(int) onSelected;

  const FilterChipsWidget({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.primary : const Color(0xFF444466),
                ),
              ),
              child: Text(
                options[i],
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : const Color(0xFF888899),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

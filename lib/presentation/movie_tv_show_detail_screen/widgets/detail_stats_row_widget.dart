import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';

class DetailStatsRowWidget extends StatelessWidget {
  final Map<String, dynamic> item;

  const DetailStatsRowWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final stats = <Map<String, String>>[
      if (item['year'] != null) {'label': 'Year', 'value': item['year'] as String},
      if (item['runtime'] != null && (item['runtime'] as String).isNotEmpty)
        {'label': 'Runtime', 'value': item['runtime'] as String},
      if (item['status'] != null) {'label': 'Status', 'value': item['status'] as String},
      if (item['language'] != null) {'label': 'Language', 'value': item['language'] as String},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: stats.map((s) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF444466)),
            ),
            child: Column(
              children: [
                Text(
                  s['value']!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE6E6F0),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s['label']!,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF888899),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

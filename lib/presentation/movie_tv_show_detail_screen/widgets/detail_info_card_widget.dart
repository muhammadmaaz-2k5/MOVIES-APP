import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DetailInfoCardWidget extends StatelessWidget {
  final Map<String, dynamic> item;

  const DetailInfoCardWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isMovie = item['type'] == 'movie';
    final details = <_DetailRow>[
      if (item['director'] != null)
        _DetailRow(
          icon: Icons.movie_creation_outlined,
          label: 'Director',
          value: item['director'] as String,
        ),
      _DetailRow(
        icon: Icons.calendar_today_rounded,
        label: 'Release Year',
        value: item['year'] as String,
      ),
      if (item['language'] != null)
        _DetailRow(
          icon: Icons.language_rounded,
          label: 'Language',
          value: item['language'] as String,
        ),
      if (item['budget'] != null && isMovie)
        _DetailRow(
          icon: Icons.attach_money_rounded,
          label: 'Budget',
          value: item['budget'] as String,
        ),
      if (item['revenue'] != null && isMovie)
        _DetailRow(
          icon: Icons.bar_chart_rounded,
          label: 'Revenue',
          value: item['revenue'] as String,
        ),
      _DetailRow(
        icon: Icons.check_circle_outline_rounded,
        label: 'Status',
        value: item['status'] as String? ?? 'Released',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Movie Details',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ...details.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: const Color(0xFF2A2A3E),
                      indent: 16,
                      endIndent: 16,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(d.icon, color: const Color(0xFF888899), size: 16),
                        const SizedBox(width: 10),
                        Text(
                          d.label,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF888899),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          d.value,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  _DetailRow({required this.icon, required this.label, required this.value});
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ActorStatsRowWidget extends StatelessWidget {
  final Map<String, dynamic> person;

  const ActorStatsRowWidget({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        icon: Icons.work_outline_rounded,
        label: 'Known For',
        value: person['knownForDepartment'] as String? ?? 'Acting',
      ),
      _StatItem(
        icon: Icons.cake_rounded,
        label: 'Birthday',
        value: _shortDate(person['birthday'] as String? ?? ''),
      ),
      _StatItem(
        icon: Icons.location_on_rounded,
        label: 'From',
        value: _shortLocation(person['birthplace'] as String? ?? ''),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          children: List.generate(stats.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Container(
                width: 1,
                height: 36,
                color: const Color(0xFF2A2A3E),
              );
            }
            final stat = stats[i ~/ 2];
            return Expanded(
              child: Column(
                children: [
                  Icon(stat.icon, color: AppTheme.primary, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    stat.label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: const Color(0xFF888899),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.value,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  String _shortDate(String date) {
    if (date.isEmpty) return 'N/A';
    final parts = date.split(' ');
    if (parts.length >= 3) return '${parts[0].substring(0, 3)} ${parts[2]}';
    return date;
  }

  String _shortLocation(String location) {
    if (location.isEmpty) return 'N/A';
    final parts = location.split(',');
    return parts.first.trim();
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  _StatItem({required this.icon, required this.label, required this.value});
}

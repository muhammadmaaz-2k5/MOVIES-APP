import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';

/// Downloads screen — shows popular external download sources.
/// All downloads happen in the browser, not inside the app.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  static const _sources = [
    _Source('YTS', '🎬', 'Best quality movies in small file sizes',
        'https://yts.mx'),
    _Source('EZTV', '📺', 'TV show torrents updated daily',
        'https://eztv.re'),
    _Source('1337x', '🔍', 'Large index of movies, shows & more',
        'https://1337x.to'),
    _Source('Archive.org', '📦', 'Free public domain movies & shows',
        'https://archive.org/details/movies'),
    _Source('Open Subtitles', '📝', 'Download subtitles for any title',
        'https://www.opensubtitles.org'),
  ];

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open link', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF1E1E2E),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        title: Row(children: [
          const Icon(Icons.download_rounded,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: 8),
          Text('Download Sources',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2A2A3E)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppTheme.primary.withAlpha(50)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All links open in your browser. '
                    'CineTrack does not host or distribute any content. '
                    'Please respect copyright laws in your region.',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text('External Sources',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF888899))),

          const SizedBox(height: 12),

          ..._sources.map((src) => _SourceCard(
                source: src,
                onTap: () => _launch(context, src.url),
              )),
        ],
      ),
    );
  }
}

// ─── Source card ──────────────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  final _Source source;
  final VoidCallback onTap;
  const _SourceCard({required this.source, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(source.icon,
                    style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source.name,
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text(source.description,
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF888899))),
                const SizedBox(height: 4),
                Text(source.url,
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppTheme.primary.withAlpha(180)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.primary.withAlpha(80)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Visit',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new_rounded,
                  color: AppTheme.primary, size: 12),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Source {
  final String name;
  final String icon;
  final String description;
  final String url;
  const _Source(this.name, this.icon, this.description, this.url);
}

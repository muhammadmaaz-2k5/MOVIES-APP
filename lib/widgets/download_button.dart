import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import '../core/app_export.dart';

// ─── Download link builders ───────────────────────────────────────────────────

// ─── Download button ──────────────────────────────────────────────────────────

/// Tapping opens a bottom sheet with external download links.
/// No in-app downloading — links open in the device browser.
class DownloadButton extends StatelessWidget {
  final int tmdbId;
  final String title;
  final String type; // 'movie' | 'tv_episode'
  final String posterUrl;
  final String subtitle; // episode label, empty for movies
  final int? season;
  final int? episode;

  const DownloadButton({
    super.key,
    required this.tmdbId,
    required this.title,
    required this.type,
    required this.posterUrl,
    this.subtitle = '',
    this.season,
    this.episode,
  });

  void _onTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadLinksSheet(
        tmdbId: tmdbId,
        title: title,
        type: type,
        subtitle: subtitle,
        season: season,
        episode: episode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF444466)),
        ),
        child: const Icon(
          Icons.download_rounded,
          color: Color(0xFF888899),
          size: 22,
        ),
      ),
    );
  }
}

// ─── Download links sheet ─────────────────────────────────────────────────────

class _DownloadLinksSheet extends StatefulWidget {
  final int tmdbId;
  final String title;
  final String type;
  final String subtitle;
  final int? season;
  final int? episode;

  const _DownloadLinksSheet({
    required this.tmdbId,
    required this.title,
    required this.type,
    required this.subtitle,
    this.season,
    this.episode,
  });

  @override
  State<_DownloadLinksSheet> createState() => _DownloadLinksSheetState();
}

class _DownloadLinksSheetState extends State<_DownloadLinksSheet> {
  List<dynamic> _links = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLinks();
  }

  Future<void> _fetchLinks() async {
    try {
      final dio = Dio();
      final mediaType = widget.type == 'tv_episode' ? 'tv' : 'movie';
      String url =
          '${AppConfig.backendBaseUrl}/api/download-links/$mediaType/${widget.tmdbId}';
      if (widget.type == 'tv_episode' &&
          widget.season != null &&
          widget.episode != null) {
        url += '?season=${widget.season}&episode=${widget.episode}';
      }
      final response = await dio.get(url);
      final rawList = response.data as List? ?? [];
      if (mounted) {
        setState(() {
          _links = rawList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    Navigator.pop(context);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.surfaceDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.subtitle.isNotEmpty
        ? '${widget.title} · ${widget.subtitle}'
        : widget.title;
    final mediaType = widget.type == 'tv_episode' ? 'tv' : 'movie';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF444466),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.download_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          displayTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF888899),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Info notice
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.open_in_browser_rounded,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Links open in your browser. Download availability depends on the source.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2A2A3E), height: 24),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (_links.isEmpty)
              _buildEmptyState()
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _links.length,
                  itemBuilder: (context, idx) {
                    final link = _links[idx];
                    final serverName =
                        link['server_name'] as String? ?? 'Mirror';
                    final serverIcon = link['server_icon'] as String? ?? '🔗';
                    final downloadUrl = link['download_url'] as String? ?? '';
                    final quality = link['quality'] as String? ?? '1080p';
                    final lang = link['language'] as String? ?? 'English';
                    final size = link['file_size'] as String? ?? '';
                    final notes = link['notes'] as String? ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariantDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            serverIcon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        serverName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '$quality · $lang${size.isNotEmpty ? ' · $size' : ''}${notes.isNotEmpty ? ' · $notes' : ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: const Color(0xFF888899),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(80),
                          ),
                        ),
                        child: Text(
                          'Get Link',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      onTap: () => _open(context, downloadUrl),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF888899),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No download links added yet',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'An admin can add download links via the Download Manager in the Admin Panel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF888899),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

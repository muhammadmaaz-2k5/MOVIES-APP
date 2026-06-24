import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';

class DetailTrailersWidget extends StatelessWidget {
  final List<Map<String, dynamic>> trailers;

  const DetailTrailersWidget({super.key, required this.trailers});

  Future<void> _launchYoutube(String key) async {
    final appUrl = Uri.parse('youtube://www.youtube.com/watch?v=$key');
    final webUrl = Uri.parse('https://www.youtube.com/watch?v=$key');
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showAllTrailers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AllTrailersSheet(trailers: trailers, onPlay: _launchYoutube),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (trailers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.play_circle_filled_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trailers & Videos',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              if (trailers.length > 1)
                GestureDetector(
                  onTap: () => _showAllTrailers(context),
                  child: Text(
                    'See all ${trailers.length}',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: trailers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final trailer = trailers[i];
              final key = trailer['key'] as String? ?? '';
              return _TrailerCard(trailer: trailer, onTap: () => _launchYoutube(key));
            },
          ),
        ),
      ],
    );
  }
}

class _TrailerCard extends StatelessWidget {
  final Map<String, dynamic> trailer;
  final VoidCallback onTap;

  const _TrailerCard({required this.trailer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final key = trailer['key'] as String? ?? '';
    final thumbUrl = 'https://img.youtube.com/vi/$key/mqdefault.jpg';
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.network(
                    thumbUrl,
                    width: 200,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200,
                      height: 100,
                      color: AppTheme.surfaceVariantDark,
                      child: const Icon(Icons.play_circle_outline, color: Colors.white54, size: 40),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withAlpha(120)],
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 40),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(220),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'YT',
                        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trailer['name'] as String? ?? 'Trailer',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllTrailersSheet extends StatelessWidget {
  final List<Map<String, dynamic>> trailers;
  final Future<void> Function(String key) onPlay;

  const _AllTrailersSheet({required this.trailers, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF444466), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text(
                    'All Trailers & Videos',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${trailers.length} videos',
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF888899)),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A3E), height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: trailers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final trailer = trailers[i];
                  final key = trailer['key'] as String? ?? '';
                  final thumbUrl = 'https://img.youtube.com/vi/$key/mqdefault.jpg';
                  return GestureDetector(
                    onTap: () => onPlay(key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                thumbUrl,
                                width: 120,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 68,
                                  color: AppTheme.surfaceVariantDark,
                                ),
                              ),
                              const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 30),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trailer['name'] as String? ?? 'Trailer',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(200),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    trailer['type'] as String? ?? 'Trailer',
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/app_export.dart';

class DetailTrailersWidget extends StatelessWidget {
  final List<Map<String, dynamic>> trailers;

  const DetailTrailersWidget({super.key, required this.trailers});

  void _openPlayer(BuildContext context, int startIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(200),
      builder: (_) => _TrailerPlayerSheet(
        trailers: trailers,
        initialIndex: startIndex,
      ),
    );
  }

  void _showAllTrailers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AllTrailersSheet(
        trailers: trailers,
        onPlay: (i) {
          Navigator.pop(ctx);
          Future.delayed(const Duration(milliseconds: 200),
              () => _openPlayer(context, i));
        },
      ),
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
              const Icon(Icons.play_circle_filled_rounded,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Trailers & Videos',
                  style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              if (trailers.length > 1)
                GestureDetector(
                  onTap: () => _showAllTrailers(context),
                  child: Text('See all ${trailers.length}',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary)),
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
            itemBuilder: (context, i) => _TrailerCard(
              trailer: trailers[i],
              onTap: () => _openPlayer(context, i),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Thumbnail card ──────────────────────────────────────────────────────────

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
                      child: const Icon(Icons.play_circle_outline,
                          color: Colors.white54, size: 40),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(130)
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_filled_rounded,
                        color: Colors.white, size: 40),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(220),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('YT',
                          style: GoogleFonts.outfit(
                              fontSize: 9, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  Positioned(
                    bottom: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trailer['type'] as String? ?? 'Trailer',
                        style: GoogleFonts.outfit(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trailer['name'] as String? ?? 'Trailer',
              style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── In-app player bottom sheet ──────────────────────────────────────────────

class _TrailerPlayerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> trailers;
  final int initialIndex;

  const _TrailerPlayerSheet({required this.trailers, required this.initialIndex});

  @override
  State<_TrailerPlayerSheet> createState() => _TrailerPlayerSheetState();
}

class _TrailerPlayerSheetState extends State<_TrailerPlayerSheet> {
  late YoutubePlayerController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        enableCaption: false,
        playsInline: true,
      ),
    )..loadVideoById(videoId: _currentKey);
  }

  String get _currentKey =>
      widget.trailers[_currentIndex]['key'] as String? ?? '';

  void _switchTrailer(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _controller.loadVideoById(
        videoId: widget.trailers[index]['key'] as String? ?? '');
  }

  @override
  void dispose() {
    _controller.close();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final trailerName =
        widget.trailers[_currentIndex]['name'] as String? ?? 'Trailer';
    final trailerType =
        widget.trailers[_currentIndex]['type'] as String? ?? 'Trailer';

    return Container(
      height: screenHeight * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF12121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF444466),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Player
          YoutubePlayerControllerProvider(
            controller: _controller,
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trailerName,
                          style: GoogleFonts.outfit(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(200),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(trailerType,
                            style: GoogleFonts.outfit(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF2A2A3E), height: 1),

          // Playlist
          if (widget.trailers.length > 1) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.queue_music_rounded,
                      color: Color(0xFF888899), size: 16),
                  const SizedBox(width: 6),
                  Text('More Videos',
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: const Color(0xFF888899))),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: widget.trailers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = widget.trailers[i];
                  final tKey = t['key'] as String? ?? '';
                  final tName = t['name'] as String? ?? 'Trailer';
                  final tType = t['type'] as String? ?? 'Trailer';
                  final isActive = i == _currentIndex;
                  final thumb =
                      'https://img.youtube.com/vi/$tKey/default.jpg';

                  return GestureDetector(
                    onTap: () => _switchTrailer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primary.withAlpha(30)
                            : AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.primary.withAlpha(100)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  thumb,
                                  width: 80, height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80, height: 52,
                                    color: AppTheme.surfaceDark),
                                ),
                                Icon(
                                  isActive
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_filled_rounded,
                                  color: isActive
                                      ? AppTheme.primary
                                      : Colors.white70,
                                  size: isActive ? 28 : 24,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isActive
                                          ? AppTheme.primary
                                          : Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(tType,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFF888899))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}

// ─── See-all trailers sheet ───────────────────────────────────────────────────

class _AllTrailersSheet extends StatelessWidget {
  final List<Map<String, dynamic>> trailers;
  final void Function(int index) onPlay;

  const _AllTrailersSheet({required this.trailers, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFF444466),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Text('All Trailers & Videos',
                      style: GoogleFonts.outfit(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const Spacer(),
                  Text('${trailers.length} videos',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFF888899))),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A3E), height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: trailers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = trailers[i];
                  final tKey = t['key'] as String? ?? '';
                  final tName = t['name'] as String? ?? 'Trailer';
                  final tType = t['type'] as String? ?? 'Trailer';
                  final thumb =
                      'https://img.youtube.com/vi/$tKey/mqdefault.jpg';

                  return GestureDetector(
                    onTap: () => onPlay(i),
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
                                thumb,
                                width: 130, height: 78,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    width: 130, height: 78,
                                    color: AppTheme.surfaceDark),
                              ),
                              const Icon(Icons.play_circle_filled_rounded,
                                  color: Colors.white, size: 34),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tName,
                                      style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(200),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(tType,
                                        style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
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

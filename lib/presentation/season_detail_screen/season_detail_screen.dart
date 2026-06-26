import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../utils/app_actions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Season Detail Screen
// Route extra: {
//   'showId':       int,
//   'showTitle':    String,
//   'seasonNumber': int,
//   'seasonName':   String,
//   'posterPath':   String,
//   'overview':     String,
//   'airDate':      String,
//   'episodeCount': int,
// }
// ─────────────────────────────────────────────────────────────────────────────

class SeasonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> season;

  const SeasonDetailScreen({super.key, required this.season});

  @override
  State<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends State<SeasonDetailScreen> {
  static const String _tmdbBase  = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  static const String _bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1YmM0ZDAzZGU2MzY1YTBlZWY3ZDBhNGM0YTdkMDAyYiIsIm5iZiI6MTc1NTg2NzY0NS40ODg5OTk4LCJzdWIiOiI2OGE4NjlmZGI0NWEzOGEyNWMyNjEzYWEiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0._zPoKSHku3D5XAsfQ-L46MTKvJTs6cOB07Ij386z4OA';

  late final Dio _dio;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _episodes = [];

  // Currently selected / playing episode
  Map<String, dynamic>? _selectedEpisode;
  bool _isPlayerExpanded = false;

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $_bearerToken'}));
    _fetchEpisodes();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchEpisodes() async {
    setState(() { _isLoading = true; _error = null; });
    final showId       = widget.season['showId']       as int?  ?? 0;
    final seasonNumber = widget.season['seasonNumber'] as int?  ?? 1;
    try {
      final resp = await _dio.get(
        '$_tmdbBase/tv/$showId/season/$seasonNumber',
      );
      final data     = resp.data as Map<String, dynamic>;
      final rawList  = (data['episodes'] as List? ?? []);
      final episodes = rawList.map<Map<String, dynamic>>((e) {
        final stillPath = e['still_path'] as String?;
        return {
          'id':             e['id'],
          'name':           e['name'] ?? 'Episode ${e['episode_number']}',
          'episodeNumber':  e['episode_number'] ?? 0,
          'overview':       e['overview'] ?? '',
          'runtime':        e['runtime'] as int?,
          'airDate':        e['air_date'] ?? '',
          'rating':         (e['vote_average'] as num?)?.toDouble() ?? 0.0,
          'stillUrl':       stillPath != null ? '$_imageBase/w300$stillPath' : '',
          'semanticLabel':  'Still from episode ${e['episode_number']}',
          'guestStars':     (e['guest_stars'] as List? ?? [])
              .take(3)
              .map((g) => g['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList(),
        };
      }).toList();
      if (mounted) {
        setState(() {
          _episodes = episodes;
          _isLoading = false;
          // Auto-select first episode
          if (episodes.isNotEmpty) _selectedEpisode = episodes.first;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = 'Failed to load episodes.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final season     = widget.season;
    final posterPath = season['posterPath'] as String?;
    final posterUrl  = posterPath != null && posterPath.isNotEmpty
        ? '$_imageBase/w342$posterPath'
        : null;
    final seasonName = season['seasonName'] as String?   ?? 'Season';
    final showTitle  = season['showTitle']  as String?   ?? '';
    final overview   = season['overview']   as String?   ?? '';
    final airDate    = season['airDate']    as String?   ?? '';
    final epCount    = season['episodeCount'] as int?    ?? 0;
    final year       = airDate.length >= 4 ? airDate.substring(0, 4) : '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Column(
        children: [
          // ── Video player area ──────────────────────────────────────────
          _PlayerArea(
            episode:     _selectedEpisode,
            isExpanded:  _isPlayerExpanded,
            onExpand:    () => setState(() => _isPlayerExpanded = !_isPlayerExpanded),
            onBack:      () => context.pop(),
            showTitle:   showTitle,
            seasonName:  seasonName,
          ),
          // ── Episode list / info ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _fetchEpisodes)
                    : _SeasonBody(
                        posterUrl:    posterUrl,
                        seasonName:   seasonName,
                        showTitle:    showTitle,
                        overview:     overview,
                        year:         year,
                        epCount:      epCount,
                        episodes:     _episodes,
                        selectedEp:   _selectedEpisode,
                        onEpTap:      (ep) => setState(() => _selectedEpisode = ep),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Video player area ────────────────────────────────────────────────────────

class _PlayerArea extends StatefulWidget {
  final Map<String, dynamic>? episode;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onBack;
  final String showTitle;
  final String seasonName;

  const _PlayerArea({
    required this.episode,
    required this.isExpanded,
    required this.onExpand,
    required this.onBack,
    required this.showTitle,
    required this.seasonName,
  });

  @override
  State<_PlayerArea> createState() => _PlayerAreaState();
}

class _PlayerAreaState extends State<_PlayerArea>
    with SingleTickerProviderStateMixin {
  bool _isPlaying    = false;
  bool _showControls = true;
  double _progress   = 0.0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    // Simulate progress when playing
    if (_isPlaying) _simulateProgress();
  }

  void _simulateProgress() async {
    while (_isPlaying && _progress < 1.0 && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && _isPlaying) setState(() => _progress += 0.005);
    }
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _showEpisodeSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF444466),
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Episode Settings', style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          ListTile(
            leading: const Icon(Icons.speed_rounded, color: Color(0xFF888899)),
            title: Text('Playback speed', style: GoogleFonts.outfit(color: Colors.white)),
            trailing: Text('1.0x', style: GoogleFonts.outfit(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(sheetCtx); showSpeedSheet(context); },
          ),
          ListTile(
            leading: const Icon(Icons.subtitles_rounded, color: Color(0xFF888899)),
            title: Text('Subtitles', style: GoogleFonts.outfit(color: Colors.white)),
            trailing: Text('Off', style: GoogleFonts.outfit(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(sheetCtx); showSubtitleSheet(context); },
          ),
          ListTile(
            leading: const Icon(Icons.audiotrack_rounded, color: Color(0xFF888899)),
            title: Text('Audio track', style: GoogleFonts.outfit(color: Colors.white)),
            trailing: Text('Default', style: GoogleFonts.outfit(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(sheetCtx); showAudioSheet(context); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ep         = widget.episode;
    final stillUrl   = ep?['stillUrl'] as String? ?? '';
    final epName     = ep?['name']    as String? ?? '';
    final epNum      = ep?['episodeNumber'] as int? ?? 0;
    final playerH    = widget.isExpanded
        ? MediaQuery.of(context).size.height * 0.55
        : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: playerH,
      color: Colors.black,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail / backdrop ─────────────────────────────────
            if (stillUrl.isNotEmpty)
              Image.network(stillUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _PlayerPlaceholder())
            else
              const _PlayerPlaceholder(),

            // ── Dark overlay ─────────────────────────────────────────
            Container(color: Colors.black.withAlpha(_isPlaying ? 80 : 140)),

            // ── Controls overlay ─────────────────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: _ControlsOverlay(
                isPlaying:   _isPlaying,
                progress:    _progress,
                epNum:       epNum,
                epName:      epName,
                showTitle:   widget.showTitle,
                seasonName:  widget.seasonName,
                isExpanded:  widget.isExpanded,
                onBack:      widget.onBack,
                onExpand:    widget.onExpand,
                onPlay:      _togglePlay,
                onSeek:      (v) => setState(() { _progress = v; }),
                onRewind:    () => setState(() => _progress = (_progress - 0.05).clamp(0.0, 1.0)),
                onForward:   () => setState(() => _progress = (_progress + 0.05).clamp(0.0, 1.0)),
                onSettings:  () => _showEpisodeSettings(context),
              ),
            ),

            // ── Buffering indicator (shown when "playing" + low progress) ─
            if (_isPlaying && _progress < 0.01)
              Center(
                child: FadeTransition(
                  opacity: _pulseCtrl,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Controls overlay ─────────────────────────────────────────────────────────

class _ControlsOverlay extends StatelessWidget {
  final bool   isPlaying;
  final double progress;
  final int    epNum;
  final String epName;
  final String showTitle;
  final String seasonName;
  final bool   isExpanded;
  final VoidCallback onBack;
  final VoidCallback onExpand;
  final VoidCallback onPlay;
  final VoidCallback onRewind;
  final VoidCallback onForward;
  final VoidCallback onSettings;
  final void Function(double) onSeek;

  const _ControlsOverlay({
    required this.isPlaying,   required this.progress,
    required this.epNum,       required this.epName,
    required this.showTitle,   required this.seasonName,
    required this.isExpanded,  required this.onBack,
    required this.onExpand,    required this.onPlay,
    required this.onSeek,      required this.onRewind,
    required this.onForward,   required this.onSettings,
  });

  String _formatTime(double p, {bool total = false}) {
    // Fake duration: 45 min
    final totalSec = 45 * 60;
    final sec      = total ? totalSec : (p * totalSec).round();
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top bar ────────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _CircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$showTitle · $seasonName',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.white70),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('E$epNum · $epName',
                          style: GoogleFonts.outfit(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _CircleBtn(
                  icon: isExpanded
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  onTap: onExpand,
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // ── Centre play controls ───────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleBtn(icon: Icons.replay_10_rounded, size: 28, onTap: onRewind),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 16)],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black, size: 34,
                ),
              ),
            ),
            const SizedBox(width: 24),
            _CircleBtn(icon: Icons.forward_10_rounded, size: 28, onTap: onForward),
          ],
        ),

        const Spacer(),

        // ── Bottom progress bar ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight:       3,
                  thumbShape:        const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor:  AppTheme.primary,
                  inactiveTrackColor: Colors.white.withAlpha(60),
                  thumbColor:        Colors.white,
                  overlayColor:      AppTheme.primary.withAlpha(40),
                ),
                child: Slider(value: progress, onChanged: onSeek),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTime(progress),
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                  Row(children: [
                    _SmallBtn(icon: Icons.subtitles_outlined,
                        onTap: () => showSubtitleSheet(context)),
                    const SizedBox(width: 8),
                    _SmallBtn(icon: Icons.settings_outlined,
                        onTap: onSettings),
                    const SizedBox(width: 8),
                    _SmallBtn(icon: Icons.volume_up_rounded,
                        onTap: () => showVolumeSheet(context)),
                  ]),
                  Text(_formatTime(1.0, total: true),
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final double   size;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap, this.size = 22});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: size),
    ),
  );
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, color: Colors.white70, size: 18),
  );
}

class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF0D0D1A),
    child: const Center(child: Icon(Icons.play_circle_outline_rounded,
        color: Colors.white24, size: 64)),
  );
}

// ─── Season body (info + episode list) ───────────────────────────────────────

class _SeasonBody extends StatelessWidget {
  final String?  posterUrl;
  final String   seasonName;
  final String   showTitle;
  final String   overview;
  final String   year;
  final int      epCount;
  final List<Map<String, dynamic>> episodes;
  final Map<String, dynamic>?      selectedEp;
  final void Function(Map<String, dynamic>) onEpTap;

  const _SeasonBody({
    required this.posterUrl,   required this.seasonName,
    required this.showTitle,   required this.overview,
    required this.year,        required this.epCount,
    required this.episodes,    required this.selectedEp,
    required this.onEpTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Season header card ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: AppTheme.surfaceDark,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: posterUrl != null
                      ? Image.network(posterUrl!, width: 80, height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PosterPlaceholder())
                      : _PosterPlaceholder(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seasonName,
                          style: GoogleFonts.outfit(
                              fontSize: 17, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(showTitle,
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: const Color(0xFF888899)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        if (year.isNotEmpty) ...[
                          _Pill(label: year),
                          const SizedBox(width: 6),
                        ],
                        _Pill(label: '$epCount Episodes'),
                      ]),
                      if (overview.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(overview,
                            maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: const Color(0xFFAAAAAA),
                                height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Episodes header ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Row(children: [
              const Icon(Icons.video_library_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Episodes',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              Text('${episodes.length} ep',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888899))),
            ]),
          ),
        ),

        // ── Episode list ───────────────────────────────────────────
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _EpisodeTile(
              episode:    episodes[i],
              isSelected: selectedEp?['id'] == episodes[i]['id'],
              onTap:      () => onEpTap(episodes[i]),
            ),
            childCount: episodes.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 80, height: 120,
    color: AppTheme.surfaceVariantDark,
    child: const Icon(Icons.tv_rounded, color: Colors.white24, size: 28),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.surfaceVariantDark,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF444466)),
    ),
    child: Text(label,
        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF888899))),
  );
}

// ─── Episode tile ─────────────────────────────────────────────────────────────

class _EpisodeTile extends StatelessWidget {
  final Map<String, dynamic> episode;
  final bool       isSelected;
  final VoidCallback onTap;

  const _EpisodeTile({
    required this.episode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final epNum      = episode['episodeNumber'] as int?    ?? 0;
    final name       = episode['name']          as String? ?? '';
    final overview   = episode['overview']      as String? ?? '';
    final stillUrl   = episode['stillUrl']      as String? ?? '';
    final runtime    = episode['runtime']       as int?;
    final airDate    = episode['airDate']        as String? ?? '';
    final rating     = (episode['rating'] as num?)?.toDouble() ?? 0.0;
    final year       = airDate.length >= 4 ? airDate.substring(0, 4) : '';
    final guestStars = (episode['guestStars']   as List?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withAlpha(20)
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary.withAlpha(120) : const Color(0xFF2A2A3E),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail + info row ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(13),
                    bottomLeft: Radius.circular(13),
                  ),
                  child: Stack(
                    children: [
                      stillUrl.isNotEmpty
                          ? Image.network(stillUrl, width: 120, height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _StillPlaceholder())
                          : _StillPlaceholder(),
                      // Play overlay on selected
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withAlpha(100),
                            child: const Center(
                              child: Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                      // Episode number badge
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('E$epNum',
                              style: GoogleFonts.outfit(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Text info ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: Colors.white, height: 1.3)),
                        const SizedBox(height: 5),
                        Row(children: [
                          if (year.isNotEmpty) ...[
                            Text(year, style: GoogleFonts.outfit(
                                fontSize: 11, color: const Color(0xFF888899))),
                            const SizedBox(width: 8),
                          ],
                          if (runtime != null) ...[
                            const Icon(Icons.schedule_rounded,
                                color: Color(0xFF888899), size: 12),
                            const SizedBox(width: 3),
                            Text('${runtime}m', style: GoogleFonts.outfit(
                                fontSize: 11, color: const Color(0xFF888899))),
                            const SizedBox(width: 8),
                          ],
                          if (rating > 0) ...[
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFDAA07), size: 12),
                            const SizedBox(width: 3),
                            Text(rating.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                    fontSize: 11, color: const Color(0xFFFDAA07),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Overview ─────────────────────────────────────────
            if (overview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(overview,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: const Color(0xFF888899),
                        height: 1.4)),
              ),

            // ── Guest stars ──────────────────────────────────────
            if (guestStars.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      color: Color(0xFF666688), size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(guestStars.join(', '),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: const Color(0xFF666688))),
                  ),
                ]),
              ),

            // ── Action row: Watch + Download ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(children: [
                // Watch button — opens real WebView player
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      onTap(); // select locally
                      final showId    = episode['showId']    as int?;
                      final seasonNum = episode['seasonNum'] as int?;
                      final epNum2    = episode['episodeNumber'] as int? ?? 1;
                      if (showId != null && seasonNum != null) {
                        context.push(
                          AppRoutes.moviePlayerScreen,
                          extra: {
                            ...episode,
                            'type':    'tv',
                            'season':  seasonNum,
                            'episode': epNum2,
                            'id':      showId,
                          },
                        );
                      } else {
                        onTap();
                      }
                    },
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text('Watch',
                              style: GoogleFonts.outfit(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Download button
                SizedBox(
                  width: 34, height: 34,
                  child: DownloadButton(
                    tmdbId:    episode['id'] as int? ?? 0,
                    title:     name,
                    type:      'tv_episode',
                    posterUrl: stillUrl.isNotEmpty ? stillUrl : '',
                    subtitle:  'E$epNum',
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StillPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 120, height: 80,
    color: AppTheme.surfaceVariantDark,
    child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 28),
  );
}

// ─── Error / empty states ────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String    message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFF444466), size: 56),
      const SizedBox(height: 16),
      Text(message, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)),
      const SizedBox(height: 16),
      TextButton(
        onPressed: onRetry,
        child: Text('Retry', style: GoogleFonts.outfit(
            color: AppTheme.primary, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

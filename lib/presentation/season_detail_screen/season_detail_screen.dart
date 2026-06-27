import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_export.dart';
import '../movie_player_screen/movie_player_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Season Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class SeasonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> season;
  const SeasonDetailScreen({super.key, required this.season});

  @override
  State<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends State<SeasonDetailScreen> {
  static const String _tmdbBase    = 'https://api.themoviedb.org/3';
  static const String _imageBase   = 'https://image.tmdb.org/t/p';
  static const String _bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1YmM0ZDAzZGU2MzY1YTBlZWY3ZDBhNGM0YTdkMDAyYiIsIm5iZiI6MTc1NTg2NzY0NS40ODg5OTk4LCJzdWIiOiI2OGE4NjlmZGI0NWEzOGEyNWMyNjEzYWEiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0._zPoKSHku3D5XAsfQ-L46MTKvJTs6cOB07Ij386z4OA';

  late final Dio _dio;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _episodes = [];

  Map<String, dynamic>? _selectedEpisode;
  bool _playerVisible = false;  // show WebView player only after episode tap

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
    final showId       = widget.season['showId']       as int? ?? 0;
    final seasonNumber = widget.season['seasonNumber'] as int? ?? 1;
    try {
      final resp = await _dio.get('$_tmdbBase/tv/$showId/season/$seasonNumber');
      final rawList = (resp.data['episodes'] as List? ?? []);
      final episodes = rawList.map<Map<String, dynamic>>((e) {
        final stillPath = e['still_path'] as String?;
        return {
          'id':            e['id'],
          'showId':        showId,
          'seasonNum':     seasonNumber,
          'name':          e['name'] ?? 'Episode ${e['episode_number']}',
          'episodeNumber': e['episode_number'] ?? 0,
          'overview':      e['overview'] ?? '',
          'runtime':       e['runtime'] as int?,
          'airDate':       e['air_date'] ?? '',
          'rating':        (e['vote_average'] as num?)?.toDouble() ?? 0.0,
          'stillUrl':      stillPath != null ? '$_imageBase/w300$stillPath' : '',
          'semanticLabel': 'Still from episode ${e['episode_number']}',
          'guestStars':    (e['guest_stars'] as List? ?? [])
              .take(3)
              .map((g) => g['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList(),
        };
      }).toList();
      if (mounted) {
        setState(() {
          _episodes  = episodes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _error = 'Failed to load episodes.'; });
    }
  }

  void _selectEpisode(Map<String, dynamic> ep) {
    setState(() {
      _selectedEpisode = ep;
      _playerVisible   = true;
    });
    // Scroll to top
  }

  void _closePlayer() => setState(() {
    _playerVisible   = false;
    _selectedEpisode = null;
  });

  @override
  Widget build(BuildContext context) {
    final s          = widget.season;
    final posterPath = s['posterPath'] as String?;
    final posterUrl  = posterPath != null && posterPath.isNotEmpty
        ? '$_imageBase/w342$posterPath'
        : null;
    final seasonName = s['seasonName']    as String? ?? 'Season';
    final showTitle  = s['showTitle']     as String? ?? '';
    final overview   = s['overview']      as String? ?? '';
    final airDate    = s['airDate']       as String? ?? '';
    final epCount    = s['episodeCount']  as int?    ?? 0;
    final year       = airDate.length >= 4 ? airDate.substring(0, 4) : '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Column(children: [
        // ── Inline WebView player (shown after episode tap) ───────
        if (_playerVisible && _selectedEpisode != null)
          _InlinePlayer(
            episode:   _selectedEpisode!,
            showTitle: showTitle,
            onClose:   _closePlayer,
          ),

        // ── App bar (shown when player is hidden) ─────────────────
        if (!_playerVisible)
          _SeasonAppBar(
            title:     '$showTitle · $seasonName',
            onBack:    () => context.pop(),
          ),

        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _fetchEpisodes)
                  : _SeasonBody(
                      posterUrl:  posterUrl,
                      seasonName: seasonName,
                      showTitle:  showTitle,
                      overview:   overview,
                      year:       year,
                      epCount:    epCount,
                      episodes:   _episodes,
                      selectedEp: _selectedEpisode,
                      onEpTap:    _selectEpisode,
                    ),
        ),
      ]),
    );
  }
}

// ─── Inline WebView player ────────────────────────────────────────────────────

class _InlinePlayer extends StatefulWidget {
  final Map<String, dynamic> episode;
  final String showTitle;
  final VoidCallback onClose;
  const _InlinePlayer({
    required this.episode,
    required this.showTitle,
    required this.onClose,
  });

  @override
  State<_InlinePlayer> createState() => _InlinePlayerState();
}

class _InlinePlayerState extends State<_InlinePlayer> {
  late WebViewController _wvc;
  int  _serverIdx  = 0;
  bool _isLoading  = true;
  bool _hasError   = false;
  bool _isExpanded = false;

  int  get _showId   => widget.episode['showId']        as int? ?? 0;
  int  get _season   => widget.episode['seasonNum']     as int? ?? 1;
  int  get _epNumber => widget.episode['episodeNumber'] as int? ?? 1;
  String get _epName => widget.episode['name'] as String? ?? '';

  String get _url {
    final item = {
      'id':   _showId,
      'type': 'tv',
    };
    return kVideoServers[_serverIdx].buildUrl(
        item, season: _season, episode: _epNumber);
  }

  @override
  void initState() {
    super.initState();
    _initWvc();
  }

  void _initWvc() {
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _isLoading = true; _hasError = false; });
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() { _isLoading = false; _hasError = true; });
        },
      ))
      ..loadRequest(Uri.parse(_url));
  }

  void _switchServer(int idx) {
    if (idx == _serverIdx) return;
    setState(() { _serverIdx = idx; _isLoading = true; _hasError = false; });
    _wvc.loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    final playerH = _isExpanded
        ? MediaQuery.of(context).size.height * 0.6
        : MediaQuery.of(context).size.width * 9 / 16;
    final server = kVideoServers[_serverIdx];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: playerH,
      color: Colors.black,
      child: Column(children: [
        // ── Player WebView ─────────────────────────────────────
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            WebViewWidget(controller: _wvc),

            // Loading
            if (_isLoading)
              Container(color: Colors.black,
                child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                    const SizedBox(height: 10),
                    Text('Loading ${server.label}…',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                  ],
                ))),

            // Error
            if (_hasError && !_isLoading)
              Container(color: Colors.black,
                child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 40),
                    const SizedBox(height: 8),
                    Text('Stream unavailable', style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _PillBtn(label: 'Retry', icon: Icons.refresh_rounded,
                          onTap: () { setState(() { _isLoading = true; _hasError = false; }); _wvc.reload(); }),
                      const SizedBox(width: 10),
                      _PillBtn(label: 'Next Server', icon: Icons.swap_horiz_rounded,
                          onTap: () => _switchServer((_serverIdx + 1) % kVideoServers.length)),
                    ]),
                  ],
                ))),
          ]),
        ),

        // ── Player control bar ─────────────────────────────────
        Container(
          color: const Color(0xFF0D0D1A),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            // Back/close
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70, size: 24)),
            const SizedBox(width: 10),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.showTitle,
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: Colors.white54),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('S$_season E$_epNumber · $_epName',
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Server indicator
            GestureDetector(
              onTap: () => _showServerSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primary.withAlpha(80)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(server.icon, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(server.label,
                      style: GoogleFonts.outfit(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded,
                      color: AppTheme.primary, size: 12),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Expand
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Icon(
                _isExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 8),
            // Reload
            GestureDetector(
              onTap: () { setState(() { _isLoading = true; _hasError = false; }); _wvc.reload(); },
              child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20)),
          ]),
        ),
      ]),
    );
  }

  void _showServerSheet(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              const Icon(Icons.dns_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Select Server', style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
          ...List.generate(kVideoServers.length, (i) {
            final s        = kVideoServers[i];
            final isActive = i == _serverIdx;
            return ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary.withAlpha(30) : AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(s.icon,
                    style: const TextStyle(fontSize: 18)))),
              title: Text(s.label, style: GoogleFonts.outfit(
                  color: isActive ? AppTheme.primary : Colors.white,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
              trailing: isActive
                  ? Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: AppTheme.primary, shape: BoxShape.circle))
                  : null,
              onTap: () {
                Navigator.pop(sheetCtx);
                _switchServer(i);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─── Season app bar ───────────────────────────────────────────────────────────

class _SeasonAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _SeasonAppBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Season body ──────────────────────────────────────────────────────────────

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
    required this.posterUrl,  required this.seasonName,
    required this.showTitle,  required this.overview,
    required this.year,       required this.epCount,
    required this.episodes,   required this.selectedEp,
    required this.onEpTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      // ── Season info header ─────────────────────────────────────
      SliverToBoxAdapter(
        child: Container(
          color: AppTheme.surfaceDark,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: posterUrl != null
                  ? Image.network(posterUrl!, width: 80, height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PosterPlaceholder())
                  : _PosterPlaceholder(),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seasonName, style: GoogleFonts.outfit(
                    fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(showTitle, style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF888899)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  if (year.isNotEmpty) ...[
                    _Pill(label: year), const SizedBox(width: 6)],
                  _Pill(label: '$epCount ep'),
                ]),
                if (overview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(overview, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFFAAAAAA), height: 1.4)),
                ],
              ],
            )),
          ]),
        ),
      ),

      // ── Episodes section header ────────────────────────────────
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(children: [
            const Icon(Icons.video_library_rounded,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text('Episodes', style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const Spacer(),
            Text('${episodes.length} ep', style: GoogleFonts.outfit(
                fontSize: 12, color: const Color(0xFF888899))),
          ]),
        ),
      ),

      // ── Episode list ───────────────────────────────────────────
      if (episodes.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text('No episodes found', style: GoogleFonts.outfit(
                  color: const Color(0xFF888899))),
            ),
          ),
        )
      else
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

      const SliverToBoxAdapter(child: SizedBox(height: 60)),
    ]);
  }
}

// ─── Episode tile ─────────────────────────────────────────────────────────────

class _EpisodeTile extends StatelessWidget {
  final Map<String, dynamic> episode;
  final bool         isSelected;
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
    final guestStars = (episode['guestStars'] as List?)?.cast<String>() ?? [];

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
            color: isSelected
                ? AppTheme.primary.withAlpha(120)
                : const Color(0xFF2A2A3E),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Thumbnail + info ───────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft:    Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
              child: Stack(children: [
                stillUrl.isNotEmpty
                    ? Image.network(stillUrl, width: 120, height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _StillPlaceholder())
                    : _StillPlaceholder(),
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withAlpha(100),
                      child: const Center(child: Icon(
                          Icons.play_arrow_rounded, color: Colors.white, size: 30)))),
                Positioned(top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text('E$epNum', style: GoogleFonts.outfit(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white)))),
              ]),
            ),
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
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
                    Text(rating.toStringAsFixed(1), style: GoogleFonts.outfit(
                        fontSize: 11, color: const Color(0xFFFDAA07),
                        fontWeight: FontWeight.w600)),
                  ],
                ]),
              ]),
            )),
          ]),

          // ── Overview ────────────────────────────────────────
          if (overview.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(overview, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF888899), height: 1.4))),

          // ── Guest stars ──────────────────────────────────────
          if (guestStars.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(children: [
                const Icon(Icons.person_outline_rounded,
                    color: Color(0xFF666688), size: 12),
                const SizedBox(width: 4),
                Expanded(child: Text(guestStars.join(', '),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: const Color(0xFF666688)))),
              ])),

          // ── Action row ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTap, // tapping "Watch" selects + shows inline player
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isSelected
                            ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(isSelected ? 'Now Playing' : 'Watch',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 34, height: 34,
                child: DownloadButton(
                  tmdbId:    episode['showId'] as int? ?? 0,
                  title:     name,
                  type:      'tv_episode',
                  posterUrl: stillUrl,
                  subtitle:  'E$epNum',
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Small shared widgets ─────────────────────────────────────────────────────

class _PosterPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 80, height: 120,
    decoration: BoxDecoration(
      color: AppTheme.surfaceVariantDark,
      borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.tv_rounded, color: Colors.white24, size: 28));
}

class _StillPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 120, height: 80,
    color: AppTheme.surfaceVariantDark,
    child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 28));
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
      border: Border.all(color: const Color(0xFF444466))),
    child: Text(label, style: GoogleFonts.outfit(
        fontSize: 11, color: const Color(0xFF888899))));
}

class _PillBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withAlpha(80))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppTheme.primary, size: 14),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.outfit(
            color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
      ])));
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
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
            color: AppTheme.primary, fontWeight: FontWeight.w600))),
    ]));
}

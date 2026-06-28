import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import '../../core/app_export.dart';
import '../../utils/app_actions.dart';

// ─── Server model ─────────────────────────────────────────────────────────────

class VideoServer {
  final String name;
  final String label;
  final String icon;
  final String movieUrlTemplate;
  final String tvUrlTemplate;

  const VideoServer({
    required this.name,
    required this.label,
    required this.icon,
    required this.movieUrlTemplate,
    required this.tvUrlTemplate,
  });

  factory VideoServer.fromJson(Map<String, dynamic> json) {
    return VideoServer(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      movieUrlTemplate: json['movie_url_template'] as String? ?? '',
      tvUrlTemplate: json['tv_url_template'] as String? ?? '',
    );
  }

  String buildUrl(Map<String, dynamic> item, {int? season, int? episode}) {
    final id = item['id'] as int? ?? 0;
    final type = item['type'] as String? ?? 'movie';
    if (type == 'tv' && season != null && episode != null) {
      return tvUrlTemplate
          .replaceAll('{id}', id.toString())
          .replaceAll('{season}', season.toString())
          .replaceAll('{episode}', episode.toString());
    }
    return movieUrlTemplate.replaceAll('{id}', id.toString());
  }
}

const List<VideoServer> kVideoServers = [
  VideoServer(
    name: 'vidfast',
    label: 'VidFast',
    icon: '⚡',
    movieUrlTemplate: 'https://vidfast.pro/movie/{id}?autoPlay=true&theme=6C5CE7',
    tvUrlTemplate: 'https://vidfast.pro/tv/{id}/{season}/{episode}?autoPlay=true&theme=6C5CE7&nextButton=true&autoNext=true'
  )
];

// ─────────────────────────────────────────────────────────────────────────────
// Movie / Episode Player Screen
// Route extra: item map (same schema as detail screen)
// Optional: 'season' (int), 'episode' (int) for TV episodes
// ─────────────────────────────────────────────────────────────────────────────

class MoviePlayerScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const MoviePlayerScreen({super.key, required this.item});

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  late WebViewController _controller;
  List<VideoServer> _servers = [];
  bool   _isLoadingServers = true;
  int    _serverIndex  = 0;
  bool   _isLoading    = true;
  bool   _hasError     = false;
  bool   _nudgeShown   = false;  // rotate-to-fullscreen nudge

  // For TV episodes passed via item map
  int? get _season  => widget.item['season']  as int?;
  int? get _episode => widget.item['episode'] as int?;

  String get _currentUrl =>
      _servers[_serverIndex].buildUrl(
        widget.item,
        season:  _season,
        episode: _episode,
      );

  @override
  void initState() {
    super.initState();
    // Unlock all orientations so user can rotate freely
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadDynamicServers();
    // Show nudge after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_nudgeShown) {
        setState(() => _nudgeShown = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _nudgeShown = false);
        });
      }
    });
  }

  Future<void> _loadDynamicServers() async {
    try {
      final dio = Dio();
      final id = widget.item['id'] ?? 0;
      final type = widget.item['type'] ?? 'movie';
      final url = '${AppConfig.backendBaseUrl}/api/config/servers?id=$id&type=$type&season=${_season ?? ''}&episode=${_episode ?? ''}';
      
      final response = await dio.get(url);
      final rawList = response.data as List? ?? [];
      final parsed = rawList.map((s) => VideoServer.fromJson(s as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _servers = parsed;
          _isLoadingServers = false;
        });
        if (_servers.isNotEmpty) {
          _initController();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _servers = const [
            VideoServer(
              name: 'vidfast',
              label: 'VidFast',
              icon: '⚡',
              movieUrlTemplate: 'https://vidfast.pro/movie/{id}?autoPlay=true&theme=6C5CE7',
              tvUrlTemplate: 'https://vidfast.pro/tv/{id}/{season}/{episode}?autoPlay=true&theme=6C5CE7&nextButton=true&autoNext=true'
            )
          ];
          _isLoadingServers = false;
        });
        _initController();
      }
    }
  }

  @override
  void dispose() {
    // Restore portrait-only on exit
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _enterLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitLandscape() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _initController() {
    _controller = WebViewController()
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
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _switchServer(int idx) {
    if (idx == _serverIndex) return;
    setState(() {
      _serverIndex = idx;
      _isLoading   = true;
      _hasError    = false;
    });
    _controller.loadRequest(Uri.parse(_currentUrl));
  }

  void _reload() {
    setState(() { _isLoading = true; _hasError = false; });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingServers) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return OrientationBuilder(builder: (context, orientation) {
      final isLandscape = orientation == Orientation.landscape;
      final server      = _servers[_serverIndex];

      // ── LANDSCAPE: fullscreen immersive player ──────────────────
      if (isLandscape) {
        // Hide system UI for true immersive
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(fit: StackFit.expand, children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              _LoadingOverlay(serverLabel: server.label),
            if (_hasError && !_isLoading)
              _ErrorOverlay(
                onRetry:      _reload,
                onNextServer: () => _switchServer((_serverIndex + 1) % _servers.length),
              ),
            // Exit-fullscreen pill (bottom-right, auto-fades)
            Positioned(
              bottom: 16, right: 16,
              child: GestureDetector(
                onTap: _exitLandscape,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(40)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.fullscreen_exit_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text('Exit fullscreen',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.white70)),
                  ]),
                ),
              ),
            ),
            // Server badge top-left
            Positioned(
              top: 16, left: 16,
              child: SafeArea(child: GestureDetector(
                onTap: () => _showServerSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withAlpha(80)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(server.icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(server.label, style: GoogleFonts.outfit(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded,
                        color: AppTheme.primary, size: 12),
                  ]),
                ),
              )),
            ),
          ]),
        );
      }

      // ── PORTRAIT: player + info panel ─────────────────────────
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      final title   = widget.item['title']   as String? ?? '';
      final type    = widget.item['type']    as String? ?? 'movie';
      final year    = widget.item['year']    as String? ?? '';
      final runtime = widget.item['runtime'] as String? ?? '';
      final isTv    = type == 'tv';

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(title, isTv, year, runtime, server),
        body: Stack(children: [
          Column(children: [
            // ── Video WebView ──────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  _LoadingOverlay(serverLabel: server.label),
                if (_hasError && !_isLoading)
                  _ErrorOverlay(
                    onRetry:      _reload,
                    onNextServer: () => _switchServer((_serverIndex + 1) % _servers.length),
                  ),
                // Fullscreen button
                Positioned(bottom: 8, right: 8,
                  child: GestureDetector(
                    onTap: _enterLandscape,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.fullscreen_rounded,
                          color: Colors.white, size: 20)))),
              ]),
            ),

            // ── Info + server panel ────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + meta
                    Text(title, style: GoogleFonts.outfit(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: Colors.white),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (isTv && _season != null) ...[
                        _MetaBadge(label: 'S$_season E$_episode',
                            color: AppTheme.secondary),
                        const SizedBox(width: 8),
                      ],
                      if (year.isNotEmpty) _MetaBadge(label: year),
                      if (runtime.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _MetaBadge(label: runtime),
                      ],
                    ]),
                    const SizedBox(height: 18),

                    // Server selector
                    Row(children: [
                      const Icon(Icons.dns_rounded, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 6),
                      Text('Select Server', style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: List.generate(_servers.length, (i) {
                        final s        = _servers[i];
                        final isActive = i == _serverIndex;
                        return GestureDetector(
                          onTap: () => _switchServer(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primary.withAlpha(30)
                                  : AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.primary
                                    : const Color(0xFF2A2A3E),
                                width: isActive ? 1.5 : 1,
                              ),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(s.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.label, style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.w700 : FontWeight.w500,
                                      color: isActive
                                          ? AppTheme.primary : Colors.white)),
                                  if (isActive)
                                    Text('Active', style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: AppTheme.primary.withAlpha(180))),
                                ],
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(
                                        color: AppTheme.primary.withAlpha(150),
                                        blurRadius: 6)],
                                  ),
                                ),
                              ],
                            ]),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF2A2A3E)),
                    const SizedBox(height: 12),

                    // Action row
                    Row(children: [
                      Expanded(child: _ActionTile(
                        icon: Icons.open_in_browser_rounded,
                        label: 'Open in browser',
                        onTap: () => openInBrowser(_currentUrl),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _ActionTile(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onTap: () => shareItem(widget.item),
                      )),
                    ]),

                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Report submitted. Thank you!',
                              style: GoogleFonts.outfit()),
                          backgroundColor: AppTheme.surfaceDark,
                        ),
                      ),
                      child: Row(children: [
                        const Icon(Icons.report_outlined,
                            color: Color(0xFF666688), size: 14),
                        const SizedBox(width: 6),
                        Text('Report broken stream', style: GoogleFonts.outfit(
                            fontSize: 12, color: const Color(0xFF666688))),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          // ── Rotate-to-fullscreen nudge ─────────────────────
          if (_nudgeShown)
            _RotateNudge(onTap: _enterLandscape),
        ]),
      );
    });
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
          ...List.generate(_servers.length, (i) {
            final s        = _servers[i];
            final isActive = i == _serverIndex;
            return ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary.withAlpha(30)
                      : AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(10)),
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
              onTap: () { Navigator.pop(sheetCtx); _switchServer(i); },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    String title, bool isTv, String year, String runtime, VideoServer server) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(children: [
            Text('${server.icon} ${server.label}',
                style: GoogleFonts.outfit(
                    fontSize: 10, color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
            if (_isLoading) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 10, height: 10,
                child: CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 1.5),
              ),
            ],
          ]),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          onPressed: _reload,
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
          onPressed: () => showPlayerMoreSheet(context, widget.item),
          padding: const EdgeInsets.only(right: 8),
        ),
      ],
    );
  }
}

// ─── Overlay widgets ──────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  final String serverLabel;
  const _LoadingOverlay({required this.serverLabel});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
        const SizedBox(height: 12),
        Text('Loading $serverLabel…',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
      ],
    )),
  );
}

class _ErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onNextServer;
  const _ErrorOverlay({required this.onRetry, required this.onNextServer});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 48),
        const SizedBox(height: 12),
        Text('Failed to load player',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Try a different server',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _PlayerBtn(label: 'Retry', icon: Icons.refresh_rounded, onTap: onRetry),
          const SizedBox(width: 12),
          _PlayerBtn(label: 'Next Server', icon: Icons.swap_horiz_rounded, onTap: onNextServer),
        ]),
      ],
    )),
  );
}

/// Animated nudge pill suggesting to rotate to landscape
class _RotateNudge extends StatelessWidget {
  final VoidCallback onTap;
  const _RotateNudge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0, right: 0,
      // sits just below the 16:9 video area
      top: MediaQuery.of(context).size.width * 9 / 16 - 18,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E).withAlpha(230),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withAlpha(100)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withAlpha(80), blurRadius: 12)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.screen_rotation_rounded,
                  color: AppTheme.primary, size: 14),
              const SizedBox(width: 6),
              Text('Rotate for fullscreen',
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(width: 6),
              const Icon(Icons.fullscreen_rounded,
                  color: AppTheme.primary, size: 14),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _MetaBadge({required this.label, this.color = const Color(0xFF444466)});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Text(label, style: GoogleFonts.outfit(
        fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}

class _PlayerBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PlayerBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withAlpha(80)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(
            color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: const Color(0xFF888899), size: 20),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.outfit(
            fontSize: 11, color: const Color(0xFF888899))),
      ]),
    ),
  );
}

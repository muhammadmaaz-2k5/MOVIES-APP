import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_export.dart';
import '../../utils/app_actions.dart';

// ─── Server model ─────────────────────────────────────────────────────────────

class VideoServer {
  final String name;
  final String label;
  final String icon;
  final String Function(Map<String, dynamic> item, {int? season, int? episode}) buildUrl;

  const VideoServer({
    required this.name,
    required this.label,
    required this.icon,
    required this.buildUrl,
  });
}

// ─── Available servers ────────────────────────────────────────────────────────

final List<VideoServer> kVideoServers = [
  VideoServer(
    name: 'vidfast',
    label: 'VidFast',
    icon: '⚡',
    buildUrl: (item, {season, episode}) {
      final id   = item['id'] as int? ?? 0;
      final type = item['type'] as String? ?? 'movie';
      final theme = '6C5CE7'; // matches AppTheme.primary
      if (type == 'tv' && season != null && episode != null) {
        return 'https://vidfast.pro/tv/$id/$season/$episode?autoPlay=true&theme=$theme&nextButton=true&autoNext=true';
      }
      return 'https://vidfast.pro/movie/$id?autoPlay=true&theme=$theme';
    },
  ),
  VideoServer(
    name: 'vidsrc',
    label: 'VidSrc',
    icon: '🎬',
    buildUrl: (item, {season, episode}) {
      final id   = item['id'] as int? ?? 0;
      final type = item['type'] as String? ?? 'movie';
      if (type == 'tv' && season != null && episode != null) {
        return 'https://vidsrc.xyz/embed/tv?tmdb=$id&season=$season&episode=$episode';
      }
      return 'https://vidsrc.xyz/embed/movie?tmdb=$id';
    },
  ),
  VideoServer(
    name: 'superembed',
    label: 'SuperEmbed',
    icon: '🚀',
    buildUrl: (item, {season, episode}) {
      final id   = item['id'] as int? ?? 0;
      final type = item['type'] as String? ?? 'movie';
      if (type == 'tv' && season != null && episode != null) {
        return 'https://multiembed.mov/directstream.php?video_id=$id&tmdb=1&s=$season&e=$episode';
      }
      return 'https://multiembed.mov/directstream.php?video_id=$id&tmdb=1';
    },
  ),
  VideoServer(
    name: 'embed2',
    label: 'Embed2',
    icon: '📺',
    buildUrl: (item, {season, episode}) {
      final id   = item['id'] as int? ?? 0;
      final type = item['type'] as String? ?? 'movie';
      if (type == 'tv' && season != null && episode != null) {
        return 'https://www.2embed.cc/embedtv/$id&s=$season&e=$episode';
      }
      return 'https://www.2embed.cc/embed/$id';
    },
  ),
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
  int    _serverIndex  = 0;
  bool   _isLoading    = true;
  bool   _hasError     = false;

  // For TV episodes passed via item map
  int? get _season  => widget.item['season']  as int?;
  int? get _episode => widget.item['episode'] as int?;

  String get _currentUrl =>
      kVideoServers[_serverIndex].buildUrl(
        widget.item,
        season:  _season,
        episode: _episode,
      );

  @override
  void initState() {
    super.initState();
    _initController();
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
    final title    = widget.item['title']   as String? ?? '';
    final type     = widget.item['type']    as String? ?? 'movie';
    final year     = widget.item['year']    as String? ?? '';
    final runtime  = widget.item['runtime'] as String? ?? '';
    final isTv     = type == 'tv';
    final VideoServer server = kVideoServers[_serverIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(title, isTv, year, runtime, server),
      body: Column(
        children: [
          // ── Video WebView area ─────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WebViewWidget(controller: _controller),

                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: AppTheme.primary, strokeWidth: 2),
                          const SizedBox(height: 12),
                          Text('Loading ${server.label}…',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                // Error overlay
                if (_hasError && !_isLoading)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.white38, size: 48),
                          const SizedBox(height: 12),
                          Text('Failed to load player',
                              style: GoogleFonts.outfit(
                                  color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Try a different server',
                              style: GoogleFonts.outfit(
                                  color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PlayerBtn(label: 'Retry', icon: Icons.refresh_rounded,
                                  onTap: _reload),
                              const SizedBox(width: 12),
                              _PlayerBtn(label: 'Next Server',
                                  icon: Icons.swap_horiz_rounded,
                                  onTap: () => _switchServer(
                                      (_serverIndex + 1) % kVideoServers.length)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Server selector + info panel ───────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + meta
                  Text(title,
                      style: GoogleFonts.outfit(
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
                    const Icon(Icons.dns_rounded,
                        color: AppTheme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text('Select Server',
                        style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(kVideoServers.length, (i) {
                      final s        = kVideoServers[i];
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
                            Text(s.icon,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.label,
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isActive
                                            ? AppTheme.primary
                                            : Colors.white)),
                                if (isActive)
                                  Text('Active',
                                      style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: AppTheme.primary
                                              .withAlpha(180))),
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
                  // Report bad stream
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
                      Text('Report broken stream',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: const Color(0xFF666688))),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
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

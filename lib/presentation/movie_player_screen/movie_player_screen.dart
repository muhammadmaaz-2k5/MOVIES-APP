import 'dart:async';
import 'dart:math';

import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../utils/app_actions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Movie Player Screen
// Route extra: {
//   'title':      String,
//   'backdropUrl': String,
//   'year':       String,
//   'runtime':    String,
// }
// ─────────────────────────────────────────────────────────────────────────────

class MoviePlayerScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const MoviePlayerScreen({super.key, required this.item});

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen>
    with SingleTickerProviderStateMixin {
  bool   _isPlaying    = false;
  bool   _showControls = true;
  double _progress     = 0.0;
  bool   _isMuted      = false;
  bool   _isFullscreen = false;
  Timer? _hideTimer;
  Timer? _progressTimer;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startProgress();
      _scheduleHide();
    } else {
      _progressTimer?.cancel();
      _hideTimer?.cancel();
      setState(() => _showControls = true);
    }
  }

  void _startProgress() {
    _progressTimer?.cancel();
    _progressTimer =
        Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final inc = 0.003 + Random().nextDouble() * 0.004;
      final np  = (_progress + inc).clamp(0.0, 1.0);
      setState(() => _progress = np);
      if (np >= 1.0) {
        _progressTimer?.cancel();
        setState(() { _isPlaying = false; _showControls = true; });
      }
    });
  }

  void _seek(double v) {
    setState(() => _progress = v);
    if (_isPlaying) _scheduleHide();
  }

  void _skip(double delta) {
    setState(() => _progress = (_progress + delta).clamp(0.0, 1.0));
    _scheduleHide();
  }

  String _formatTime(double p, {bool total = false}) {
    // Derive fake duration from runtime string, fallback 120 min
    final runtime = widget.item['runtime'] as String? ?? '';
    int totalMin = 120;
    final match = RegExp(r'(\d+)').firstMatch(runtime);
    if (match != null) totalMin = int.tryParse(match.group(1)!) ?? 120;
    final totalSec = totalMin * 60;
    final sec = total ? totalSec : (p * totalSec).round();
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title      = widget.item['title']       as String? ?? '';
    final backdropUrl = widget.item['backdropUrl'] as String? ?? '';
    final year       = widget.item['year']         as String? ?? '';
    final runtime    = widget.item['runtime']      as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video area ────────────────────────────────────────────
            if (backdropUrl.isNotEmpty)
              Image.network(backdropUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _BlackScreen())
            else
              const _BlackScreen(),

            // ── Gradient overlay ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(_isPlaying ? 80 : 160),
                    Colors.transparent,
                    Colors.black.withAlpha(_isPlaying ? 100 : 180),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // ── Buffering spinner ─────────────────────────────────────
            if (_isPlaying && _progress < 0.01)
              Center(
                child: FadeTransition(
                  opacity: _pulseCtrl,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle),
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                ),
              ),

            // ── Controls overlay ──────────────────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Column(children: [
                // ── Top bar ───────────────────────────────────────────
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      _NavBtn(icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => context.pop()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title,
                                style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (year.isNotEmpty || runtime.isNotEmpty)
                              Text(
                                [year, runtime]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                      _NavBtn(icon: Icons.cast_rounded,
                          onTap: () => showCastSheet(context)),
                      const SizedBox(width: 8),
                      _NavBtn(
                        icon: _isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        onTap: () =>
                            setState(() => _isFullscreen = !_isFullscreen),
                      ),
                    ]),
                  ),
                ),

                const Spacer(),

                // ── Centre controls ───────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _NavBtn(icon: Icons.replay_10_rounded, size: 30,
                      onTap: () => _skip(-10 / (_totalSec))),
                  const SizedBox(width: 28),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 66, height: 66,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(100),
                              blurRadius: 20)
                        ],
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black, size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  _NavBtn(icon: Icons.forward_10_rounded, size: 30,
                      onTap: () => _skip(10 / (_totalSec))),
                ]),

                const Spacer(),

                // ── Bottom controls ───────────────────────────────────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(children: [
                      // Seek bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight:          3.5,
                          thumbShape:           const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                          overlayShape:         const RoundSliderOverlayShape(
                              overlayRadius: 16),
                          activeTrackColor:     AppTheme.primary,
                          inactiveTrackColor:   Colors.white.withAlpha(50),
                          thumbColor:           Colors.white,
                          overlayColor:         AppTheme.primary.withAlpha(40),
                        ),
                        child: Slider(
                            value: _progress, onChanged: _seek),
                      ),
                      // Time + extras
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatTime(_progress),
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: Colors.white70)),
                            Row(children: [
                              _SmallBtn(
                                icon: _isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                onTap: () =>
                                    setState(() => _isMuted = !_isMuted),
                              ),
                              const SizedBox(width: 14),
                              _SmallBtn(icon: Icons.subtitles_outlined,
                                  onTap: () => showSubtitleSheet(context)),
                              const SizedBox(width: 14),
                              _SmallBtn(icon: Icons.settings_outlined,
                                  onTap: () => _showSettings(context)),
                              const SizedBox(width: 14),
                              _SmallBtn(icon: Icons.more_vert_rounded,
                                  onTap: () => showPlayerMoreSheet(context, widget.item)),
                            ]),
                            Text(_formatTime(1.0, total: true),
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: Colors.white70)),
                          ]),
                    ]),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  int get _totalSec {
    final runtime = widget.item['runtime'] as String? ?? '120';
    final match   = RegExp(r'(\d+)').firstMatch(runtime);
    final min     = match != null ? int.tryParse(match.group(1)!) ?? 120 : 120;
    return min * 60;
  }

  void _showSettings(BuildContext context) {
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
            child: Text('Playback Settings', style: GoogleFonts.outfit(
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
            leading: const Icon(Icons.hd_rounded, color: Color(0xFF888899)),
            title: Text('Quality', style: GoogleFonts.outfit(color: Colors.white)),
            trailing: Text('Auto', style: GoogleFonts.outfit(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(sheetCtx); showQualitySheet(context); },
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
}

class _BlackScreen extends StatelessWidget {
  const _BlackScreen();

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: const Center(child: Icon(Icons.play_circle_outline_rounded,
        color: Colors.white24, size: 80)),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final double   size;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap, this.size = 20});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: Colors.black.withAlpha(120), shape: BoxShape.circle),
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
    child: Icon(icon, color: Colors.white70, size: 20),
  );
}



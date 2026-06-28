import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_export.dart';

// ─── Share ────────────────────────────────────────────────────────────────────

Future<void> shareItem(Map<String, dynamic> item, {BuildContext? context}) async {
  final title   = item['title']    as String? ?? 'Check this out';
  final type    = item['type']     as String? ?? 'movie';
  final id      = item['id']       as int?    ?? 0;
  final typeStr = type == 'tv' ? 'tv' : 'movie';
  final url     = 'https://www.themoviedb.org/$typeStr/$id';
  final text    = '🎬 $title\n\nWatch it on CineTrack!\n$url';

  Rect? sharePositionOrigin;
  if (context != null) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
    }
  }
  sharePositionOrigin ??= const Rect.fromLTWH(0, 0, 100, 100);

  try {
    // Invoke non-blocking to prevent UI thread lock
    Share.share(text, sharePositionOrigin: sharePositionOrigin);
  } catch (e) {
    debugPrint('Sharing failed: $e');
  }
}

Future<void> sharePerson(Map<String, dynamic> person, {BuildContext? context}) async {
  final name = person['name'] as String? ?? 'Actor';
  final id   = person['id']   as int?    ?? 0;
  final url  = 'https://www.themoviedb.org/person/$id';
  final text = '🎭 $name\n\nView on CineTrack!\n$url';

  Rect? sharePositionOrigin;
  if (context != null) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
    }
  }
  sharePositionOrigin ??= const Rect.fromLTWH(0, 0, 100, 100);

  try {
    Share.share(text, sharePositionOrigin: sharePositionOrigin);
  } catch (e) {
    debugPrint('Sharing failed: $e');
  }
}

// ─── Open in browser ─────────────────────────────────────────────────────────

Future<void> openInBrowser(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> openTmdbPage(Map<String, dynamic> item) async {
  final type = (item['type'] as String? ?? 'movie') == 'tv' ? 'tv' : 'movie';
  final id   = item['id'] as int? ?? 0;
  await openInBrowser('https://www.themoviedb.org/$type/$id');
}

// ─── "More" bottom sheet ──────────────────────────────────────────────────────

void showMoreMenu(BuildContext context, Map<String, dynamic> item) {
  final title   = item['title']  as String? ?? '';

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetCtx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF444466),
              borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(title,
              style: GoogleFonts.outfit(fontSize: 15,
                  fontWeight: FontWeight.w700, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const Divider(color: Color(0xFF2A2A3E), height: 1),
        _MoreTile(
          icon: Icons.share_rounded,
          label: 'Share',
          onTap: () { Navigator.pop(sheetCtx); shareItem(item, context: context); },
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// ─── Player bottom sheets ─────────────────────────────────────────────────────

void showSubtitleSheet(BuildContext context) {
  _showPickerSheet(
    context: context,
    title: 'Subtitles',
    icon: Icons.subtitles_rounded,
    options: const ['Off', 'English', 'Arabic', 'French', 'Spanish', 'Urdu', 'Hindi'],
    initialIndex: 0,
  );
}

void showAudioSheet(BuildContext context) {
  _showPickerSheet(
    context: context,
    title: 'Audio Track',
    icon: Icons.audiotrack_rounded,
    options: const ['Default', 'English', 'Arabic', 'French', 'Hindi', 'Urdu'],
    initialIndex: 0,
  );
}

void showSpeedSheet(BuildContext context) {
  _showPickerSheet(
    context: context,
    title: 'Playback Speed',
    icon: Icons.speed_rounded,
    options: const ['0.25x', '0.5x', '0.75x', '1.0x', '1.25x', '1.5x', '2.0x'],
    initialIndex: 3,
  );
}

void showQualitySheet(BuildContext context) {
  _showPickerSheet(
    context: context,
    title: 'Video Quality',
    icon: Icons.hd_rounded,
    options: const ['Auto', '1080p', '720p', '480p', '360p'],
    initialIndex: 0,
  );
}

void showVolumeSheet(BuildContext context) {
  _showPickerSheet(
    context: context,
    title: 'Volume',
    icon: Icons.volume_up_rounded,
    options: const ['Muted', '25%', '50%', '75%', '100%'],
    initialIndex: 4,
  );
}

void showCastSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF444466),
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            const Icon(Icons.cast_rounded, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            Text('Cast to device', style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        const Divider(color: Color(0xFF2A2A3E), height: 1),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Icon(Icons.cast_connected_rounded,
                color: const Color(0xFF444466), size: 56),
            const SizedBox(height: 16),
            Text('No devices found',
                style: GoogleFonts.outfit(fontSize: 15,
                    fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Make sure your device is on the same Wi-Fi network',
                style: GoogleFonts.outfit(fontSize: 12,
                    color: const Color(0xFF888899)),
                textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// ─── Player more-options sheet ────────────────────────────────────────────────

void showPlayerMoreSheet(BuildContext context, Map<String, dynamic> item) {
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
        _MoreTile(icon: Icons.share_rounded, label: 'Share',
            onTap: () { Navigator.pop(sheetCtx); shareItem(item, context: context); }),
        _MoreTile(icon: Icons.speed_rounded, label: 'Playback speed',
            onTap: () { Navigator.pop(sheetCtx); showSpeedSheet(context); }),
        _MoreTile(icon: Icons.loop_rounded, label: 'Loop video',
            onTap: () { Navigator.pop(sheetCtx); }),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

void _showPickerSheet({
  required BuildContext context,
  required String       title,
  required IconData     icon,
  required List<String> options,
  required int          initialIndex,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _PickerSheet(
        title: title, icon: icon,
        options: options, initialIndex: initialIndex),
  );
}

class _PickerSheet extends StatefulWidget {
  final String       title;
  final IconData     icon;
  final List<String> options;
  final int          initialIndex;
  const _PickerSheet({required this.title, required this.icon,
      required this.options, required this.initialIndex});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late int _selected;

  @override
  void initState() { super.initState(); _selected = widget.initialIndex; }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF444466),
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(children: [
            Icon(widget.icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(widget.title, style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        const Divider(color: Color(0xFF2A2A3E), height: 1),
        ...List.generate(widget.options.length, (i) {
          final isSelected = i == _selected;
          return ListTile(
            title: Text(widget.options[i], style: GoogleFonts.outfit(
                color: isSelected ? AppTheme.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
            trailing: isSelected
                ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                : null,
            onTap: () {
              setState(() => _selected = i);
              Future.delayed(const Duration(milliseconds: 180),
                  () => Navigator.pop(context));
            },
          );
        }),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _MoreTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: const Color(0xFF888899)),
    title: Text(label, style: GoogleFonts.outfit(color: Colors.white)),
    onTap: onTap,
  );
}

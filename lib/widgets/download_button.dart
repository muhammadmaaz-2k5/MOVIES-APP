import 'package:google_fonts/google_fonts.dart';

import '../core/app_export.dart';
import '../services/download_manager.dart';

/// A self-contained download button that shows state and opens quality picker.
class DownloadButton extends StatefulWidget {
  final int    tmdbId;
  final String title;
  final String type;       // 'movie' | 'tv_episode'
  final String posterUrl;
  final String subtitle;   // episode label, empty for movies

  const DownloadButton({
    super.key,
    required this.tmdbId,
    required this.title,
    required this.type,
    required this.posterUrl,
    this.subtitle = '',
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  @override
  void initState() {
    super.initState();
    DownloadManager.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    DownloadManager.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  DownloadItem? get _anyItem {
    final dm = DownloadManager.instance;
    for (final q in ['1080p', '720p', '480p']) {
      final id = '${widget.type}_${widget.tmdbId}_$q';
      final item = dm.getItem(id);
      if (item != null) return item;
    }
    return null;
  }

  void _onTap() {
    final item = _anyItem;
    if (item == null) {
      _showQualityPicker();
      return;
    }
    switch (item.status) {
      case DownloadStatus.downloading:
        DownloadManager.instance.pause(item.id);
      case DownloadStatus.paused:
        DownloadManager.instance.resume(item.id);
      case DownloadStatus.completed:
        _showCompletedMenu(item);
      case DownloadStatus.failed:
        DownloadManager.instance.retry(item.id);
      case DownloadStatus.queued:
        DownloadManager.instance.cancel(item.id);
    }
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QualityPickerSheet(
        title: widget.title,
        onSelect: (quality) {
          DownloadManager.instance.addDownload(
            tmdbId:   widget.tmdbId,
            title:    widget.title,
            type:     widget.type,
            quality:  quality,
            posterUrl: widget.posterUrl,
            subtitle:  widget.subtitle,
          );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Download started ($quality)',
                style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.surfaceDark,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View',
              textColor: AppTheme.primary,
              onPressed: () => context.push(AppRoutes.downloadsScreen),
            ),
          ));
        },
      ),
    );
  }

  void _showCompletedMenu(DownloadItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF444466),
                  borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary),
            title: Text('Play offline', style: GoogleFonts.outfit(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Playing offline: ${item.title}',
                    style: GoogleFonts.outfit()),
                backgroundColor: AppTheme.surfaceDark,
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            title: Text('Delete download', style: GoogleFonts.outfit(color: Colors.white)),
            onTap: () {
              DownloadManager.instance.deleteCompleted(item.id);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _anyItem;
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: _bgColor(item),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor(item)),
        ),
        child: item != null && item.status == DownloadStatus.downloading
            ? Stack(alignment: Alignment.center, children: [
                SizedBox(width: 28, height: 28,
                    child: CircularProgressIndicator(
                        value:       item.progress,
                        color:       AppTheme.primary,
                        backgroundColor: const Color(0xFF2A2A3E),
                        strokeWidth: 2.5)),
                Icon(_icon(item), color: _iconColor(item), size: 14),
              ])
            : Icon(_icon(item), color: _iconColor(item), size: 22),
      ),
    );
  }

  IconData _icon(DownloadItem? item) {
    if (item == null)                             return Icons.download_rounded;
    switch (item.status) {
      case DownloadStatus.queued:                 return Icons.hourglass_top_rounded;
      case DownloadStatus.downloading:            return Icons.pause_rounded;
      case DownloadStatus.paused:                 return Icons.play_arrow_rounded;
      case DownloadStatus.completed:              return Icons.download_done_rounded;
      case DownloadStatus.failed:                 return Icons.refresh_rounded;
    }
  }

  Color _iconColor(DownloadItem? item) {
    if (item == null)                             return const Color(0xFF888899);
    switch (item.status) {
      case DownloadStatus.completed:              return const Color(0xFF00C875);
      case DownloadStatus.failed:                 return Colors.redAccent;
      case DownloadStatus.paused:                 return const Color(0xFFFDAA07);
      default:                                    return AppTheme.primary;
    }
  }

  Color _bgColor(DownloadItem? item) {
    if (item?.status == DownloadStatus.completed) {
      return const Color(0xFF00C875).withAlpha(20);
    }
    if (item?.status == DownloadStatus.downloading ||
        item?.status == DownloadStatus.paused) {
      return AppTheme.primary.withAlpha(20);
    }
    return AppTheme.surfaceDark;
  }

  Color _borderColor(DownloadItem? item) {
    if (item?.status == DownloadStatus.completed) {
      return const Color(0xFF00C875).withAlpha(80);
    }
    if (item?.status == DownloadStatus.downloading ||
        item?.status == DownloadStatus.paused) {
      return AppTheme.primary.withAlpha(80);
    }
    return const Color(0xFF444466);
  }
}

// ─── Quality picker sheet ─────────────────────────────────────────────────────

class _QualityPickerSheet extends StatelessWidget {
  final String   title;
  final void Function(String) onSelect;

  const _QualityPickerSheet({required this.title, required this.onSelect});

  static const _qualities = [
    _Q('1080p HD',  '1080p', '~1.8 GB',  Icons.hd_rounded),
    _Q('720p',      '720p',  '~900 MB',  Icons.sd_rounded),
    _Q('480p',      '480p',  '~400 MB',  Icons.sd_card_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF444466),
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(children: [
              Text('Download Quality', style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(title, style: GoogleFonts.outfit(
                  fontSize: 13, color: const Color(0xFF888899)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          ..._qualities.map((q) => ListTile(
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(q.icon, color: AppTheme.primary, size: 22),
            ),
            title: Text(q.label, style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(q.size, style: GoogleFonts.outfit(
                color: const Color(0xFF888899), fontSize: 12)),
            trailing: const Icon(Icons.download_rounded,
                color: Color(0xFF888899), size: 20),
            onTap: () {
              Navigator.pop(context);
              onSelect(q.value);
            },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _Q {
  final String   label;
  final String   value;
  final String   size;
  final IconData icon;
  const _Q(this.label, this.value, this.size, this.icon);
}

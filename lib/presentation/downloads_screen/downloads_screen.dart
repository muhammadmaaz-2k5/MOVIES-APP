import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/download_manager.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    DownloadManager.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _tab.dispose();
    DownloadManager.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final dm       = DownloadManager.instance;
    final active   = dm.items.where((d) =>
        d.status != DownloadStatus.completed).toList();
    final done     = dm.completed;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        title: Row(children: [
          const Icon(Icons.download_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 8),
          Text('Downloads', style: GoogleFonts.outfit(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        actions: [
          if (done.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context),
              child: Text('Clear all', style: GoogleFonts.outfit(
                  fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF888899),
          labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
          dividerColor: const Color(0xFF2A2A3E),
          tabs: [
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Completed (${done.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildActiveList(active),
          _buildCompletedList(done),
        ],
      ),
    );
  }

  Widget _buildActiveList(List<DownloadItem> items) {
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.download_outlined,
        message: 'No active downloads',
        sub: 'Downloads you start will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) => _ActiveTile(item: items[i]),
    );
  }

  Widget _buildCompletedList(List<DownloadItem> items) {
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        message: 'No completed downloads',
        sub: 'Finished downloads will show here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) => _CompletedTile(item: items[i]),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Clear completed?', style: GoogleFonts.outfit(
            color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This will remove all completed downloads from the list.',
            style: GoogleFonts.outfit(color: const Color(0xFF888899))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF888899)))),
          TextButton(
            onPressed: () {
              DownloadManager.instance.clearCompleted();
              Navigator.pop(context);
            },
            child: Text('Clear', style: GoogleFonts.outfit(
                color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Active download tile ──────────────────────────────────────────────────────

class _ActiveTile extends StatelessWidget {
  final DownloadItem item;
  const _ActiveTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final dm = DownloadManager.instance;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Row(
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.posterUrl.isNotEmpty
                ? Image.network(item.posterUrl, width: 52, height: 74,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Placeholder())
                : _Placeholder(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 14,
                        fontWeight: FontWeight.w600, color: Colors.white)),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF888899))),
                ],
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.status == DownloadStatus.queued ? null : item.progress,
                    backgroundColor: const Color(0xFF2A2A3E),
                    color: item.status == DownloadStatus.paused
                        ? const Color(0xFFFDAA07)
                        : AppTheme.primary,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.statusLabel,
                        style: GoogleFonts.outfit(fontSize: 11,
                            color: _statusColor(item.status))),
                    Text(item.sizeLabel,
                        style: GoogleFonts.outfit(fontSize: 11,
                            color: const Color(0xFF888899))),
                  ],
                ),
                const SizedBox(height: 2),
                _QualityBadge(quality: item.quality),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Controls
          Column(
            children: [
              if (item.status == DownloadStatus.downloading)
                _IconBtn(icon: Icons.pause_rounded,
                    onTap: () => dm.pause(item.id))
              else if (item.status == DownloadStatus.paused)
                _IconBtn(icon: Icons.play_arrow_rounded,
                    onTap: () => dm.resume(item.id))
              else if (item.status == DownloadStatus.failed)
                _IconBtn(icon: Icons.refresh_rounded,
                    onTap: () => dm.retry(item.id)),
              const SizedBox(height: 6),
              _IconBtn(icon: Icons.close_rounded,
                  color: Colors.redAccent.withAlpha(180),
                  onTap: () => dm.cancel(item.id)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(DownloadStatus s) {
    switch (s) {
      case DownloadStatus.downloading: return AppTheme.primary;
      case DownloadStatus.paused:      return const Color(0xFFFDAA07);
      case DownloadStatus.failed:      return Colors.redAccent;
      default:                         return const Color(0xFF888899);
    }
  }
}

// ─── Completed tile ────────────────────────────────────────────────────────────

class _CompletedTile extends StatelessWidget {
  final DownloadItem item;
  const _CompletedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Row(
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.posterUrl.isNotEmpty
                ? Image.network(item.posterUrl, width: 52, height: 74,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Placeholder())
                : _Placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 14,
                        fontWeight: FontWeight.w600, color: Colors.white)),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF888899))),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF00C875), size: 13),
                  const SizedBox(width: 4),
                  Text('Downloaded · ${item.fileSizeMb} MB',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: const Color(0xFF00C875))),
                  const SizedBox(width: 8),
                  _QualityBadge(quality: item.quality),
                ]),
                if (item.completedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(_formatDate(item.completedAt!),
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: const Color(0xFF666688))),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(children: [
            _IconBtn(
              icon: Icons.play_arrow_rounded,
              color: AppTheme.primary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playing offline: ${item.title}',
                        style: GoogleFonts.outfit()),
                    backgroundColor: AppTheme.surfaceDark,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            _IconBtn(
              icon: Icons.delete_outline_rounded,
              color: Colors.redAccent.withAlpha(180),
              onTap: () => DownloadManager.instance.deleteCompleted(item.id),
            ),
          ]),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours < 1)    return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)     return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Shared small widgets ──────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 52, height: 74,
    color: AppTheme.surfaceVariantDark,
    child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 20),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap,
      this.color = const Color(0xFF888899)});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantDark,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}

class _QualityBadge extends StatelessWidget {
  final String quality;
  const _QualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.primary.withAlpha(30),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: AppTheme.primary.withAlpha(80)),
    ),
    child: Text(quality, style: GoogleFonts.outfit(
        fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary)),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  final String   sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: const Color(0xFF444466), size: 64),
      const SizedBox(height: 16),
      Text(message, style: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 8),
      Text(sub, style: GoogleFonts.outfit(
          fontSize: 13, color: const Color(0xFF888899))),
    ]),
  );
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Download state enum ──────────────────────────────────────────────────────

enum DownloadStatus { queued, downloading, paused, completed, failed }

// ─── Download item model ──────────────────────────────────────────────────────

class DownloadItem {
  final String id;          // unique: "${type}_${tmdbId}_${quality}"
  final int    tmdbId;
  final String title;
  final String type;        // 'movie' | 'tv_episode'
  final String quality;     // '1080p' | '720p' | '480p'
  final String posterUrl;
  final String subtitle;    // e.g. "S1 E3" for episodes, "" for movies
  final int    fileSizeMb;  // simulated

  DownloadStatus status;
  double         progress;  // 0.0 – 1.0
  DateTime?      completedAt;

  DownloadItem({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.type,
    required this.quality,
    required this.posterUrl,
    required this.subtitle,
    required this.fileSizeMb,
    this.status   = DownloadStatus.queued,
    this.progress = 0.0,
    this.completedAt,
  });

  DownloadItem copyWith({DownloadStatus? status, double? progress, DateTime? completedAt}) =>
      DownloadItem(
        id: id, tmdbId: tmdbId, title: title, type: type,
        quality: quality, posterUrl: posterUrl, subtitle: subtitle,
        fileSizeMb: fileSizeMb,
        status:      status      ?? this.status,
        progress:    progress    ?? this.progress,
        completedAt: completedAt ?? this.completedAt,
      );

  String get statusLabel {
    switch (status) {
      case DownloadStatus.queued:      return 'Queued';
      case DownloadStatus.downloading: return 'Downloading…';
      case DownloadStatus.paused:      return 'Paused';
      case DownloadStatus.completed:   return 'Downloaded';
      case DownloadStatus.failed:      return 'Failed';
    }
  }

  String get sizeLabel {
    if (status == DownloadStatus.completed) return '$fileSizeMb MB';
    final done = (progress * fileSizeMb).round();
    return '$done / $fileSizeMb MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'tmdbId': tmdbId, 'title': title, 'type': type,
    'quality': quality, 'posterUrl': posterUrl, 'subtitle': subtitle,
    'fileSizeMb': fileSizeMb,
    'status': status.index, 'progress': progress,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
    id:          j['id']          as String,
    tmdbId:      j['tmdbId']      as int,
    title:       j['title']       as String,
    type:        j['type']        as String,
    quality:     j['quality']     as String,
    posterUrl:   j['posterUrl']   as String,
    subtitle:    j['subtitle']    as String,
    fileSizeMb:  j['fileSizeMb']  as int,
    status:      DownloadStatus.values[j['status'] as int],
    progress:    (j['progress']   as num).toDouble(),
    completedAt: j['completedAt'] != null
        ? DateTime.tryParse(j['completedAt'] as String)
        : null,
  );
}

// ─── Download manager singleton ───────────────────────────────────────────────

class DownloadManager extends ChangeNotifier {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  static const String _prefKey = 'downloads_v1';
  static const int    _maxConcurrent = 2;

  final List<DownloadItem> _items = [];
  final Map<String, Timer> _timers = {};

  List<DownloadItem> get items => List.unmodifiable(_items);

  List<DownloadItem> get activeDownloads =>
      _items.where((d) => d.status == DownloadStatus.downloading).toList();

  List<DownloadItem> get completed =>
      _items.where((d) => d.status == DownloadStatus.completed).toList();

  // ── Initialise from persisted state ────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_prefKey) ?? [];
    for (final s in raw) {
      try {
        final item = DownloadItem.fromJson(
            Map<String, dynamic>.from(_decodeJson(s)));
        // Resume downloading ones as paused on restart
        if (item.status == DownloadStatus.downloading) {
          _items.add(item.copyWith(status: DownloadStatus.paused));
        } else {
          _items.add(item);
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  // ── Check if already queued/downloaded ─────────────────────────────────────

  bool isQueued(String id) =>
      _items.any((d) => d.id == id && d.status != DownloadStatus.failed);

  DownloadItem? getItem(String id) =>
      _items.where((d) => d.id == id).firstOrNull;

  // ── Add new download ────────────────────────────────────────────────────────

  void addDownload({
    required int    tmdbId,
    required String title,
    required String type,
    required String quality,
    required String posterUrl,
    String          subtitle = '',
  }) {
    final id   = '${type}_${tmdbId}_$quality';
    if (isQueued(id)) return;

    final size = quality == '1080p' ? 1800 + Random().nextInt(600)
               : quality == '720p'  ? 900  + Random().nextInt(300)
               :                      400  + Random().nextInt(200);

    final item = DownloadItem(
      id: id, tmdbId: tmdbId, title: title, type: type,
      quality: quality, posterUrl: posterUrl, subtitle: subtitle,
      fileSizeMb: size,
    );
    _items.insert(0, item);
    notifyListeners();
    _persist();
    _processQueue();
  }

  // ── Pause ───────────────────────────────────────────────────────────────────

  void pause(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    _updateItem(id, status: DownloadStatus.paused);
    _persist();
  }

  // ── Resume ──────────────────────────────────────────────────────────────────

  void resume(String id) {
    _updateItem(id, status: DownloadStatus.queued);
    _persist();
    _processQueue();
  }

  // ── Cancel / delete ─────────────────────────────────────────────────────────

  void cancel(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    _items.removeWhere((d) => d.id == id);
    notifyListeners();
    _persist();
    _processQueue();
  }

  void deleteCompleted(String id) => cancel(id);

  void clearCompleted() {
    _items.removeWhere((d) => d.status == DownloadStatus.completed);
    notifyListeners();
    _persist();
  }

  // ── Retry failed ────────────────────────────────────────────────────────────

  void retry(String id) {
    _updateItem(id, status: DownloadStatus.queued, progress: 0);
    _persist();
    _processQueue();
  }

  // ── Internal: process queue ─────────────────────────────────────────────────

  void _processQueue() {
    final downloading = _items
        .where((d) => d.status == DownloadStatus.downloading)
        .length;
    if (downloading >= _maxConcurrent) return;

    final next = _items.firstWhere(
        (d) => d.status == DownloadStatus.queued,
        orElse: () => DownloadItem(
            id: '', tmdbId: 0, title: '', type: '', quality: '',
            posterUrl: '', subtitle: '', fileSizeMb: 0));
    if (next.id.isEmpty) return;

    _updateItem(next.id, status: DownloadStatus.downloading);
    _startSimulation(next.id);
  }

  void _startSimulation(String id) {
    // Tick every 400 ms, increment varies to mimic real network speed
    _timers[id] = Timer.periodic(const Duration(milliseconds: 400), (_) {
      final idx = _items.indexWhere((d) => d.id == id);
      if (idx == -1) { _timers[id]?.cancel(); return; }

      final item      = _items[idx];
      final increment = (0.008 + Random().nextDouble() * 0.018);
      final newProg   = (item.progress + increment).clamp(0.0, 1.0);

      if (newProg >= 1.0) {
        _timers[id]?.cancel();
        _timers.remove(id);
        _items[idx] = item.copyWith(
            status: DownloadStatus.completed,
            progress: 1.0,
            completedAt: DateTime.now());
        notifyListeners();
        _persist();
        _processQueue();
      } else {
        _items[idx] = item.copyWith(progress: newProg);
        notifyListeners();
        // Persist every ~5 ticks to avoid excessive writes
        if ((newProg * 100).round() % 10 == 0) _persist();
      }
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _updateItem(String id, {DownloadStatus? status, double? progress}) {
    final idx = _items.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(status: status, progress: progress);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = _items
        .where((d) => d.status != DownloadStatus.failed)
        .map((d) => _encodeJson(d.toJson()))
        .toList();
    await prefs.setStringList(_prefKey, list);
  }

  // Simple JSON encode/decode using dart:convert via string interpolation
  String _encodeJson(Map<String, dynamic> m) {
    final parts = m.entries.map((e) {
      final v = e.value;
      if (v == null)     return '"${e.key}":null';
      if (v is String)   return '"${e.key}":"${v.replaceAll('"', '\\"')}"';
      if (v is num)      return '"${e.key}":$v';
      if (v is bool)     return '"${e.key}":$v';
      return '"${e.key}":"$v"';
    }).join(',');
    return '{$parts}';
  }

  Map<String, dynamic> _decodeJson(String s) {
    // Use dart:convert indirectly via fromJson — simple split parse
    final trimmed = s.trim().replaceAll(RegExp(r'^\{|\}$'), '');
    final result  = <String, dynamic>{};
    // Minimal key-value parser for our known flat schema
    final re = RegExp(r'"(\w+)":(null|true|false|"[^"]*"|-?\d+(?:\.\d+)?)');
    for (final m in re.allMatches(trimmed)) {
      final key = m.group(1)!;
      final raw = m.group(2)!;
      if (raw == 'null')              { result[key] = null; }
      else if (raw == 'true')         { result[key] = true; }
      else if (raw == 'false')        { result[key] = false; }
      else if (raw.startsWith('"'))   { result[key] = raw.substring(1, raw.length - 1); }
      else if (raw.contains('.'))     { result[key] = double.parse(raw); }
      else                            { result[key] = int.parse(raw); }
    }
    return result;
  }
}

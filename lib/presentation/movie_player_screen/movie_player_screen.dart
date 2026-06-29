import 'dart:async';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    movieUrlTemplate:
        'https://vidfast.pro/movie/{id}?autoPlay=true&theme=6C5CE7',
    tvUrlTemplate:
        'https://vidfast.pro/tv/{id}/{season}/{episode}?autoPlay=true&theme=6C5CE7&nextButton=true&autoNext=true',
  ),
  VideoServer(
    name: 'vidsrc',
    label: 'VidSrc',
    icon: '▶',
    movieUrlTemplate: 'https://vidsrc.to/embed/movie/{id}',
    tvUrlTemplate: 'https://vidsrc.to/embed/tv/{id}/{season}/{episode}',
  ),
  VideoServer(
    name: 'vidlink',
    label: 'VidLink',
    icon: '⚡',
    movieUrlTemplate:
        'https://vidlink.pro/movie/{id}?primaryColor=B20710&secondaryColor=170000&icons=vid&iconColor=B20710&title=false&poster=true&autoplay=false&nextbutton=true',
    tvUrlTemplate:
        'https://vidlink.pro/tv/{id}/{season}/{episode}?primaryColor=B20710&secondaryColor=170000&icons=vid&iconColor=B20710&title=false&poster=true&autoplay=false&nextbutton=true',
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
  List<VideoServer> _servers = [];
  bool _isLoadingServers = true;
  int _serverIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _nudgeShown = false; // rotate-to-fullscreen nudge

  Timer? _timeoutTimer;
  bool _errorTriggered = false;
  int _savedPosition = 0;

  // For TV episodes passed via item map
  int? get _season => widget.item['season'] as int?;
  int? get _episode => widget.item['episode'] as int?;

  String get _currentUrl => _servers[_serverIndex].buildUrl(
    widget.item,
    season: _season,
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
      final url =
          '${AppConfig.backendBaseUrl}/api/config/servers?id=$id&type=$type&season=${_season ?? ''}&episode=${_episode ?? ''}';

      final response = await dio.get(url);
      final rawList = response.data as List? ?? [];
      final parsed = rawList
          .map((s) => VideoServer.fromJson(s as Map<String, dynamic>))
          .toList();
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
              name: 'vidsrc',
              label: 'VidSrc',
              icon: '▶',
              movieUrlTemplate: 'https://vidsrc.to/embed/movie/{id}',
              tvUrlTemplate:
                  'https://vidsrc.to/embed/tv/{id}/{season}/{episode}',
            ),
            VideoServer(
              name: 'vidlink',
              label: 'VidLink',
              icon: '⚡',
              movieUrlTemplate:
                  'https://vidlink.pro/movie/{id}?primaryColor=B20710&secondaryColor=170000&icons=vid&iconColor=B20710&title=false&poster=true&autoplay=false&nextbutton=true',
              tvUrlTemplate:
                  'https://vidlink.pro/tv/{id}/{season}/{episode}?primaryColor=B20710&secondaryColor=170000&icons=vid&iconColor=B20710&title=false&poster=true&autoplay=false&nextbutton=true',
            ),
            VideoServer(
              name: 'vidfast',
              label: 'VidFast',
              icon: '⚡',
              movieUrlTemplate:
                  'https://vidfast.pro/movie/{id}?autoPlay=true&theme=6C5CE7',
              tvUrlTemplate:
                  'https://vidfast.pro/tv/{id}/{season}/{episode}?autoPlay=true&theme=6C5CE7&nextButton=true&autoNext=true',
            ),
          ];
          _isLoadingServers = false;
        });
        _initController();
      }
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
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

  bool _detectVidsrc(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('vidsrc.icu') ||
        lowerUrl.contains('vidsrc.to') ||
        lowerUrl.contains('vidsrc.me') ||
        lowerUrl.contains('vidsrc.net') ||
        lowerUrl.contains('vidsrc.xyz') ||
        lowerUrl.contains('vidsrc.cc') ||
        lowerUrl.contains('vidfast.pro') ||
        lowerUrl.contains('vidlink.pro') ||
        lowerUrl.contains('vidsrc');
  }

  bool _detectDoodstream(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('doodstream.com') ||
        lowerUrl.contains('dsvplay.com') ||
        lowerUrl.contains('dood.to') ||
        lowerUrl.contains('ds2play.com') ||
        lowerUrl.contains('ds2video.com');
  }

  String? _getVideoHostingService(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('1drv.ms') ||
        lowerUrl.contains('onedrive.live.com') ||
        lowerUrl.contains('sharepoint.com')) {
      return 'onedrive';
    }

    if (lowerUrl.contains('doodstream.com') ||
        lowerUrl.contains('dsvplay.com') ||
        lowerUrl.contains('dood.to') ||
        lowerUrl.contains('ds2play.com') ||
        lowerUrl.contains('ds2video.com')) {
      return 'doodstream';
    }

    if (lowerUrl.contains('vidsrc.icu') ||
        lowerUrl.contains('vidsrc.to') ||
        lowerUrl.contains('vidsrc.me') ||
        lowerUrl.contains('vidsrc.net') ||
        lowerUrl.contains('vidsrc.xyz') ||
        lowerUrl.contains('vidsrc.cc') ||
        lowerUrl.contains('vidfast.pro') ||
        lowerUrl.contains('vidlink.pro') ||
        lowerUrl.contains('vidsrc')) {
      return 'vidsrc';
    }

    if (lowerUrl.contains('vidzee.wtf') ||
        lowerUrl.contains('player.vidzee.wtf')) {
      return 'vidzee';
    }

    if (lowerUrl.contains('videasy.net') ||
        lowerUrl.contains('player.videasy.net')) {
      return 'videasy';
    }

    if (lowerUrl.contains('vidnest.fun')) {
      return 'vidnest';
    }

    if (lowerUrl.contains('mixdrop.co') ||
        lowerUrl.contains('mixdrop.to') ||
        lowerUrl.contains('mixdrop.sx') ||
        lowerUrl.contains('mixdrop.bz')) {
      return 'mixdrop';
    }

    if (lowerUrl.contains('streamtape.com') ||
        lowerUrl.contains('streamtape.net') ||
        lowerUrl.contains('streamtape.to')) {
      return 'streamtape';
    }

    if (lowerUrl.contains('tiktok.com')) return 'tiktok';
    if (lowerUrl.contains('embedsito.com')) return 'embedsito';
    if (lowerUrl.contains('embed.su')) return 'embedsu';
    if (lowerUrl.contains('upstream.to')) return 'upstream';
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be'))
      return 'youtube';
    if (lowerUrl.contains('vimeo.com')) return 'vimeo';
    if (lowerUrl.contains('dailymotion.com')) return 'dailymotion';
    if (lowerUrl.contains('streamable.com')) return 'streamable';
    if (lowerUrl.contains('mdy48tn97.com')) return 'mdy48tn97';
    if (lowerUrl.contains('vidstream.pro')) return 'vidstream';
    if (lowerUrl.contains('gogo-stream.com')) return 'gogostream';
    if (lowerUrl.contains('mp4upload.com')) return 'mp4upload';
    if (lowerUrl.contains('streamlare.com')) return 'streamlare';
    if (lowerUrl.contains('filemoon.sx')) return 'filemoon';
    if (lowerUrl.contains('bilibili.tv') || lowerUrl.contains('bilibili.com'))
      return 'bilibili';

    if (lowerUrl.contains('cloudflare.com') ||
        lowerUrl.contains('cloudfront.net') ||
        lowerUrl.contains('googleapis.com') ||
        lowerUrl.contains('gstatic.com') ||
        lowerUrl.contains('jwpcdn.com') ||
        lowerUrl.contains('jwplatform.com')) {
      return 'cdn';
    }

    return null;
  }

  bool _isAllowedVideoHosting(String url) {
    return _getVideoHostingService(url) != null;
  }

  bool _shouldBlockNavigation(String url, String currentUrl, bool isVidsrc) {
    if (url == currentUrl) {
      return false;
    }

    final lowerUrl = url.toLowerCase();

    if (isVidsrc) {
      const strictBlockedPatterns = [
        'doubleclick.net',
        'googlesyndication.com',
        'google-analytics.com',
        'adservice.google',
        'facebook.com',
        'twitter.com',
        'instagram.com',
        'pinterest.com',
        'linkedin.com',
        'reddit.com',
        'tiktok.com',
        'snapchat.com',
        'play.google.com',
        'apps.apple.com',
        'itunes.apple.com',
      ];
      final shouldBlock = strictBlockedPatterns.any(
        (pattern) => lowerUrl.contains(pattern),
      );
      if (!shouldBlock) {
        return false;
      }
    }

    if (_isAllowedVideoHosting(url)) {
      return false;
    }

    const blockedPatterns = [
      'doubleclick.net',
      'googlesyndication.com',
      'google-analytics.com',
      'adservice.google',
      'advertising.com',
      'adnxs.com',
      'adsystem.com',
      'adsrvr.org',
      'adroll.com',
      'serving-sys.com',
      'adcolony.com',
      'applovin.com',
      'chartboost.com',
      'unity3d.com',
      'ironsrc.com',
      'facebook.com',
      'twitter.com',
      'instagram.com',
      'pinterest.com',
      'linkedin.com',
      'reddit.com',
      'tiktok.com',
      'snapchat.com',
      'play.google.com',
      'apps.apple.com',
      'itunes.apple.com',
    ];

    for (final pattern in blockedPatterns) {
      if (lowerUrl.contains(pattern)) {
        return true;
      }
    }

    if (lowerUrl.contains('/app/') || lowerUrl.contains('/apps/')) {
      return true;
    }

    return false;
  }

  String _buildHtmlContent(
    String processedUrl,
    bool isDoodstream,
    int savedPosition,
    bool isVidsrc,
  ) {
    final buffer = StringBuffer();
    buffer.write('<!DOCTYPE html>');
    buffer.write('<html><head>');
    buffer.write(
      '<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">',
    );
    buffer.write('<style>');
    buffer.write(
      'html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background-color: #000; display: flex; align-items: center; justify-content: center; }',
    );

    if (processedUrl.contains('youtube.com')) {
      buffer.write(
        'iframe { width: 100%; height: 100%; border: none; display: block; }',
      );
      buffer.write('.ytp-pause-overlay { display: none !important; }');
    } else if (isDoodstream) {
      buffer.write(
        'iframe { width: 100%; height: 100%; border: none; display: block; margin: 0 auto; }',
      );
    } else {
      buffer.write(
        'iframe { width: 100%; height: 100%; border: none; display: block; }',
      );
    }
    buffer.write('</style>');

    if (isDoodstream && savedPosition > 0) {
      buffer.write('<script>');
      buffer.write('''
          (function() {
              var savedPosition = $savedPosition;
              var positionRestored = false;
              var iframe = null;
              
              function tryRestorePosition() {
                  if (positionRestored || savedPosition <= 0) return;
                  
                  try {
                      iframe = document.querySelector('iframe');
                      if (!iframe) {
                          setTimeout(tryRestorePosition, 500);
                          return;
                      }
                      
                      try {
                          var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                          var video = iframeDoc.querySelector('video');
                          
                          if (video) {
                              video.currentTime = savedPosition;
                              positionRestored = true;
                              console.log('Position restored to: ' + savedPosition);
                          } else {
                              var players = iframeDoc.querySelectorAll('[class*="player"], [id*="player"], video, [class*="video"], [id*="video"]');
                              for (var i = 0; i < players.length; i++) {
                                  if (players[i].tagName === 'VIDEO' || players[i].currentTime !== undefined) {
                                      players[i].currentTime = savedPosition;
                                      positionRestored = true;
                                      console.log('Position restored to: ' + savedPosition);
                                      break;
                                  }
                              }
                          }
                      } catch (e) {
                          iframe.contentWindow.postMessage({
                              type: 'seek',
                              time: savedPosition
                          }, '*');
                          
                          setTimeout(function() {
                              try {
                                  var script = iframe.contentDocument.createElement('script');
                                  script.textContent = "if (document.querySelector('video')) { document.querySelector('video').currentTime = " + savedPosition + "; }";
                                  iframe.contentDocument.head.appendChild(script);
                              } catch (err) {
                                  console.log('Cannot inject script due to CORS');
                              }
                          }, 2000);
                      }
                  } catch (e) {
                      console.log('Error restoring position: ' + e.message);
                  }
              }
              
              window.addEventListener('load', function() {
                  setTimeout(tryRestorePosition, 1000);
                  setTimeout(tryRestorePosition, 3000);
                  setTimeout(tryRestorePosition, 5000);
              });
              
              document.addEventListener('DOMContentLoaded', function() {
                  setTimeout(tryRestorePosition, 1000);
              });
          })();
      ''');
      buffer.write('</script>');
    }

    final bodyStyle = isDoodstream
        ? "margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; display: flex; align-items: center; justify-content: center;"
        : "margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden;";

    buffer.write('</head><body style="$bodyStyle">');

    final iframeBaseStyle = isDoodstream
        ? "width: 100%; height: 100%; border: none; display: block; margin: 0 auto;"
        : "width: 100%; height: 100%; border: none; display: block;";

    buffer.write(
      '<iframe id="video-iframe" src="$processedUrl" allowfullscreen',
    );
    if (isVidsrc) {
      buffer.write(
        ' allow="autoplay; fullscreen; picture-in-picture; encrypted-media"',
      );
    }
    if (processedUrl.contains('youtube.com')) {
      buffer.write(
        ' allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"',
      );
    }
    buffer.write(' style="$iframeBaseStyle"></iframe>');

    if (isDoodstream) {
      buffer.write('<script>');
      buffer.write('''
          (function() {
              var videoUrl = '$processedUrl';
              var positionInterval = null;
              var lastSavedPosition = 0;
              
              function savePosition(position) {
                  if (position > 0 && Math.abs(position - lastSavedPosition) >= 5) {
                      lastSavedPosition = position;
                      
                      try {
                          if (window.Android && window.Android.postMessage) {
                              window.Android.postMessage(JSON.stringify({
                                  event: 'savePlaybackPosition',
                                  videoUrl: videoUrl,
                                  position: Math.floor(position)
                              }));
                          }
                      } catch (e) {
                          console.log('Error calling Android postMessage: ' + e.message);
                      }
                  }
              }
              
              function trackPosition() {
                  try {
                      var iframe = document.getElementById('video-iframe');
                      if (!iframe) return;
                      
                      try {
                          var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                          var video = iframeDoc.querySelector('video');
                          
                          if (video) {
                              if (!video.paused) {
                                  savePosition(video.currentTime);
                              }
                          }
                      } catch (e) {
                          iframe.contentWindow.postMessage({type: 'getCurrentTime'}, '*');
                      }
                  } catch (e) {
                      console.log('Error tracking position: ' + e.message);
                  }
              }
              
              window.addEventListener('message', function(event) {
                  if (event.data && event.data.type === 'currentTime') {
                      savePosition(event.data.time);
                  }
              });
              
              if (positionInterval) clearInterval(positionInterval);
              positionInterval = setInterval(trackPosition, 5000);
              
              window.addEventListener('beforeunload', function() {
                  trackPosition();
              });
          })();
      ''');
      buffer.write('</script>');
    }

    buffer.write('</body></html>');
    return buffer.toString();
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'playback_position_\${_currentUrl.hashCode}';
      final val = prefs.getInt(key) ?? 0;
      if (mounted) {
        setState(() {
          _savedPosition = val;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePlaybackPosition(String url, int position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'playback_position_\${url.hashCode}';
      await prefs.setInt(key, position);
    } catch (_) {}
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _errorTriggered = false;

    final isVidsrc = _detectVidsrc(_currentUrl);

    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && _isLoading && !_errorTriggered) {
        setState(() {
          _isLoading = false;
        });
        if (!isVidsrc) {
          setState(() {
            _hasError = true;
            _errorTriggered = true;
          });
          _autoSwitchServer();
        } else {
          setState(() {
            _hasError = false;
          });
        }
      }
    });
  }

  void _autoSwitchServer() {
    if (_servers.length <= 1) return;
    final nextIdx = (_serverIndex + 1) % _servers.length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Server \${_servers[_serverIndex].label} failed. Switching to \${_servers[nextIdx].label}...',
          style: GoogleFonts.outfit(),
        ),
        backgroundColor: AppTheme.surfaceDark,
        duration: const Duration(seconds: 2),
      ),
    );

    _switchServer(nextIdx);
  }

  void _checkVideoAvailability() {
    final isVidsrc = _detectVidsrc(_currentUrl);
    if (isVidsrc) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        }
      });
      return;
    }

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      try {
        final result = await _controller.runJavaScriptReturningResult('''
            (function() {
                try {
                    var iframe = document.getElementById('video-iframe');
                    if (!iframe) {
                        return JSON.stringify({hasVideo: false, reason: 'no_iframe'});
                    }
                    
                    try {
                        var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                        var video = iframeDoc.querySelector('video');
                        var hasVideo = video !== null;
                        
                        var bodyText = iframeDoc.body ? iframeDoc.body.innerText.toLowerCase() : '';
                        var hasError = bodyText.includes('error') || 
                                       bodyText.includes('not found') || 
                                       bodyText.includes('404') ||
                                       bodyText.includes('unavailable') ||
                                       bodyText.includes('not available');
                        
                        return JSON.stringify({
                            hasVideo: hasVideo && !hasError,
                            reason: hasError ? 'error_page' : (hasVideo ? 'video_found' : 'no_video')
                        });
                    } catch (e) {
                        return JSON.stringify({hasVideo: true, reason: 'cors_blocked'});
                    }
                } catch (e) {
                    return JSON.stringify({hasVideo: false, reason: 'check_failed'});
                }
            })();
        ''');

        final resultStr = result.toString().replaceAll('"', '').trim();
        final hasVideo =
            resultStr.contains('hasVideo:true') ||
            resultStr.contains('reason:cors_blocked') ||
            resultStr.contains('reason:check_failed');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (!hasVideo && !_errorTriggered) {
            setState(() {
              _hasError = true;
              _errorTriggered = true;
            });
            _autoSwitchServer();
          } else {
            setState(() {
              _hasError = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        }
      }
    });
  }

  Future<void> _loadCurrentContent() async {
    _timeoutTimer?.cancel();
    _startTimeoutTimer();

    await _loadSavedPosition();

    final isYoutube =
        _currentUrl.contains('youtube.com') || _currentUrl.contains('youtu.be');
    final isDoodstream = _detectDoodstream(_currentUrl);
    final isVidsrc = _detectVidsrc(_currentUrl);

    if (isYoutube) {
      _controller.loadRequest(Uri.parse(_currentUrl));
    } else {
      final html = _buildHtmlContent(
        _currentUrl,
        isDoodstream,
        _savedPosition,
        isVidsrc,
      );
      _controller.loadHtmlString(html, baseUrl: _currentUrl);
    }
  }

  void _initController() {
    final isVidsrc = _detectVidsrc(_currentUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'Android',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (data['event'] == 'savePlaybackPosition') {
              final url = data['videoUrl'] as String;
              final pos = data['position'] as int;
              if (url.isNotEmpty && pos > 0) {
                _savePlaybackPosition(url, pos);
              }
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (url) {
            _checkVideoAvailability();

            final isDoodstream = _detectDoodstream(_currentUrl);
            if (isDoodstream && _savedPosition > 0) {
              final isNewLoad = url == _currentUrl;
              if (isNewLoad) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (!mounted) return;
                  final restoreScript =
                      '''
                    (function() {
                        var savedPosition = $_savedPosition;
                        var attempts = 0;
                        var maxAttempts = 10;
                        
                        function tryRestore() {
                            attempts++;
                            try {
                                var iframe = document.getElementById('video-iframe');
                                if (!iframe) {
                                    if (attempts < maxAttempts) {
                                        setTimeout(tryRestore, 1000);
                                    }
                                    return;
                                }
                                
                                try {
                                    var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                                    var video = iframeDoc.querySelector('video');
                                    
                                    if (video && video.readyState >= 2) {
                                        if (video.currentTime > 1 && Math.abs(video.currentTime - savedPosition) > 30) {
                                            console.log('Video already playing, skipping position restore');
                                            return;
                                        }
                                        
                                        if (video.currentTime < 5 || Math.abs(video.currentTime - savedPosition) < 30) {
                                            video.currentTime = savedPosition;
                                            console.log('Position restored to: ' + savedPosition);
                                            return;
                                        }
                                    }
                                } catch (e) {
                                    iframe.contentWindow.postMessage({
                                        type: 'seek',
                                        time: savedPosition
                                    }, '*');
                                }
                                
                                if (attempts < maxAttempts) {
                                    setTimeout(tryRestore, 1000);
                                }
                            } catch (e) {
                                console.log('Error restoring position: ' + e.message);
                            }
                        }
                        
                        setTimeout(tryRestore, 2000);
                    })();
                ''';
                  _controller.runJavaScript(restoreScript);
                });
              }
            }
          },
          onWebResourceError: (error) {
            debugPrint(
              "WebView Error (\${error.errorCode}): \${error.description} for URL: \${error.failingUrl}",
            );

            if (isVidsrc) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                });
              }
              return;
            }

            if (!_errorTriggered) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorTriggered = true;
                });
              }
              _autoSwitchServer();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            final isMain = request.isMainFrame;

            if (isMain) {
              if (url != _currentUrl) {
                debugPrint(
                  "🚫 Blocked main frame navigation (frame busting): \$url",
                );
                return NavigationDecision.prevent;
              }
            }

            if (_shouldBlockNavigation(url, _currentUrl, isVidsrc)) {
              debugPrint("🚫 Blocked navigation: \$url");
              return NavigationDecision.prevent;
            }

            if (isVidsrc) {
              return NavigationDecision.navigate;
            }

            final isDoodstream = _detectDoodstream(_currentUrl);
            if (isDoodstream) {
              bool sameDomain = false;
              try {
                final processedDomain = Uri.parse(_currentUrl).host;
                final requestDomain = Uri.parse(url).host;
                sameDomain =
                    requestDomain == processedDomain ||
                    requestDomain.endsWith('.\$processedDomain') ||
                    processedDomain.endsWith('.\$requestDomain');
              } catch (_) {}

              if (sameDomain) {
                return NavigationDecision.navigate;
              }
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    _loadCurrentContent();
  }

  void _switchServer(int idx) {
    if (idx == _serverIndex) return;
    setState(() {
      _serverIndex = idx;
      _isLoading = true;
      _hasError = false;
    });
    _loadCurrentContent();
  }

  void _reload() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _loadCurrentContent();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingServers) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final server = _servers[_serverIndex];

        // ── LANDSCAPE: fullscreen immersive player ──────────────────
        if (isLandscape) {
          // Hide system UI for true immersive
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading) _LoadingOverlay(serverLabel: server.label),
                if (_hasError && !_isLoading)
                  _ErrorOverlay(
                    onRetry: _reload,
                    onNextServer: () =>
                        _switchServer((_serverIndex + 1) % _servers.length),
                  ),
                // Exit-fullscreen pill (center bottom, auto-fades)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _exitLandscape,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.fullscreen_exit_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Exit fullscreen',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Server badge top-left
                Positioned(
                  top: 16,
                  left: 16,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () => _showServerSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              server.icon,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              server.label,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.expand_more_rounded,
                              color: AppTheme.primary,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ── PORTRAIT: player + info panel ─────────────────────────
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        final title = widget.item['title'] as String? ?? '';
        final type = widget.item['type'] as String? ?? 'movie';
        final year = widget.item['year'] as String? ?? '';
        final runtime = widget.item['runtime'] as String? ?? '';
        final isTv = type == 'tv';

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _buildAppBar(title, isTv, year, runtime, server),
          body: Stack(
            children: [
              Column(
                children: [
                  // ── Video WebView ──────────────────────────────────
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_isLoading)
                          _LoadingOverlay(serverLabel: server.label),
                        if (_hasError && !_isLoading)
                          _ErrorOverlay(
                            onRetry: _reload,
                            onNextServer: () => _switchServer(
                              (_serverIndex + 1) % _servers.length,
                            ),
                          ),
                        // Fullscreen button
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _enterLandscape,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(140),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Info + server panel ────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + meta
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (isTv && _season != null) ...[
                                _MetaBadge(
                                  label: 'S$_season E$_episode',
                                  color: AppTheme.secondary,
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (year.isNotEmpty) _MetaBadge(label: year),
                              if (runtime.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _MetaBadge(label: runtime),
                              ],
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Server selector
                          Row(
                            children: [
                              const Icon(
                                Icons.dns_rounded,
                                color: AppTheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Select Server',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.8,
                            ),
                            itemCount: _servers.length,
                            itemBuilder: (context, i) {
                              final s = _servers[i];
                              final isActive = i == _serverIndex;
                              return GestureDetector(
                                onTap: () => _switchServer(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppTheme.primary.withAlpha(30)
                                        : AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isActive
                                          ? AppTheme.primary
                                          : const Color(0xFF2A2A3E),
                                      width: isActive ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        s.icon,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          s.label,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: isActive
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isActive
                                                ? AppTheme.primary
                                                : Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Rotate-to-fullscreen nudge ─────────────────────
              if (_nudgeShown) _RotateNudge(onTap: _enterLandscape),
            ],
          ),
        );
      },
    );
  }

  void _showServerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF444466),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.dns_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Server',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_servers.length, (i) {
              final s = _servers[i];
              final isActive = i == _serverIndex;
              return ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withAlpha(30)
                        : AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(s.icon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                title: Text(
                  s.label,
                  style: GoogleFonts.outfit(
                    color: isActive ? AppTheme.primary : Colors.white,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: isActive
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _switchServer(i);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    String title,
    bool isTv,
    String year,
    String runtime,
    VideoServer server,
  ) {
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
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Text(
                '${server.icon} ${server.label}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: _reload,
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Colors.white,
            size: 20,
          ),
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
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
          const SizedBox(height: 12),
          Text(
            'Loading $serverLabel…',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _ErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onNextServer;
  const _ErrorOverlay({required this.onRetry, required this.onNextServer});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white38,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load player',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different server',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayerBtn(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onTap: onRetry,
              ),
              const SizedBox(width: 12),
              _PlayerBtn(
                label: 'Next Server',
                icon: Icons.swap_horiz_rounded,
                onTap: onNextServer,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Animated nudge pill suggesting to rotate to landscape
class _RotateNudge extends StatelessWidget {
  final VoidCallback onTap;
  const _RotateNudge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
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
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 12),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.screen_rotation_rounded,
                  color: AppTheme.primary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rotate for fullscreen',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.fullscreen_rounded,
                  color: AppTheme.primary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaBadge({required this.label, this.color = const Color(0xFF444466)});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _PlayerBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PlayerBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF888899), size: 20),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF888899),
            ),
          ),
        ],
      ),
    ),
  );
}

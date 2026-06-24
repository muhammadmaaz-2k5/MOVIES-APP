import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';

class FeaturedBannerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onTap;

  const FeaturedBannerWidget({super.key, required this.items, required this.onTap});

  @override
  State<FeaturedBannerWidget> createState() => _FeaturedBannerWidgetState();
}

class _FeaturedBannerWidgetState extends State<FeaturedBannerWidget> {
  int _current = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              return GestureDetector(
                onTap: () => widget.onTap(item),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomImageWidget(
                      imageUrl: item['backdropUrl'] as String?,
                      fit: BoxFit.cover,
                      semanticLabel: item['backdropSemanticLabel'] as String?,
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.backgroundDark.withAlpha(200),
                            AppTheme.backgroundDark,
                          ],
                          stops: const [0.4, 0.75, 1.0],
                        ),
                      ),
                    ),
                    // Info
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(200),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (item['type'] as String? ?? 'movie').toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.star_rounded, color: AppTheme.accent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                ((item['rating'] as num?)?.toStringAsFixed(1) ?? ''),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'] as String? ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (item['genres'] as List<dynamic>? ?? []).join(' • '),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _current ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _current ? AppTheme.primary : const Color(0xFF444466),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

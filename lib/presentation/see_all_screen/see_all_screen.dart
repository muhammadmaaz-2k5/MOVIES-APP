import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const SeeAllScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2A2A3E)),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'Nothing here yet',
                style: GoogleFonts.outfit(color: const Color(0xFF888899), fontSize: 15),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
                return GestureDetector(
                  onTap: () => context.push(AppRoutes.movieTvShowDetailScreen, extra: item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomImageWidget(
                                imageUrl: item['posterUrl'] as String?,
                                fit: BoxFit.cover,
                                semanticLabel: item['posterSemanticLabel'] as String?,
                              ),
                              if (rating > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(180),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded, color: AppTheme.accent, size: 12),
                                        const SizedBox(width: 3),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Type badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item['type'] == 'tv'
                                            ? AppTheme.secondary
                                            : AppTheme.primary)
                                        .withAlpha(200),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    item['type'] == 'tv' ? 'TV' : 'Movie',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String? ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE6E6F0),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['year'] as String? ?? '',
                                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF888899)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

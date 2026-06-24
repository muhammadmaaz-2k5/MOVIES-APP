import '../../../core/app_export.dart';

class DetailHeroHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const DetailHeroHeaderWidget({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomImageWidget(
            imageUrl: item['backdropUrl'] as String?,
            fit: BoxFit.cover,
            semanticLabel: item['backdropSemanticLabel'] as String?,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.backgroundDark.withAlpha(180),
                  AppTheme.backgroundDark,
                ],
                stops: const [0.45, 0.75, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: onFavoriteToggle,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

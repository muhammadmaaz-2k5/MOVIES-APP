import 'dart:ui';

import '../../../core/app_export.dart';

class ActorHeroHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> person;

  const ActorHeroHeaderWidget({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Blurred backdrop
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: CustomImageWidget(
                    imageUrl:
                        person['backdropUrl'] as String? ??
                        person['photoUrl'] as String,
                    fit: BoxFit.cover,
                    semanticLabel:
                        person['backdropSemanticLabel'] as String? ??
                        'Actor profile backdrop',
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.backgroundDark.withAlpha(128),
                        AppTheme.backgroundDark,
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Circular portrait at bottom center
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Hero(
                tag: 'person-${person['id']}',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(77),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: person['photoUrl'] as String,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      semanticLabel: person['semanticLabel'] as String,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

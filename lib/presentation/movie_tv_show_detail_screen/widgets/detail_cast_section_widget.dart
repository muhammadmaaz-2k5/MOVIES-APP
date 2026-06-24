import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class DetailCastSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> cast;
  final void Function(Map<String, dynamic> person) onPersonTap;

  const DetailCastSectionWidget({
    super.key,
    required this.cast,
    required this.onPersonTap,
  });

  void _showAllCast(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FullCastSheet(cast: cast, onPersonTap: onPersonTap),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.people_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cast',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAllCast(context),
                child: Text(
                  'See all ${cast.length}',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final person = cast[i];
              return _CastItem(person: person, onTap: () => onPersonTap(person));
            },
          ),
        ),
      ],
    );
  }
}

class _CastItem extends StatelessWidget {
  final Map<String, dynamic> person;
  final VoidCallback onTap;
  const _CastItem({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photoUrl = person['photoUrl'] as String? ?? '';
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Hero(
              tag: 'person-${person['id']}',
              child: ClipOval(
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        semanticLabel: person['semanticLabel'] as String? ?? 'Cast member photo',
                        errorBuilder: (_, __, ___) => _CastAvatarPlaceholder(name: person['name'] as String? ?? '?'),
                      )
                    : _CastAvatarPlaceholder(name: person['name'] as String? ?? '?'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              person['name'] as String? ?? '',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              person['character'] as String? ?? '',
              style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF888899)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FullCastSheet extends StatelessWidget {
  final List<Map<String, dynamic>> cast;
  final void Function(Map<String, dynamic> person) onPersonTap;

  const _FullCastSheet({required this.cast, required this.onPersonTap});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF444466),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Full Cast',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${cast.length} members',
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF888899)),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A3E), height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: cast.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final person = cast[i];
                  final photoUrl = person['photoUrl'] as String? ?? '';
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onPersonTap(person);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: photoUrl.isNotEmpty
                                ? Image.network(
                                    photoUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _CastAvatarPlaceholder(name: person['name'] as String? ?? '?', size: 52),
                                  )
                                : _CastAvatarPlaceholder(name: person['name'] as String? ?? '?', size: 52),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person['name'] as String? ?? '',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'as ${person['character'] as String? ?? ''}',
                                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888899), fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF444466), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CastAvatarPlaceholder extends StatelessWidget {
  final String name;
  final double size;
  const _CastAvatarPlaceholder({required this.name, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.surfaceVariantDark,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

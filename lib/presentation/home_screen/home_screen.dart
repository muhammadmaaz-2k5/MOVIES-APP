import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../search_screen/filter_sheet.dart';
import '../search_screen/search_filters.dart';
import './widgets/featured_banner_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/genre_chip_row_widget.dart';
import './widgets/movie_grid_card_widget.dart';
import './widgets/section_header_widget.dart';
import './widgets/top_rated_row_widget.dart';
import './widgets/trending_card_widget.dart';

// TODO: Replace with [Riverpod/Bloc] for production — TMDB API integration
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedFilter = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarBlurred = false;
  SearchFilters _activeFilters = const SearchFilters();

  // TODO: Replace with TMDB API call — GET /trending/all/week
  // Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
  static final List<Map<String, dynamic>> _featuredMaps = [
    {
      'id': 1,
      'title': 'Dune: Part Two',
      'type': 'movie',
      'backdropUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15af53f71-1772813364588.png',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15af53f71-1772813364588.png',
      'rating': 8.5,
      'year': '2024',
      'genres': ['Sci-Fi', 'Adventure'],
      'runtime': '166 min',
      'overview':
          'Paul Atreides unites with the Fremen while on a warpath of revenge against the conspirators who destroyed his family.',
      'voteCount': 4821,
      'backdropSemanticLabel':
          'Vast desert landscape with dramatic lighting, representing the sci-fi world of Dune',
      'posterSemanticLabel':
          'Movie poster for Dune Part Two featuring desert warrior silhouette',
    },
    {
      'id': 2,
      'title': 'Shogun',
      'type': 'tv',
      'backdropUrl':
          'https://images.unsplash.com/photo-1708527731834-419bf5fe1d5b',
      'posterUrl':
          'https://images.unsplash.com/photo-1708527731834-419bf5fe1d5b',
      'rating': 9.0,
      'year': '2024',
      'genres': ['Drama', 'History'],
      'runtime': '10 Episodes',
      'overview':
          'A shipwrecked English navigator becomes a pivotal player in a brutal struggle for power in feudal Japan.',
      'voteCount': 3214,
      'backdropSemanticLabel':
          'Misty Japanese landscape with traditional architecture suggesting feudal era',
      'posterSemanticLabel':
          'TV show poster for Shogun featuring samurai in traditional armor',
    },
    {
      'id': 3,
      'title': 'Oppenheimer',
      'type': 'movie',
      'backdropUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_122a0ff3c-1782334248803.png',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_122a0ff3c-1782334248803.png',
      'rating': 8.9,
      'year': '2023',
      'genres': ['Drama', 'History', 'Biography'],
      'runtime': '180 min',
      'overview':
          'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.',
      'voteCount': 12450,
      'backdropSemanticLabel':
          'Dramatic sky with explosive light suggesting the atomic age',
      'posterSemanticLabel':
          'Oppenheimer movie poster with silhouette of man in hat against explosive sky',
    },
  ];

  static final List<Map<String, dynamic>> _trendingMaps = [
    {
      'id': 10,
      'title': 'The Bear',
      'type': 'tv',
      'posterUrl':
          'https://images.unsplash.com/photo-1656478708298-e4d5e138bf11',
      'rating': 8.7,
      'year': '2024',
      'genres': ['Drama', 'Comedy'],
      'runtime': '8 Episodes',
      'overview':
          'A young chef from the fine-dining world returns to Chicago to run his family sandwich shop.',
      'voteCount': 2890,
      'posterSemanticLabel':
          'TV show poster featuring a professional kitchen environment with dramatic lighting',
    },
    {
      'id': 11,
      'title': 'Poor Things',
      'type': 'movie',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1f0b094f2-1771890357295.png',
      'rating': 8.0,
      'year': '2023',
      'genres': ['Comedy', 'Drama', 'Fantasy'],
      'runtime': '141 min',
      'overview':
          'The incredible tale about the fantastical evolution of Bella Baxter, a young woman brought back to life.',
      'voteCount': 5670,
      'posterSemanticLabel':
          'Whimsical movie poster with surreal Victorian-era aesthetic',
    },
    {
      'id': 12,
      'title': 'Fallout',
      'type': 'tv',
      'posterUrl':
          'https://images.unsplash.com/photo-1661366721768-e2e2e27cf50a',
      'rating': 8.5,
      'year': '2024',
      'genres': ['Sci-Fi', 'Action', 'Drama'],
      'runtime': '8 Episodes',
      'overview':
          'In a future, post-apocalyptic Los Angeles, a young woman emerges from her vault into the wasteland.',
      'voteCount': 3120,
      'posterSemanticLabel':
          'Post-apocalyptic wasteland scene with desolate urban environment',
    },
    {
      'id': 13,
      'title': 'Civil War',
      'type': 'movie',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1ed8be91f-1777395428211.png',
      'rating': 7.4,
      'year': '2024',
      'genres': ['Action', 'Drama', 'War'],
      'runtime': '109 min',
      'overview':
          'A team of military-embedded journalists race against time to reach D.C. before rebel factions descend.',
      'voteCount': 1980,
      'posterSemanticLabel':
          'War journalism themed movie poster with tense dramatic imagery',
    },
    {
      'id': 14,
      'title': 'Baby Reindeer',
      'type': 'tv',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_14e45a2ba-1772758782914.png',
      'rating': 8.6,
      'year': '2024',
      'genres': ['Drama', 'Thriller'],
      'runtime': '7 Episodes',
      'overview':
          'A struggling comedian becomes the obsession of a stalker, forcing him to confront uncomfortable truths.',
      'voteCount': 4230,
      'posterSemanticLabel':
          'Psychological thriller TV show poster with lone figure in dark urban setting',
    },
    {
      'id': 15,
      'title': 'Challengers',
      'type': 'movie',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1a3085a0a-1773862793944.png',
      'rating': 7.8,
      'year': '2024',
      'genres': ['Drama', 'Romance', 'Sport'],
      'runtime': '131 min',
      'overview':
          'Three players who knew each other when they were teenagers reconnect at a tennis tournament.',
      'voteCount': 2340,
      'posterSemanticLabel':
          'Tennis drama movie poster with athletic figures and competitive intensity',
    },
  ];

  static final List<Map<String, dynamic>> _popularMaps = [
    {
      'id': 20,
      'title': 'Inception',
      'type': 'movie',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1ea57370e-1772239655078.png',
      'rating': 8.8,
      'year': '2010',
      'genres': ['Sci-Fi', 'Action', 'Thriller'],
      'runtime': '148 min',
      'overview':
          'A thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea.',
      'voteCount': 34567,
      'posterSemanticLabel':
          'Surreal cityscape bending in impossible ways for Inception movie poster',
    },
    {
      'id': 21,
      'title': 'The Last of Us',
      'type': 'tv',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_14b28fd37-1772897587194.png',
      'rating': 8.8,
      'year': '2023',
      'genres': ['Drama', 'Action', 'Sci-Fi'],
      'runtime': '9 Episodes',
      'overview':
          'After a global catastrophe, a hardened survivor and a teenage girl must traverse a dangerous post-pandemic America.',
      'voteCount': 8920,
      'posterSemanticLabel':
          'Post-apocalyptic drama TV poster showing overgrown urban landscape with survivors',
    },
    {
      'id': 22,
      'title': 'Parasite',
      'type': 'movie',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_125bcebc8-1780257695672.png',
      'rating': 8.5,
      'year': '2019',
      'genres': ['Thriller', 'Comedy', 'Drama'],
      'runtime': '132 min',
      'overview':
          'A poor family schemes to become employed by a wealthy family, infiltrating their household one by one.',
      'voteCount': 28900,
      'posterSemanticLabel':
          'Korean thriller movie poster with symbolic imagery of class divide',
    },
    {
      'id': 23,
      'title': 'Severance',
      'type': 'tv',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18f9990a5-1782334248416.png',
      'rating': 8.7,
      'year': '2022',
      'genres': ['Sci-Fi', 'Thriller', 'Drama'],
      'runtime': '9 Episodes',
      'overview':
          'Mark leads a team of office workers whose memories have been surgically divided between their work and personal lives.',
      'voteCount': 5670,
      'posterSemanticLabel':
          'Corporate dystopia TV show poster with clinical office environment imagery',
    },
  ];

  static final List<Map<String, dynamic>> _topRatedMaps = [
    {
      'id': 30,
      'title': 'Breaking Bad',
      'type': 'tv',
      'posterUrl':
          'https://images.pexels.com/photos/1089440/pexels-photo-1089440.jpeg?w=400',
      'rating': 9.5,
      'year': '2008–2013',
      'genres': ['Drama', 'Crime', 'Thriller'],
      'runtime': '62 Episodes',
      'overview':
          'A chemistry teacher diagnosed with cancer partners with a former student to secure his family\'s future.',
      'voteCount': 89234,
      'posterSemanticLabel':
          'Iconic Breaking Bad TV show poster with desert landscape and chemistry imagery',
    },
    {
      'id': 31,
      'title': 'Interstellar',
      'type': 'movie',
      'posterUrl':
          'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=400&q=80',
      'rating': 8.7,
      'year': '2014',
      'genres': ['Sci-Fi', 'Drama', 'Adventure'],
      'runtime': '169 min',
      'overview':
          'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
      'voteCount': 41200,
      'posterSemanticLabel':
          'Space exploration movie poster showing spacecraft approaching a wormhole',
    },
    {
      'id': 32,
      'title': 'The Godfather',
      'type': 'movie',
      'posterUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1d8217788-1772109803927.png',
      'rating': 9.2,
      'year': '1972',
      'genres': ['Crime', 'Drama'],
      'runtime': '175 min',
      'overview':
          'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.',
      'voteCount': 78900,
      'posterSemanticLabel':
          'Classic Godfather movie poster with shadowy figure in formal attire',
    },
  ];

  static const List<String> _genreList = [
    'Action',
    'Comedy',
    'Drama',
    'Horror',
    'Sci-Fi',
    'Thriller',
    'Romance',
    'Animation',
    'Documentary',
    'Fantasy',
  ];

  static const List<String> _filterOptions = ['All', 'Movies', 'TV Shows'];

  late List<Map<String, dynamic>> _featured;
  late List<Map<String, dynamic>> _trending;
  late List<Map<String, dynamic>> _popular;
  late List<Map<String, dynamic>> _topRated;

  @override
  void initState() {
    super.initState();
    _featured = _featuredMaps;
    _trending = _trendingMaps;
    _popular = _popularMaps;
    _topRated = _topRatedMaps;

    _scrollController.addListener(() {
      final shouldBlur = _scrollController.offset > 10;
      if (shouldBlur != _isAppBarBlurred) {
        setState(() => _isAppBarBlurred = shouldBlur);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredList(List<Map<String, dynamic>> list) {
    if (_selectedFilter == 0) return list;
    final type = _selectedFilter == 1 ? 'movie' : 'tv';
    return list.where((e) => e['type'] == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(theme),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surfaceDark,
        onRefresh: () async {
          // TODO: Replace with TMDB API refresh calls
          await Future.value();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: kToolbarHeight + 56),
                  // Featured Banner
                  FeaturedBannerWidget(
                    items: _featured,
                    onTap: (item) => context.push(
                      AppRoutes.movieTvShowDetailScreen,
                      extra: item,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Filter chips
                  FilterChipsWidget(
                    options: _filterOptions,
                    selectedIndex: _selectedFilter,
                    onSelected: (i) => setState(() => _selectedFilter = i),
                  ),
                  const SizedBox(height: 24),
                  // Trending Now
                  SectionHeaderWidget(
                    title: 'Trending Now',
                    iconName: 'local_fire_department_rounded',
                    onSeeMore: () => context.push(
                      AppRoutes.seeAllScreen,
                      extra: {'title': 'Trending Now', 'items': _filteredList(_trending)},
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredList(_trending).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final item = _filteredList(_trending)[i];
                        return TrendingCardWidget(
                          item: item,
                          index: i,
                          onTap: () => context.push(
                            AppRoutes.movieTvShowDetailScreen,
                            extra: item,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Popular
                  SectionHeaderWidget(
                    title: 'Popular Right Now',
                    iconName: 'trending_up_rounded',
                    onSeeMore: () => context.push(
                      AppRoutes.seeAllScreen,
                      extra: {'title': 'Popular Right Now', 'items': _filteredList(_popular)},
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 3 : 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredList(_popular).length,
                      itemBuilder: (context, i) {
                        final item = _filteredList(_popular)[i];
                        return MovieGridCardWidget(
                          item: item,
                          onTap: () => context.push(
                            AppRoutes.movieTvShowDetailScreen,
                            extra: item,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Genre Browse
                  SectionHeaderWidget(
                    title: 'Browse by Genre',
                    iconName: 'filter_list_rounded',
                    onSeeMore: null,
                  ),
                  const SizedBox(height: 12),
                  GenreChipRowWidget(genres: _genreList),
                  const SizedBox(height: 28),
                  // Top Rated
                  SectionHeaderWidget(
                    title: 'Top Rated All Time',
                    iconName: 'workspace_premium_rounded',
                    onSeeMore: () => context.push(
                      AppRoutes.seeAllScreen,
                      extra: {'title': 'Top Rated All Time', 'items': _filteredList(_topRated)},
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_filteredList(_topRated).map(
                    (item) => TopRatedRowWidget(
                      item: item,
                      onTap: () => context.push(
                        AppRoutes.movieTvShowDetailScreen,
                        extra: item,
                      ),
                    ),
                  )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(ThemeData theme) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _isAppBarBlurred ? 20 : 0,
            sigmaY: _isAppBarBlurred ? 20 : 0,
          ),
          child: Container(
            color: _isAppBarBlurred
                ? AppTheme.backgroundDark.withAlpha(191)
                : Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'CineTrack',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    _GlassIconButton(iconName: 'search_rounded', onTap: () => context.push(AppRoutes.searchScreen)),
                    const SizedBox(width: 8),
                    _GlassFilterButton(
                      activeCount: _activeFilters.activeCount,
                      onTap: () async {
                        final result =
                            await showModalBottomSheet<SearchFilters>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              FilterSheet(current: _activeFilters),
                        );
                        if (result != null) {
                          setState(() => _activeFilters = result);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      iconName: 'notifications_none_rounded',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final String iconName;
  final VoidCallback onTap;

  const _GlassIconButton({required this.iconName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: CustomIconWidget(
          iconName: iconName,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _GlassFilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _GlassFilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withAlpha(40)
              : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppTheme.primary.withAlpha(120)
                : Colors.white.withAlpha(26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 16,
                color: isActive ? AppTheme.primary : Colors.white),
            if (isActive) ...[
              const SizedBox(width: 4),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

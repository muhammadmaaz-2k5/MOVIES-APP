import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/actor_person_detail_screen/actor_person_detail_screen.dart';
import '../presentation/anime_screen/anime_screen.dart';
import '../presentation/category_section_screen/category_section_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/movies_screen/movies_screen.dart';
import '../presentation/season_detail_screen/season_detail_screen.dart';
import '../presentation/tv_shows_screen/tv_shows_screen.dart';
import '../presentation/movie_tv_show_detail_screen/movie_tv_show_detail_screen.dart';
import '../presentation/search_screen/search_screen.dart';
import '../presentation/see_all_screen/see_all_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial                = '/';
  static const String homeScreen             = '/home';
  static const String moviesScreen           = '/movies';
  static const String tvShowsScreen          = '/tv-shows';
  static const String animeScreen            = '/anime';
  static const String movieTvShowDetailScreen = '/movie-tv-show-detail-screen';
  static const String actorPersonDetailScreen = '/actor-person-detail-screen';
  static const String searchScreen           = '/search';
  static const String seeAllScreen           = '/see-all';
  static const String categorySectionScreen  = '/category-section';
  static const String seasonDetailScreen     = '/season-detail';
}

// Shared slide+fade transition
CustomTransitionPage<void> _slidePage(
    GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          ),
    );

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    // ── Splash / initial redirect to shell ──────────────────────────────────
    GoRoute(
      path: AppRoutes.initial,
      redirect: (_, __) => AppRoutes.homeScreen,
    ),

    // ── Main shell with bottom nav (4 branches) ──────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        // Branch 0 — Home
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.homeScreen,
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        // Branch 1 — Movies
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.moviesScreen,
            builder: (context, state) => const MoviesScreen(),
          ),
        ]),
        // Branch 2 — TV Shows
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.tvShowsScreen,
            builder: (context, state) => const TvShowsScreen(),
          ),
        ]),
        // Branch 3 — Anime
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.animeScreen,
            builder: (context, state) => const AnimeScreen(),
          ),
        ]),
      ],
    ),

    // ── Global overlay routes (no bottom nav) ────────────────────────────────
    GoRoute(
      path: AppRoutes.searchScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SearchScreen(),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: AppRoutes.categorySectionScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _slidePage(
          state,
          CategorySectionScreen(
            emoji: extra['emoji'] as String,
            title: extra['title'] as String,
            tmdbParams: (extra['tmdbParams'] as Map).cast<String, dynamic>(),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.seeAllScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _slidePage(
          state,
          SeeAllScreen(
            title: extra['title'] as String,
            items: (extra['items'] as List).cast<Map<String, dynamic>>(),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.movieTvShowDetailScreen,
      pageBuilder: (context, state) => _slidePage(
        state,
        MovieTvShowDetailScreen(
          item: state.extra as Map<String, dynamic>?,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.actorPersonDetailScreen,
      pageBuilder: (context, state) => _slidePage(
        state,
        ActorPersonDetailScreen(
          person: state.extra as Map<String, dynamic>?,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.seasonDetailScreen,
      pageBuilder: (context, state) => _slidePage(
        state,
        SeasonDetailScreen(
          season: state.extra as Map<String, dynamic>,
        ),
      ),
    ),
  ],
);

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/actor_person_detail_screen/actor_person_detail_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/movie_tv_show_detail_screen/movie_tv_show_detail_screen.dart';
import '../presentation/search_screen/search_screen.dart';
import '../presentation/see_all_screen/see_all_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String homeScreen = '/home-screen';
  static const String movieTvShowDetailScreen = '/movie-tv-show-detail-screen';
  static const String actorPersonDetailScreen = '/actor-person-detail-screen';
  static const String searchScreen = '/search';
  static const String seeAllScreen = '/see-all';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: child,
            ),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.searchScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SearchScreen(),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: AppRoutes.seeAllScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CustomTransitionPage(
          key: state.pageKey,
          child: SeeAllScreen(
            title: extra['title'] as String,
            items: (extra['items'] as List).cast<Map<String, dynamic>>(),
          ),
          transitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: animation, child: child),
              ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.movieTvShowDetailScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: MovieTvShowDetailScreen(
          item: state.extra as Map<String, dynamic>?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: animation, child: child),
            ),
      ),
    ),
    GoRoute(
      path: AppRoutes.actorPersonDetailScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ActorPersonDetailScreen(
          person: state.extra as Map<String, dynamic>?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: animation, child: child),
            ),
      ),
    ),
  ],
);

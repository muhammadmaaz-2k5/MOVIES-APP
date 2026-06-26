import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './custom_icon_widget.dart';

class _TabSpec {
  final String label;
  final String emoji;
  final String icon;
  final String selectedIcon;
  final int?   branchIndex; // null = push route
  final String? pushRoute;

  const _TabSpec({
    required this.label,
    required this.emoji,
    required this.icon,
    required this.selectedIcon,
    this.branchIndex,
    this.pushRoute,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Home',
      emoji: '🏠',
      icon: 'home_outlined',
      selectedIcon: 'home_rounded',
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Movies',
      emoji: '🎬',
      icon: 'movie_outlined',
      selectedIcon: 'movie_rounded',
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'TV Shows',
      emoji: '📺',
      icon: 'tv_outlined',
      selectedIcon: 'tv_rounded',
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Anime',
      emoji: '⛩️',
      icon: 'auto_awesome_outlined',
      selectedIcon: 'auto_awesome_rounded',
      branchIndex: 3,
    ),
    _TabSpec(
      label: 'Search',
      emoji: '🔍',
      icon: 'search_rounded',
      selectedIcon: 'search_rounded',
      branchIndex: null,
      pushRoute: '/search',
    ),
  ];

  // accent colours per tab
  static const List<Color> _tabColors = [
    Color(0xFF6C5CE7), // Home   — purple
    Color(0xFF0984E3), // Movies — blue
    Color(0xFF00B894), // TV     — teal
    Color(0xFFFF6B9D), // Anime  — pink
    Color(0xFFFDAA07), // Search — amber
  ];

  @override
  Widget build(BuildContext context) {
    final currentBranch = widget.navigationShell.currentIndex;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withAlpha(204),
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab      = _tabs[i];
                final isBranch = tab.branchIndex != null;
                final isActive = isBranch &&
                    tab.branchIndex == currentBranch;
                final color    = _tabColors[i];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!isBranch) {
                        GoRouter.of(context).push(tab.pushRoute!);
                        return;
                      }
                      widget.navigationShell.goBranch(
                        tab.branchIndex!,
                        initialLocation:
                            tab.branchIndex == currentBranch,
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? color.withAlpha(50)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: CustomIconWidget(
                              iconName: isActive
                                  ? tab.selectedIcon
                                  : tab.icon,
                              color: isActive
                                  ? color
                                  : const Color(0xFF888899),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isActive
                                  ? color
                                  : const Color(0xFF888899),
                            ),
                            child: Text(tab.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './custom_icon_widget.dart';

// V3 Liquid Glass — BackdropFilter blur + frosted surface + animated pill — LOCKED

class _TabSpec {
  final String label;
  final String icon;
  final String selectedIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Home',
      icon: 'home_outlined',
      selectedIcon: 'home_rounded',
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Search',
      icon: 'search_rounded',
      selectedIcon: 'search_rounded',
      branchIndex: null,
    ),
    _TabSpec(
      label: 'Watchlist',
      icon: 'bookmark_border_rounded',
      selectedIcon: 'bookmark_rounded',
      branchIndex: null,
    ),
    _TabSpec(
      label: 'Profile',
      icon: 'person_outline_rounded',
      selectedIcon: 'person_rounded',
      branchIndex: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withAlpha(191),
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final isActive = i == _selectedVisualIndex;
                  final isStub = tab.branchIndex == null;

                  return GestureDetector(
                    onTap: () {
                      if (isStub) {
                        // Search tab: push the search screen
                        if (tab.icon == 'search_rounded') {
                          GoRouter.of(context).push('/search');
                        }
                        return;
                      }
                      setState(() => _selectedVisualIndex = i);
                      widget.navigationShell.goBranch(
                        tab.branchIndex!,
                        initialLocation:
                            tab.branchIndex ==
                            widget.navigationShell.currentIndex,
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isStub ? 0.4 : 1.0,
                      child: SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF6C5CE7).withAlpha(64)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: CustomIconWidget(
                                iconName: isActive
                                    ? tab.selectedIcon
                                    : tab.icon,
                                color: isActive
                                    ? const Color(0xFF6C5CE7)
                                    : const Color(0xFF888899),
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? const Color(0xFF6C5CE7)
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
      ),
    );
  }
}

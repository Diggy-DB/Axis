import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navItems = [
    NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: '/',
    ),
    NavigationItem(
      label: 'Calendar',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      route: '/calendar',
    ),
    NavigationItem(
      label: 'Tasks',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
      route: '/tasks',
    ),
    NavigationItem(
      label: 'Habits',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
      route: '/habits',
    ),
    NavigationItem(
      label: 'Reflection',
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories,
      route: '/reflection',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.toString();
    final index = _navItems.indexWhere((item) => item.route == location);
    if (index != -1 && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onNavigationItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    context.go(_navItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useRail = width >= AppConstants.mobileBreakpoint;

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation (tablet/desktop)
          if (useRail)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onNavigationItemSelected,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.lg, bottom: AppSpacing.xl),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'AXIS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
              destinations: _navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),

          // Vertical divider
          if (useRail) const VerticalDivider(thickness: 1, width: 1),

          // Main content
          Expanded(
            child: widget.child,
          ),
        ],
      ),

      // Bottom Navigation (mobile)
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onNavigationItemSelected,
              destinations: _navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

import 'package:flutter/material.dart';

import '../config/theme.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: AppTheme.darkSurface,
      indicatorColor: AppTheme.primaryGold.withValues(alpha: 0.2),
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppTheme.primaryGold),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings, color: AppTheme.primaryGold),
          label: 'Settings',
        ),
      ],
    );
  }
}

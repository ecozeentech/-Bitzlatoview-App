import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Native bottom navigation used by [MainShell] to switch between the
/// WebView "Home" tab and the native "Settings" tab without ever unloading
/// the WebView (it stays alive in an `IndexedStack`).
///
/// This, together with the splash screen and settings screen, is part of
/// what makes the app more than a "thin WebView wrapper" for App Store
/// Guideline 4.2 purposes.
class BitzlatoviewBottomNavBar extends StatelessWidget {
  const BitzlatoviewBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Color(0xFF272B35), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.gold,
          unselectedItemColor: AppTheme.textSecondary,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

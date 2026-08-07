import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'settings_screen.dart';
import 'webview_screen.dart';

/// Hosts the "Home" (WebView) and "Settings" tabs behind a native bottom
/// navigation bar, and gates access behind biometric app-lock when enabled.
///
/// Using an [IndexedStack] keeps the WebView instance alive (and its
/// scroll/session state intact) when the user switches to Settings and
/// back, instead of reloading the page every time.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    if (authProvider.requiresUnlock) {
      return _AppLockScreen(onUnlock: () => authProvider.unlock());
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          WebViewScreen(initialUrl: widget.initialUrl),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BitzlatoviewBottomNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}

class _AppLockScreen extends StatelessWidget {
  const _AppLockScreen({required this.onUnlock});

  final Future<bool> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, color: AppTheme.gold, size: 64),
            const SizedBox(height: 20),
            Text(
              '${AppConstants.appName} is locked',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Authenticate to continue',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

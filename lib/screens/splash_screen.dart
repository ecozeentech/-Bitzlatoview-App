import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../widgets/bitzlatoview_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BitzlatoviewAppIcon(size: 128),
            const SizedBox(height: 28),
            const BitzlatoviewLogo(
              iconSize: 0,
              fontSize: 28,
              showWordmark: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Secure Trading Platform',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

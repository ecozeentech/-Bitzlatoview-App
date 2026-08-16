import 'package:flutter/material.dart';

import '../config/theme.dart';

import '../widgets/bitzlatoview_logo.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BitzlatoviewAppIcon(size: 72),
              const SizedBox(height: 32),
              Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: AppTheme.primaryGold.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your connection and try again. '
                'Your session will be restored when you reconnect.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

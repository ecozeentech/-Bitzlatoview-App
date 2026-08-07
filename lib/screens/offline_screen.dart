import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../widgets/loading_indicator.dart';

/// Shown when the device has no network connectivity.
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF16120A),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.goldMuted, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 34,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'You\'re offline',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Check your internet connection. Bitzlatoview will reload automatically when you\'re back online.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  )
                else
                  const LoadingIndicator(message: 'Waiting for connection…'),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

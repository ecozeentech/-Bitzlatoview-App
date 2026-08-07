import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';

/// Friendly, branded "no internet connection" screen.
///
/// Automatically calls [onRetry] the moment connectivity is restored, in
/// addition to offering a manual retry button - satisfying the "Offline
/// Support" requirement (detect, inform, auto-recover).
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final bool online = results.any((r) => r != ConnectivityResult.none);
      if (online) widget.onRetry();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'You\'re offline',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t reach ${AppConstants.appName}. '
                'Please check your internet connection - we\'ll reconnect '
                'automatically once you\'re back online.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

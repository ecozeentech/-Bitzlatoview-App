import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Full-screen, friendly error state with a retry action. Named
/// [AppErrorView] (rather than `ErrorWidget`) to avoid colliding with
/// Flutter's built-in `ErrorWidget`.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.title = 'Something went wrong',
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.error),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

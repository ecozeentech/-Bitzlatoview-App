import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';

/// Branded loading spinner shown while the WebView is fetching a page.
/// Wrapped in a [RepaintBoundary] since it animates continuously and should
/// not force repaints of the (potentially complex) WebView beneath it.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.progress,
    this.message,
  });

  /// 0.0-1.0 determinate progress. When null, shows an indeterminate spinner.
  final double? progress;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final bool determinate = progress != null && progress! > 0 && progress! < 1;
    return RepaintBoundary(
      child: Container(
        color: AppTheme.background,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: determinate ? progress : null,
                strokeWidth: 3,
                color: AppTheme.gold,
                backgroundColor: AppTheme.surfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? 'Loading ${AppConstants.appName}…',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim linear progress bar overlaid at the top of the WebView while a page
/// is loading - keeps the page visible instead of blocking it entirely.
class TopProgressBar extends StatelessWidget {
  const TopProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: progress,
        color: AppTheme.gold,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

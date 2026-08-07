import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Branded gold loading indicator used during WebView page loads.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.message,
    this.progress,
  });

  final String? message;
  final int? progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: progress != null && progress! > 0 && progress! < 100
                  ? progress! / 100
                  : null,
              color: AppTheme.gold,
              backgroundColor: AppTheme.border,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

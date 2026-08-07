import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/deep_link_service.dart';

/// Branded splash screen (dark theme, gold accent) shown while the app
/// performs its one-time async bootstrap: restoring the session, wiring up
/// push notifications and starting the deep-link listener. A native splash
/// (via `flutter_native_splash`) is already visible before Flutter's first
/// frame, so this screen picks up seamlessly from the same background/logo
/// and fades into the WebView once ready.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onReady});

  /// Invoked once bootstrap completes; the caller (the router) is
  /// responsible for navigating to the WebView / lock screen.
  final VoidCallback onReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final Stopwatch stopwatch = Stopwatch()..start();

    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final deepLinkService = context.read<DeepLinkService>();

    await Future.wait<void>([
      authProvider.initialize(),
      notificationProvider.initialize(),
      deepLinkService.initialize(),
    ]);

    final int elapsed = stopwatch.elapsedMilliseconds;
    final int remaining = AppConstants.splashMinimumDuration.inMilliseconds - elapsed;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;
    widget.onReady();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.gold, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'B',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

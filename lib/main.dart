import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the platform-drawn native splash screen visible until our own
  // Flutter SplashScreen widget (lib/screens/splash_screen.dart) has
  // rendered its first frame, avoiding a flash of blank white in between.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0D12),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const BitzlatoviewApp());

  // Hand off from the native splash to the Flutter SplashScreen widget as
  // soon as the first frame is drawn.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}

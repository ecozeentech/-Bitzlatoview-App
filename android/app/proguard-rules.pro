# Flutter wraps most of its own engine code; keep bridge-facing entry points.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# flutter_inappwebview uses reflection for its JS bridge / plugin interfaces.
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# Firebase Cloud Messaging / Google Play Services.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep model classes referenced only via JSON (de)serialization from the JS bridge.
-keepclassmembers class com.bitzlatoview.bitzlatoview_mobile.** {
    <fields>;
}

# Flutter's engine includes optional support for Play Store "deferred
# components" (dynamic feature modules), which references the Play Core
# split-install library. This app doesn't use deferred components or depend
# on play-core, so these classes are legitimately absent - silence R8.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

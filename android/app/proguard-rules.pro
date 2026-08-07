# Keep WebView and Firebase messaging classes used via reflection.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keep class io.flutter.** { *; }
-dontwarn com.google.firebase.**

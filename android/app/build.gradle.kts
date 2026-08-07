import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
}

// Release signing config, loaded from android/key.properties (never
// committed - see android/key.properties.example and the README "Build &
// Release" section). Falls back to debug signing when absent so a fresh
// checkout still builds out of the box for local development.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.bitzlatoview.bitzlatoview_mobile"
    // Some plugins (flutter_secure_storage, permission_handler_android)
    // require compiling against API 37+ even though this app's minSdk/targetSdk
    // stay at 24/34 per the product spec - compileSdk only affects which SDK
    // APIs are visible at compile time, not runtime behavior or device support.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (java.time APIs on API < 26).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.bitzlatoview.bitzlatoview_mobile"
        // Per the Bitzlatoview mobile spec: Android 7.0+ (API 24) minimum,
        // API 34 (Android 14) target.
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Signing with the debug keys so `flutter build apk --release`
                // still works out of the box before a real keystore exists.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Enables multiple .dex files, required once minSdk 24 pulls in enough
    // plugins (Firebase, WebView bridge, etc.) to exceed the 64k method limit.
    implementation("androidx.multidex:multidex:2.0.1")
    // Backports java.time / java.util.stream etc. to API < 26, required by
    // flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

// The Google Services (Firebase) plugin requires android/app/google-services.json
// to exist. That file contains project-specific secrets and is intentionally
// NOT committed to this repository (see README "Firebase setup") - so we only
// apply the plugin when a real config file has been dropped in locally or by CI.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

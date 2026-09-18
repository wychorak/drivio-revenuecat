plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val localEnv = rootProject.file("../.env")
    .takeIf { it.exists() }
    ?.readLines()
    ?.mapNotNull { line ->
        val trimmed = line.trim()
        if (trimmed.isEmpty() || trimmed.startsWith("#") || !trimmed.contains("=")) {
            null
        } else {
            val (key, value) = trimmed.split("=", limit = 2)
            key.trim() to value.trim().removeSurrounding("\"")
        }
    }
    ?.toMap()
    .orEmpty()

android {
    namespace = "com.drivio.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.drivio.app"
        manifestPlaceholders["googleMapsApiKey"] =
            (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)
                ?: localEnv["GOOGLE_MAPS_API_KEY"]
                ?: ""
        manifestPlaceholders["admobAppId"] =
            (project.findProperty("ADMOB_ANDROID_APP_ID") as String?)
                ?: "ca-app-pub-3940256099942544~3347511713"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

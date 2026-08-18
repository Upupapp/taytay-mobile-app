plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ph.gov.taytay.lguids.taytay_resident"
    // Pinned above Flutter's default because `flutter_secure_storage` 11 declares
    // that dependants must compile against API 37 or later. compileSdk controls
    // only which APIs are available at compile time; `targetSdk` (runtime
    // behaviour) and `minSdk` (device support) stay on Flutter's defaults, so no
    // device loses support and no new runtime behaviour is opted into.
    //
    // AGP 9.0.1 reports 36 as its "maximum recommended" compileSdk and emits a
    // warning at 37. Accepted deliberately: the alternative is downgrading the
    // credential-storage plugin, and the keystore layer is the last place to run
    // an older version. Revisit when AGP officially supports 37.
    compileSdk = 37

    // Android SDK platforms are minor-versioned from API 37 onward, and the
    // unqualified `platforms;android-37` package no longer exists — the SDK
    // manager offers `android-37.0` and `android-37.1`. `compileSdk = 37` alone
    // resolves to the hash string `android-37` and fails to find a target on any
    // machine whose SDK was installed after that change, which is what happened
    // when this repository moved from its original Windows host to macOS.
    //
    // Pinned to minor 0 rather than the newest available: it is the closest
    // equivalent to the platform the 28 build TABs were verified against, and a
    // minor bump is an additive API change nothing here has asked for.
    compileSdkMinor = 0
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ph.gov.taytay.lguids.taytay_resident"
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

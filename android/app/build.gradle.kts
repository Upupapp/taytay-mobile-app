import java.util.Properties

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
        applicationId = "ph.gov.taytay.lguids.taytay_resident"

        /*
         * PINNED, not inherited (F11). Both rode Flutter's defaults, which move
         * when the SDK moves — so the device base this app supports could change
         * because somebody upgraded a toolchain, which is not a decision anybody
         * would have made deliberately.
         *
         * minSdk 24 (Android 7.0, 2016). Chosen from who is excluded rather than
         * from what is convenient: every Android version above this is ~99% of
         * the active Philippine device base, and each step up excludes exactly
         * the residents a social-welfare app exists for — people on inherited
         * handsets that no longer receive vendor updates. Raising it needs a
         * reason about devices, not about libraries.
         */
        minSdk = 24

        /*
         * targetSdk 36. Play enforces a target-API floor that moves annually and
         * is checked at submission, not at build — so this must be re-read
         * against the current floor before each store submission rather than
         * left until a rejection explains it.
         */
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    /*
     * Release signing, read from android/key.properties — which .gitignore
     * already excludes, correctly. The keystore is held by the LGU and its loss
     * is an incident: losing it means never being able to update this app under
     * the same Play listing again.
     */
    signingConfigs {
        create("release") {
            val propertiesFile = rootProject.file("key.properties")
            if (propertiesFile.exists()) {
                val properties = Properties()
                propertiesFile.inputStream().use { properties.load(it) }

                val missing = listOf(
                    "storeFile", "storePassword", "keyAlias", "keyPassword",
                ).filter { properties.getProperty(it).isNullOrBlank() }

                // A half-filled key.properties is worse than an absent one: it
                // fails deep inside the packaging task with a message about a
                // property rather than about what the developer forgot.
                if (missing.isNotEmpty()) {
                    throw GradleException(
                        "android/key.properties is missing: ${missing.joinToString(", ")}. " +
                            "See docs/integration/release-engineering.md.",
                    )
                }

                storeFile = file(properties.getProperty("storeFile"))
                storePassword = properties.getProperty("storePassword")
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
            }
        }
    }

    /*
     * Three flavours, so a staging build can never be mistaken for production on
     * a tester's phone — and, more usefully, so both can be installed side by
     * side. A single applicationId means acceptance testing against staging
     * requires uninstalling the real app, which is exactly when somebody tests
     * the wrong one and reports a bug against the wrong environment.
     *
     * The suffix is on the applicationId rather than only on the label, because
     * a label is what somebody reads and an applicationId is what the OS
     * enforces.
     *
     * TAYTAY_ENV is still supplied by --dart-define and is still what the app
     * itself reads. These do not set it: a flavour whose Gradle config disagreed
     * with the dart-define would be a build that says "staging" on the icon and
     * talks to production, which is worse than having no flavours at all.
     */
    // AGP 9 disables generated resource values by default. Enabled deliberately:
    // the alternative is a per-flavour strings.xml in three source sets, which is
    // three files to keep in step for one string.
    buildFeatures {
        resValues = true
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Taytay LGU (dev)")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "Taytay LGU (staging)")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Taytay LGU IDS")
        }
    }

    buildTypes {
        release {
            /*
             * NO FALLBACK TO THE DEBUG KEY, and that is the point of this change
             * (F03).
             *
             * The template this replaced signed release builds with the debug key
             * "so `flutter run --release` works" — and it does work, which is the
             * problem: the build succeeds, the artifact looks finished, and it is
             * unpublishable in a way nothing announces. That artifact existed in
             * this repository through twenty-eight TABs and a release-readiness
             * audit.
             *
             * Absent credentials now leave the config unsigned, so the build
             * fails at signing rather than producing something that cannot be
             * shipped. A failure a developer meets in a minute is cheaper than a
             * store rejection three weeks later.
             */
            signingConfig = signingConfigs.getByName("release")

            // Kept off deliberately. Shrinking changes what ships, and this app
            // has no measured size problem to solve with it — 19.5 MB of a 20.9 MB
            // artifact is the Flutter engine (TAB 20). Turning it on before there
            // is a reason risks a reflection-related crash that only appears in
            // release, which is the worst place to find one.
            isMinifyEnabled = false
            isShrinkResources = false
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

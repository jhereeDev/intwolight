import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing, from whichever source is present.
//
// ⚠️ This file used to sign release builds with the DEBUG key — the Flutter
// template default, TODO comment and all. `flutter run --release` works fine
// that way, which is exactly why it survived: nothing fails until Google Play
// rejects the upload, minutes after a CI build has already run.
//
// Two sources, in order:
//   1. android/key.properties  — local builds on this machine.
//   2. CM_* environment vars   — Codemagic, which writes the keystore to disk
//      and exports the path/passwords. `codemagic.yaml`'s android-release
//      workflow declares them in the InTwoLights_Android group; before this
//      change Gradle ignored every one of them.
//
// Neither is in the repo, and `android/.gitignore` already excludes
// key.properties, *.keystore and *.jks. Keep it that way.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}

val cmKeystorePath: String? = System.getenv("CM_KEYSTORE_PATH")
val hasLocalKey = keystorePropertiesFile.exists()
val hasCiKey = !cmKeystorePath.isNullOrBlank()
val canSignRelease = hasLocalKey || hasCiKey

android {
    namespace = "com.jhere.intwolights"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Must stay identical to the iOS bundle ID. RevenueCat keys products
        // per app per store, and a mismatch surfaces as missing entitlements.
        applicationId = "com.jhere.intwolights"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (canSignRelease) {
            create("release") {
                if (hasLocalKey) {
                    keyAlias = keystoreProperties["keyAlias"] as String?
                    keyPassword = keystoreProperties["keyPassword"] as String?
                    storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                    storePassword = keystoreProperties["storePassword"] as String?
                } else {
                    keyAlias = System.getenv("CM_KEY_ALIAS")
                    keyPassword = System.getenv("CM_KEY_PASSWORD")
                    storeFile = file(cmKeystorePath!!)
                    storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (canSignRelease) {
                signingConfigs.getByName("release")
            } else {
                // Kept so `flutter run --release` still works on a machine with
                // no key. The warning below is the whole point — a silent
                // fallback is how a debug-signed bundle reaches an upload form.
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Printed at configure time so it lands near the top of a CI log, where it is
// actually read, rather than buried next to the APK path.
gradle.projectsEvaluated {
    val source = when {
        hasLocalKey -> "android/key.properties"
        hasCiKey -> "CM_KEYSTORE_PATH (Codemagic)"
        else -> null
    }
    if (source != null) {
        logger.lifecycle("✅ release signing key: $source")
    } else {
        logger.warn(
            "⚠️  NO RELEASE KEYSTORE — release builds are signed with the DEBUG " +
                "key. Google Play will reject this bundle on upload. Provide " +
                "android/key.properties locally, or the InTwoLights_Android " +
                "environment group in Codemagic."
        )
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

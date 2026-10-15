plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.graviton94.homefairy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.graviton94.homefairy"
        // Android 8.0+ (docs/plan.md)
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // CI passes --build-number (run number) and --build-name.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Test key for installing builds directly on phones. Not a secret: it lives in the repo
        // so every CI build has the same signature and updates install over each other.
        create("sideload") {
            storeFile = file("../keystore/sideload.jks")
            storePassword = "android"
            keyAlias = "sideload"
            keyPassword = "android"
        }
        // Play upload key: only when all four variables are set (aab workflow).
        val uploadStore = System.getenv("ANDROID_UPLOAD_KEYSTORE")?.takeIf { it.isNotBlank() && file(it).exists() }
        val uploadVars = listOf("ANDROID_UPLOAD_STORE_PASSWORD", "ANDROID_UPLOAD_KEY_ALIAS", "ANDROID_UPLOAD_KEY_PASSWORD")
            .map { System.getenv(it).orEmpty() }
        if (uploadStore != null && uploadVars.all { it.isNotBlank() }) {
            create("upload") {
                storeFile = file(uploadStore)
                storePassword = uploadVars[0]
                keyAlias = uploadVars[1]
                keyPassword = uploadVars[2]
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("sideload")
        }
        release {
            signingConfig = signingConfigs.findByName("upload") ?: signingConfigs.getByName("sideload")
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

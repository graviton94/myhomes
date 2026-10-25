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
        // Test key for installing builds directly on phones, so every CI build updates over the last.
        // app.yml unlocks keystore/sideload.jks.gpg with the SIDELOAD_PASSPHRASE secret and passes the path here.
        // Without it (a local build) the debug key signs instead (keystore/README.md).
        val sideloadStore = System.getenv("HF_SIDELOAD_STORE")?.takeIf { it.isNotBlank() && file(it).exists() }
        val sideloadPass = System.getenv("HF_SIDELOAD_PASSWORD").orEmpty()
        if (sideloadStore != null && sideloadPass.isNotBlank()) {
            create("sideload") {
                storeFile = file(sideloadStore)
                storePassword = sideloadPass
                keyAlias = "sideload"
                keyPassword = sideloadPass
            }
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
            signingConfig = signingConfigs.findByName("sideload") ?: signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.findByName("upload") ?: signingConfigs.findByName("sideload")
                ?: signingConfigs.getByName("debug")
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

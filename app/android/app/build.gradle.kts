plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.graviton94.homefairy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications needs java.time on older Android.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "io.github.graviton94.homefairy"
        // Android 8.0+ (docs/plan.md)
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // CI passes --build-number (run number) and --build-name.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Login keys from CI secrets (app.yml); placeholders in local builds.
        manifestPlaceholders["kakaoScheme"] = "kakao" + (System.getenv("HF_KAKAO_NATIVE_APP_KEY")?.takeIf { it.isNotBlank() } ?: "none")
        resValue("string", "naver_client_id", System.getenv("HF_NAVER_CLIENT_ID").orEmpty())
        resValue("string", "naver_client_secret", System.getenv("HF_NAVER_CLIENT_SECRET").orEmpty())
        resValue("string", "naver_client_name", "Home Fairy")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

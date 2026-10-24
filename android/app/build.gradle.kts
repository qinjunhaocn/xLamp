
plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 通过环境变量注入 release 签名信息（GitHub Actions secrets → env）。
val keystorePath: String = System.getenv("XLAMP_KEYSTORE") ?: ""
val keystoreFile = file(keystorePath)
val hasReleaseKeystore = keystorePath.isNotEmpty() && keystoreFile.exists()

android {
    namespace = "com.voxyn.xlamp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.voxyn.xlamp"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = keystoreFile
                storePassword = System.getenv("XLAMP_STORE_PASSWORD")
                keyAlias = System.getenv("XLAMP_KEY_ALIAS")
                keyPassword = System.getenv("XLAMP_KEY_PASSWORD")
                // 同时启用 v1 / v2 / v3 签名方案。
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
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

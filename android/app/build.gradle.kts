plugins {
    id("com.android.application")
    id("kotlin-android")

    // 🔐 Firebase Google Services plugin (ADDED)
    id("com.google.gms.google-services")

    // Flutter plugin (MUST be last)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.healt"
    compileSdk = flutter.compileSdkVersion

    // ✅ REQUIRED NDK version (RETAINED)
    ndkVersion = "27.0.12077973"

    compileOptions {
        // ✅ REQUIRED for flutter_local_notifications v17+
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.healt"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ⚠️ Debug signing for now (RETAINED)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ✅ REQUIRED desugaring library (RETAINED)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

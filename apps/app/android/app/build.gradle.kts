import java.util.Base64
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val dartDefines = mutableMapOf<String, String>()
if (project.hasProperty("dart-defines")) {
    val defines = project.property("dart-defines") as String
    defines.split(",").forEach { entry ->
        val decoded = String(Base64.getDecoder().decode(entry))
        val pair = decoded.split("=", limit = 2)
        if (pair.size == 2) {
            dartDefines[pair[0]] = pair[1]
        }
    }
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseTaskRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "android/key.properties is required for a release build. " +
            "Restore it together with android/app/release.jks before building.",
    )
}

android {
    namespace = "jp.flutterkaigi.conf2026"
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
        applicationId = "jp.flutterkaigi.conf2026"
        dartDefines["APP_ID_SUFFIX"]?.let {
            applicationIdSuffix = it
        }
        manifestPlaceholders["appLabel"] = dartDefines["APP_NAME"] ?: "FlutterKaigi 2026"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

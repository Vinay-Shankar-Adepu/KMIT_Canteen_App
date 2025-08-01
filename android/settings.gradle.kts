pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Flutter build loader
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // ✅ Android application plugin
    id("com.android.application") version "8.2.2" apply false

    // ✅ Kotlin plugin - required for Firebase Auth & Kotlin-based MainActivity.kt
    id("org.jetbrains.kotlin.android") version "2.1.21" apply false

    // ✅ Google services plugin for Firebase
    id("com.google.gms.google-services") version "4.3.15" apply false
}

include(":app")

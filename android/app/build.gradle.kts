import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun hasReleaseSigningConfig(): Boolean {
    val requiredKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    return requiredKeys.all { key ->
        keystoreProperties.getProperty(key)?.isNotBlank() == true
    }
}

android {
    namespace = "com.opizza.app_client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.opizza.app_client"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigningConfig()) {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigningConfig()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.register("validateReleaseSigning") {
    doLast {
        if (!hasReleaseSigningConfig()) {
            throw GradleException(
                "Missing Android release signing config. Create android/key.properties " +
                    "from key.properties.example and provide a real upload keystore."
            )
        }
    }
}

tasks.matching {
    it.name in setOf("assembleRelease", "bundleRelease", "packageRelease")
}.configureEach {
    dependsOn("validateReleaseSigning")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

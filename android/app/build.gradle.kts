import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val fallbackTestKeystore = rootProject.file("test.keystore")
val keystoreMode = when {
    keystorePropertiesFile.exists() -> {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        "keyProperties"
    }
    fallbackTestKeystore.exists() -> {
        keystoreProperties["storeFile"] = fallbackTestKeystore.absolutePath
        keystoreProperties["storePassword"] = "123456"
        keystoreProperties["keyAlias"] = "testkey"
        keystoreProperties["keyPassword"] = "123456"
        "ciTestKeystore"
    }
    else -> "debugKeystore"
}

android {
    namespace = "liubquanti.white.cobalt"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "liubquanti.white.cobalt"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreMode == "debugKeystore") {
            val debugConfig = getByName("debug")
            create("release") {
                storeFile = debugConfig.storeFile
                storePassword = debugConfig.storePassword
                keyAlias = debugConfig.keyAlias
                keyPassword = debugConfig.keyPassword
            }
        } else {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = false
            isShrinkResources = false

            when (keystoreMode) {
                "keyProperties" -> println("🔐 Release build: using real key.properties")
                "ciTestKeystore" -> println("⚠️ Release build: using temporary test keystore for CI")
                else -> println("⚠️ Release build: using Android debug keystore fallback; add key.properties for production")
            }
        }
    }
}

flutter {
    source = "../.."
}

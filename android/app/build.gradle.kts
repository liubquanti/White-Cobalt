import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    // Тимчасовий ключ для CI
    keystoreProperties["storeFile"] = rootProject.file("test.keystore").absolutePath
    keystoreProperties["storePassword"] = "123456"
    keystoreProperties["keyAlias"] = "testkey"
    keystoreProperties["keyPassword"] = "123456"
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
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // Вимикаємо мінімізацію і стиск ресурсів для стабільності на CI
            isMinifyEnabled = false
            isShrinkResources = false

            // Лог для зрозумілості
            if (keystorePropertiesFile.exists()) {
                println("🔐 Release build: using real key.properties")
            } else {
                println("⚠️ Release build: using temporary test keystore for CI")
            }
        }
    }
}

flutter {
    source = "../.."
}

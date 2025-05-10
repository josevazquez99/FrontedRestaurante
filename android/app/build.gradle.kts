plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")  // Plugin necesario para Flutter

    // Firebase plugin
    id("com.google.gms.google-services")  // Añadir el plugin de Google Services
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
}

android {
    namespace = "com.example.restaurante_flutter_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.restaurante_flutter_app"  // ID de la aplicación
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")  // Configuración de firma para el release
        }
    }
}

flutter {
    source = "../.."
}



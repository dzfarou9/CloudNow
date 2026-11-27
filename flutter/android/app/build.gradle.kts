plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.opencloudgaming.opennow_android"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.opencloudgaming.opennow"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    buildTypes {
        release {
            // Codemagic supplies the upload keystore through these properties.
            // Local builds keep the debug signing config so they still install.
            val keystorePath = project.findProperty("opennow.keystore") as String?
            val storePass = project.findProperty("opennow.storePassword") as String?
            val keyAliasName = project.findProperty("opennow.keyAlias") as String?
            val keyPass = project.findProperty("opennow.keyPassword") as String?

            signingConfig = if (keystorePath != null && storePass != null &&
                keyAliasName != null && keyPass != null
            ) {
                signingConfigs.create("release") {
                    storeFile = file(keystorePath)
                    storePassword = storePass
                    keyAlias = keyAliasName
                    keyPassword = keyPass
                }
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = false
        }
    }

    sourceSets {
        getByName("main").jniLibs.srcDirs("src/main/jniLibs")
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

/**
 * Optional Rust bridge build. The core/streamer live in Rust, so an Android
 * build needs cargo-ndk on the machine. Opt in with `-PbuildRust` (Codemagic
 * does this); plain `flutter run` keeps working without a local Rust toolchain.
 */
val buildRust = tasks.register<Exec>("buildRust") {
    onlyIf { project.hasProperty("buildRust") }
    workingDir = file("../..")
    commandLine(
        "cargo", "ndk",
        "-t", "arm64-v8a",
        "-t", "armeabi-v7a",
        "-t", "x86_64",
        "-o", "android/app/src/main/jniLibs",
        "build", "--release",
        "--manifest-path", "rust/opennow_mobile/Cargo.toml",
    )
}

tasks.named("preBuild") {
    dependsOn(buildRust)
}

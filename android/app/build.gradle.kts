import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val storeBuild = providers.gradleProperty("chaengimStoreRelease").orNull == "true" ||
    gradle.startParameter.taskNames.any {
        it.substringAfterLast(':').startsWith("bundle", ignoreCase = true) &&
            it.endsWith("Release", ignoreCase = true)
    }
val publishedApplicationId = providers.gradleProperty("chaengimApplicationId")
    .getOrElse("com.example.my_first_app")
val previewBuild = providers.gradleProperty("chaengimPreview").orNull == "true"
val uploadProperties = Properties()
if (storeBuild) {
    require(!previewBuild) { "Store builds cannot use preview data." }
    require(
        publishedApplicationId.matches(Regex("[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+")) &&
            !publishedApplicationId.startsWith("com.example.")
    ) { "Set a permanent chaengimApplicationId before building for a store." }
    val keyFile = rootProject.file("key.properties")
    require(keyFile.isFile) { "Store builds require android/key.properties and an upload keystore." }
    keyFile.inputStream().use { uploadProperties.load(it) }
    for (name in listOf("storeFile", "storePassword", "keyAlias", "keyPassword")) {
        require(!uploadProperties.getProperty(name).isNullOrBlank()) {
            "Missing signing setting: $name"
        }
    }
    require(rootProject.file(uploadProperties.getProperty("storeFile")).isFile) {
        "Upload keystore file not found."
    }
}

android {
    namespace = "com.example.my_first_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = if (previewBuild)
            "$publishedApplicationId.preview" else publishedApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Defaults to Google's demo app. Release ads remain off without Dart configuration.
        manifestPlaceholders["admobAppId"] = providers.gradleProperty("admobAppId")
            .getOrElse("ca-app-pub-3940256099942544~3347511713")
    }

    signingConfigs {
        if (storeBuild) {
            create("upload") {
                storeFile = rootProject.file(uploadProperties.getProperty("storeFile"))
                storePassword = uploadProperties.getProperty("storePassword")
                keyAlias = uploadProperties.getProperty("keyAlias")
                keyPassword = uploadProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // APKs for local testing retain their existing signature and data.
            signingConfig = signingConfigs.getByName(if (storeBuild) "upload" else "debug")
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
    // Ads brings WorkManager 2.7.0; its Room startup fails with current R8.
    implementation("androidx.work:work-runtime:2.11.2")
    testImplementation("junit:junit:4.13.2")
}

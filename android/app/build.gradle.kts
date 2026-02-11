/*
 * Copyright (C) 2026 Rootify - Aby - FoxLabs
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ---- CORE IMPORTS & LIBRARIES ----
// Standard library dependencies for dynamic versioning and build orchestration.
import java.util.Properties
import java.io.FileInputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date

// ---- APPLICATION VERSIONING CONFIGURATION ----
// Logic for dynamic version code and version name generation based on build context.
fun getAppVersionConfig(): Map<String, Any> {
    val versionFile = file("version.properties")
    val props = Properties()
    
    // --- File initialization
    if (!versionFile.exists()) {
        versionFile.createNewFile()
    }
    
    // --- Property persistence loading
    FileInputStream(versionFile).use { props.load(it) }

    // --- Build context determination
    // Prioritizes explicit -Pctx=[context] followed by shorthand flags (-Palpha, -Pbeta, etc.).
    val buildContext = when {
        project.hasProperty("ctx") -> project.property("ctx").toString()
        project.hasProperty("alpha") -> "alpha"
        project.hasProperty("beta") -> "beta"
        project.hasProperty("rc") -> "rc"
        project.hasProperty("stable") -> "stable"
        else -> "stable"
    }
    
    // --- Versioning group mapping
    val groupKey = buildContext
    
    // --- Smart Version Increment Logic
    // Increments version code strictly for standalone Release builds to prevent development-time bloat.
    // Detection Heuristic: Only increments for direct build tasks (assemble/bundle), NOT during 'run'/install flows.
    val taskNames = project.gradle.startParameter.taskNames
    val isReleaseBuild = taskNames.any { 
        (it.contains("assemble") || it.contains("bundle")) && it.contains("Release") 
    } && taskNames.none { it.contains("install") }
    
    val currentCount = if (isReleaseBuild) {
        val next = (props["${groupKey}_count"]?.toString() ?: "0").toInt() + 1
        props["${groupKey}_count"] = next.toString()
        
        // --- Save properties with copyright header
        FileOutputStream(versionFile).use { out ->
            out.write(("""#
# Copyright (C) 2026 Rootify - Aby - FoxLabs
# Licensed under the Apache License, Version 2.0
#
""").trimIndent().toByteArray())
            props.store(out, null)
        }
        next
    } else {
        (props["${groupKey}_count"]?.toString() ?: "0").toInt()
    }

    // --- Semantic version construction
    val baseVersion = when (buildContext) {
        "alpha", "beta" -> "0.9.$currentCount"
        "rc" -> "0.9.9.$currentCount"
        else -> "1.0.$currentCount"
    }

    // --- Metadata generation
    val timestamp = SimpleDateFormat("yyMMdd").format(Date())
    
    return mapOf(
        "code" to (timestamp.toLong() * 100 + currentCount).toInt(),
        "name" to "$baseVersion-$buildContext",
        "label" to baseVersion,
        "context" to buildContext,
        "build" to currentCount
    )
}

// Global configuration initialization
val appConfig = getAppVersionConfig()

// ---- PLUGIN CONFIGURATION ----
// Android and Flutter integration plugin definitions.
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ---- ANDROID PROJECT SETTINGS ----
// ---- SECURE SIGNING CONFIGURATION ----
// Load keystore credentials from external properties for release builds.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("android/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Core SDK targets, compilation options, and build variant configurations.
android {
    namespace = "com.aby.rootify"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // --- Java & Kotlin Language Compatibility
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    // --- Keystore Orchestration
    signingConfigs {
        getByName("debug") {
            // Standard Android debug signing
        }
        create("release") {
            // Production signing with secure fallback to debug if key.properties is missing
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // --- Default Application Configuration
    defaultConfig {
        applicationId = "com.aby.rootify"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        // Dynamic version assignment from getAppVersionConfig
        versionCode = appConfig["code"] as Int
        versionName = appConfig["name"] as String
    }

    // --- Build Variant Management
    buildTypes {
        getByName("debug") {
            // Standard development mode (JIT)
            isDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("profile") {
            // Performance profiling mode (AOT)
            initWith(getByName("release"))
            isDebuggable = true
            signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            matchingFallbacks.add("release")
        }
        getByName("release") {
            // Production deployment mode (AOT)
            isDebuggable = false
            signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            isShrinkResources = false
            isMinifyEnabled = false
        }
    }
}

// ---- POST-BUILD AUTOMATION PIPELINE ----
// Automated deployment logic executed after successful compilation.
afterEvaluate {
    // Orchestrate deployment for Debug, Release, and Profile binaries.
    val targetTasks = listOf("assembleDebug", "assembleProfile", "assembleRelease")
    targetTasks.forEach { taskName ->
        tasks.findByName(taskName)?.doLast {
            val outputDir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
            val homeDir = System.getProperty("user.home")
            val currentTime = SimpleDateFormat("HH-mm-ss").format(Date())
            val date = SimpleDateFormat("yyyyMMdd").format(Date())
            val projectName = "rootify"
            val label = appConfig["label"]
            val ctx = appConfig["context"].toString()
            val bNumber = appConfig["build"]
            val buildMode = when {
                taskName.contains("Profile") -> "profile"
                taskName.contains("Debug") -> "debug"
                else -> "release"
            }

            // --- Run Detection Heuristic
            // Development runs are identified by the presence of an 'install' task.
            val isInstallFlow = project.gradle.startParameter.taskNames.any { it.contains("install") }
            
            // --- Destination Directory Mapping
            val destDir = if (isInstallFlow) {
                // Development runs go to a timestamped archive to prevent run-time state pollution.
                File("$homeDir/Apps/Run/$currentTime.run")
            } else {
                // Standalone builds go to their respective context-named directories.
                val destDirName = ctx.replaceFirstChar { it.uppercase() }
                File("$homeDir/Apps/$destDirName")
            }
            
            if (!destDir.exists()) {
                destDir.mkdirs()
            }
            
            // --- ABI-Specific Deployment (ARM Optimized)
            if (outputDir.exists()) {
                outputDir.listFiles()?.forEach { file ->
                    // Process only relevant build-mode APKs
                    if (file.name.startsWith("app-") && file.name.endsWith("-$buildMode.apk")) {
                        
                        // --- Architecture Filtering (Exclude x86/x86_64)
                        val abi = when {
                            file.name.contains("arm64-v8a") -> "arm64-v8a"
                            file.name.contains("armeabi-v7a") -> "armeabi-v7a"
                            else -> null // Skip non-ARM architectures
                        }
                        
                        if (abi != null) {
                            val runtimeMeta = if (isInstallFlow) "-run" else ""
                            val newName = "$projectName-$abi-$label-$ctx-$date-b$bNumber-$buildMode$runtimeMeta.apk"
                            val destFile = File(destDir, newName)
                            
                            // Deploy file to targeted Apps directory
                            file.copyTo(destFile, overwrite = true)
                            println("Success: $newName -> ${destDir.absolutePath.replace(homeDir, "~")}/")
                        }
                    }
                }
            }
        }
    }
}

// ---- FLUTTER CORE INTEGRATION ----
flutter {
    source = "../.."
}

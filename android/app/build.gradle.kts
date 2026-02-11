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

import java.util.Properties
import java.io.FileInputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date

fun getAppVersionConfig(): Map<String, Any> {
    val versionFile = file("version.properties")
    val props = Properties()
    
    if (!versionFile.exists()) {
        versionFile.createNewFile()
    }
    
    FileInputStream(versionFile).use { props.load(it) }

    val buildContext = if (project.hasProperty("ctx")) project.property("ctx").toString() else "stable"
    val groupKey = if (buildContext in listOf("alpha", "beta")) "test_group" else buildContext
    
    // Only increment version if strictly building (to avoid bloat on IDE sync)
    val isBuild = project.gradle.startParameter.taskNames.any { it.contains("assemble") || it.contains("bundle") }
    val currentCount = if (isBuild) {
        val next = (props["${groupKey}_count"]?.toString() ?: "0").toInt() + 1
        props["${groupKey}_count"] = next.toString()
        FileOutputStream(versionFile).use { props.store(it, null) }
        next
    } else {
        (props["${groupKey}_count"]?.toString() ?: "0").toInt()
    }

    val baseVersion = when (buildContext) {
        "alpha", "beta" -> "0.9.$currentCount"
        "rc" -> "0.9.9.$currentCount"
        else -> "1.0.$currentCount"
    }

    val timestamp = SimpleDateFormat("yyMMdd").format(Date())
    
    return mapOf(
        "code" to (timestamp.toLong() * 100 + currentCount).toInt(),
        "name" to "$baseVersion-$buildContext",
        "label" to baseVersion,
        "context" to buildContext,
        "build" to currentCount
    )
}

val appConfig = getAppVersionConfig()

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aby.rootify"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.aby.rootify"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        versionCode = appConfig["code"] as Int
        versionName = appConfig["name"] as String
    }

    buildTypes {
        getByName("debug") {
            // Explicitly set debuggable true for debug builds
            isDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            // Ensure release is not debuggable
            isDebuggable = false
            signingConfig = signingConfigs.getByName("debug")
            isShrinkResources = false
            isMinifyEnabled = false
        }
    }
}

afterEvaluate {
    tasks.named("assembleRelease") {
        doLast {
            val outputDir = file("$buildDir/outputs/flutter-apk")
            val homeDir = System.getProperty("user.home")
            val date = SimpleDateFormat("yyyyMMdd").format(Date())
            val projectName = "rootify"
            val label = appConfig["label"]
            val ctx = appConfig["context"].toString()
            val bNumber = appConfig["build"]

            val destDirName = ctx.capitalize()
            val destDir = File("$homeDir/Apps/$destDirName")
            
            // Create destination directory if it doesn't exist
            if (!destDir.exists()) {
                destDir.mkdirs()
            }
            
            if (outputDir.exists()) {
                outputDir.listFiles()?.forEach { file ->
                    if (file.name.startsWith("app-") && file.name.endsWith("-release.apk")) {
                        // Extract ABI from filename
                        val abi = when {
                            file.name.contains("arm64-v8a") -> "arm64-v8a"
                            file.name.contains("armeabi-v7a") -> "armeabi-v7a"
                            file.name.contains("x86_64") -> "x86_64"
                            file.name.contains("x86") -> "x86"
                            else -> "universal"
                        }
                        
                        val newName = "$projectName-$abi-$label-$ctx-$date-b$bNumber.apk"
                        val destFile = File(destDir, newName)
                        
                        // Copy APK to destination (keep original for Flutter validation)
                        file.copyTo(destFile, overwrite = true)
                        
                        println("Copied: $newName -> ~/Apps/$destDirName/")
                    }
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

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

// ---- SYSTEM ---
import 'dart:io';

// ---- EXTERNAL ---
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// ---- LOCAL ---
import '../services/shell_services.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Rootify Module Orchestrator
// Orchestrates the construction of the systemless module using dedicated folder handlers.
class RootifyModuleBuilder {
  static const String moduleDir = "/data/adb/modules/rootify";
  static const String internalBin = "/data/data/com.aby.rootify/files/bin";
  static const String internalShell = "/data/data/com.aby.rootify/files/shell";

  static Future<void> extractAssets() async {
    logger.i("ModuleBuilder: Extracting internal toolchain assets...");

    // Ensure internal cache directories exist
    await Directory(internalBin).create(recursive: true);
    await Directory(internalShell).create(recursive: true);

    final binaries = [
      'GOVERNOR',
      'MINFREQ',
      'MAXFREQ',
      'ZRAM-SIZE',
      'ZRAM-ALGHORITM',
      'SWAP-AGGRESIVE',
      'VFS-CACHE',
      'FPSGO',
      'ROOTIFY',
      'laya-battery-monitor',
      'laya-kernel-tuner'
    ];

    final scripts = [
      'GOVERNOR.sh',
      'MINFREQ.sh',
      'MAXFREQ.sh',
      'ZRAM-SIZE.sh',
      'ZRAM-ALGHORITM.sh',
      'SWAP-AGGRESIVE.sh',
      'VFS-CACHE.sh',
      'ZRAM-CONFIG.sh',
      'THERMAL.sh',
      'BATTMON.sh',
      'KERTUN.sh',
      'FPSGO.sh'
    ];

    for (final b in binaries) {
      // Laya binaries are in lib/bin/ along with other tools
      await _extractFile("lib/bin/$b", "$internalBin/$b");
    }

    for (final s in scripts) {
      await _extractFile("lib/shell/sh/$s", "$internalShell/$s");
    }
  }

  static Future<void> _extractFile(String assetPath, String targetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final file = File(targetPath);

      // Optimization: Only write if file doesn't exist or is empty
      if (!await file.exists() || await file.length() == 0) {
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
        await Process.run('chmod', ['+x', targetPath]);
      }
    } catch (e) {
      logger.e("ModuleBuilder: Failed to extract $assetPath", e);
    }
  }

  static Future<void> buildAndSync(
    ShellService shell, {
    required bool cpuEnabled,
    required bool cpuDisabled,
    required Map<String, dynamic> cpuSettings,
    required bool zramEnabled,
    required int zramSizeMb,
    String? zramAlgo,
    int? swappiness,
    int? vfsCachePressure,
    required String appVersion,
    required String versionCode,
    required bool layaEnabled,
    required List<String> activeLayaModules,
    required bool thermalEnabled,
    required bool thermalDisabled,
    bool? fpsGoEnabled,
    Map<String, dynamic>? fpsGoSettings,
  }) async {
    logger.d("ModuleBuilder: Constructing systemless payload...");

    try {
      final tempDir = await getTemporaryDirectory();

      // OPTIMIZATION: Check for Fast Sync (Config Only)
      if (await _FolderRoot.canFastSync(shell, moduleDir, versionCode)) {
        logger.d("ModuleBuilder: Version match. Performing Fast Sync.");
        await _FolderConfigs.deploy(
          shell,
          tempDir,
          moduleDir,
          cpuSettings: cpuSettings,
          zramSizeMb: zramSizeMb,
          zramAlgo: zramAlgo,
          swappiness: swappiness,
          vfsCachePressure: vfsCachePressure,
          layaEnabled: layaEnabled,
          activeLayaModules: activeLayaModules,
          thermalEnabled: thermalEnabled,
          fpsGoEnabled: fpsGoEnabled,
          fpsGoSettings: fpsGoSettings,
        );
        return;
      }

      logger.d("ModuleBuilder: Performing FULL construction...");

      // 0. Ensure assets are extracted to internal cache
      await extractAssets();

      // 1. Prepare Structure
      await shell.exec(
          "mkdir -p $moduleDir/shell $moduleDir/bin $moduleDir/logs $moduleDir/configs");

      // 2. Folder: ROOT (Metadata & Lifecycle)
      await _FolderRoot.deploy(
        shell,
        tempDir,
        moduleDir,
        internalBin,
        internalShell,
        appVersion,
        versionCode,
      );

      // 3. Folder: BIN (Executables)
      await _FolderBin.deploy(shell, moduleDir, internalBin);

      // 4. Folder: SHELL (Wrappers)
      await _FolderShell.deploy(shell, moduleDir, internalShell);

      // 5. Folder: CONFIGS (Persistence for ROOTIFY boot)
      await _FolderConfigs.deploy(
        shell,
        tempDir,
        moduleDir,
        cpuSettings: cpuSettings,
        zramSizeMb: zramSizeMb,
        zramAlgo: zramAlgo,
        swappiness: swappiness,
        vfsCachePressure: vfsCachePressure,
        layaEnabled: layaEnabled,
        activeLayaModules: activeLayaModules,
        thermalEnabled: thermalEnabled,
        fpsGoEnabled: fpsGoEnabled,
        fpsGoSettings: fpsGoSettings,
      );

      // 6. [DEPRECATED] Folder: PAYLOAD (Removed in favor of ROOTIFY boot)

      // 7. Finalize
      await shell.exec("rm -f /data/adb/service.d/rootify_boot.sh");
      await shell.exec("chown -R 0.0 $moduleDir");

      logger.d("ModuleBuilder: Build successful.");
    } catch (e) {
      logger.e("ModuleBuilder: Build failed", e);
      rethrow;
    }
  }
}

// ---- MAJOR ---
// Folder Handlers

class _FolderRoot {
  static Future<bool> canFastSync(
      ShellService shell, String moduleDir, String versionCode) async {
    try {
      final currentProp = await shell
          .exec("cat $moduleDir/module.prop 2>/dev/null", canSkip: true);
      return currentProp.contains("versionCode=$versionCode");
    } catch (_) {
      return false;
    }
  }

  static Future<void> deploy(
    ShellService shell,
    Directory tempDir,
    String moduleDir,
    String internalBin,
    String internalShell,
    String appVersion,
    String versionCode,
  ) async {
    // 1. module.prop (Must be generated as it depends on app version/code)
    final prop =
        "id=rootify\nname=Rootify\nversion=$appVersion\nversionCode=$versionCode\nauthor=Rootify - Aby\ndescription=Advanced System Performance & Tuning Suite for Android.";
    final fProp = File('${tempDir.path}/module.prop');
    await fProp.writeAsString(prop);
    await shell.exec("mv -f ${fProp.path} $moduleDir/module.prop");

    // 2. Centerpiece: Monolithic ROOTIFY
    await shell.exec("cp -f $internalBin/ROOTIFY $moduleDir/ROOTIFY");
    await shell.exec("chmod +x $moduleDir/ROOTIFY");

    // 3. Lifecycle Scripts (Sourced from internalShell)
    await shell.exec("cp -f $internalShell/service.sh $moduleDir/service.sh");
    await shell.exec("cp -f $internalShell/action.sh $moduleDir/action.sh");
    await shell
        .exec("cp -f $internalShell/uninstall.sh $moduleDir/uninstall.sh");

    await shell.exec("chmod +x $moduleDir/service.sh");
    await shell.exec("chmod +x $moduleDir/action.sh");
    await shell.exec("chmod +x $moduleDir/uninstall.sh");
  }
}

// Note: _FolderPayload (zigbin) has been consolidated into ROOTIFY boot logic.

class _FolderBin {
  static Future<void> deploy(
      ShellService shell, String moduleDir, String internalBin) async {
    // 1. Specialized Binaries (Granular)
    final tools = [
      'GOVERNOR',
      'MINFREQ',
      'MAXFREQ',
      'ZRAM-SIZE',
      'ZRAM-ALGHORITM',
      'SWAP-AGGRESIVE',
      'VFS-CACHE',
      'FPSGO',
      'laya-battery-monitor',
      'laya-kernel-tuner'
    ];
    for (final b in tools) {
      await shell.exec("cp -f $internalBin/$b $moduleDir/bin/$b");
      await shell.exec("chmod +x $moduleDir/bin/$b");
    }
  }
}

class _FolderShell {
  static Future<void> deploy(
      ShellService shell, String moduleDir, String internalShell) async {
    final scripts = ['FPSGO.sh'];
    for (final s in scripts) {
      await shell.exec("cp -f $internalShell/$s $moduleDir/shell/$s");
      await shell.exec("chmod +x $moduleDir/shell/$s");
    }
  }
}

class _FolderConfigs {
  static Future<void> deploy(
    ShellService shell,
    Directory tempDir,
    String moduleDir, {
    required Map<String, dynamic> cpuSettings,
    required int zramSizeMb,
    String? zramAlgo,
    int? swappiness,
    int? vfsCachePressure,
    required bool layaEnabled,
    required List<String> activeLayaModules,
    required bool thermalEnabled,
    bool? fpsGoEnabled,
    Map<String, dynamic>? fpsGoSettings,
  }) async {
    final configsDir = "$moduleDir/configs";

    // 1. CPU
    final cpuFiles = {
      'MAXFREQ': 'max',
      'MINFREQ': 'min',
      'GOVERNOR': 'governor'
    };
    for (final entry in cpuFiles.entries) {
      final sb = StringBuffer();
      cpuSettings.forEach((policy, data) {
        if (data[entry.value] != null) {
          final policyNum = policy.replaceAll('policy', '');
          sb.writeln("$policyNum:${data[entry.value]}");
        }
      });
      if (sb.isNotEmpty) {
        final file = File('${tempDir.path}/${entry.key}');
        await file.writeAsString(sb.toString());
        await shell.exec("mv -f ${file.path} $configsDir/${entry.key}");
      }
    }

    // 2. ZRAM
    await _writeSingle(
        shell, tempDir, configsDir, 'ZRAM-SIZE', zramSizeMb.toString());
    await _writeSingle(
        shell, tempDir, configsDir, 'ZRAM-ALGHORITM', zramAlgo ?? 'lzo');
    await _writeSingle(shell, tempDir, configsDir, 'SWAP-AGGRESIVE',
        (swappiness ?? 60).toString());
    await _writeSingle(shell, tempDir, configsDir, 'VFS-CACHE',
        (vfsCachePressure ?? 100).toString());

    // 3. Services (Laya & Thermal)
    final serviceFiles = {
      'BATTMON': 'laya-battery-monitor',
      'KERTUN': 'laya-kernel-tuner',
      'THERMAL': 'thermal'
    };
    for (final s in serviceFiles.entries) {
      bool enabled = false;
      if (s.key == 'THERMAL') {
        enabled = thermalEnabled;
      } else {
        enabled = layaEnabled && activeLayaModules.contains(s.value);
      }
      final content = "applyonBoot?: ${enabled ? 'true' : 'false'}";
      await _writeSingle(shell, tempDir, configsDir, s.key, content);
    }

    // 4. FPSGO
    if (fpsGoEnabled == true && fpsGoSettings != null) {
      final sb = StringBuffer();
      final path = fpsGoSettings['path'] as String?;
      final enabled = fpsGoSettings['enabled'] == true ||
          fpsGoSettings['enabled'].toString().toLowerCase() == 'true';
      if (path != null) {
        sb.writeln("enable:$path:${enabled ? '1' : '0'}");
        if (fpsGoSettings['mode'] != null) {
          sb.writeln("mode:$path:${fpsGoSettings['mode']}");
        }
        if (fpsGoSettings.containsKey('parameters')) {
          (fpsGoSettings['parameters'] as Map<String, dynamic>)
              .forEach((p, v) => sb.writeln("set:$p:$v"));
        }
      }
      if (sb.isNotEmpty) {
        final file = File('${tempDir.path}/FPSGO');
        await file.writeAsString(sb.toString());
        await shell.exec("mv -f ${file.path} $configsDir/FPSGO");
      }
    }
  }

  static Future<void> _writeSingle(ShellService shell, Directory tempDir,
      String configsDir, String name, String val) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString(val);
    await shell.exec("mv -f ${file.path} $configsDir/$name");
  }
}

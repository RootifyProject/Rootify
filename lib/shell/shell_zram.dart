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

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../shell/base_shell.dart';
import '../shell/shellsession.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// ZRAM Statistics Container
class ZramStats {
  final int origDataSize;
  final int comprDataSize;
  final int memUsedTotal;
  final int memLimit;
  final int memUsedMax;
  final int samePages;
  final int pagesCompact;

  const ZramStats({
    this.origDataSize = 0,
    this.comprDataSize = 0,
    this.memUsedTotal = 0,
    this.memLimit = 0,
    this.memUsedMax = 0,
    this.samePages = 0,
    this.pagesCompact = 0,
  });
}

// ---- MAJOR ---
// Bridge for ZRAM (Compressed RAM) Management
class ShellZramService extends BaseShellService {
  ShellZramService(super.session);

  // --- Sub
  // Support & Identification
  Future<bool> isSupported() async {
    final check = await exec(
        "test -b /dev/block/zram0 && echo 'YES' || echo 'NO'",
        silent: true);
    return check.contains("YES");
  }

  Future<int> getZramSize() async {
    logger.d("ZramShell: Reading ZRAM partition size...");
    try {
      // First check if zram device exists
      final deviceCheck = await exec(
          'test -b /dev/block/zram0 && echo YES || echo NO',
          silent: true);
      if (!deviceCheck.contains('YES')) {
        logger.w("ZramShell: ZRAM device not found");
        return 0;
      }

      final output =
          await exec('cat /sys/block/zram0/disksize 2>/dev/null', silent: true);
      logger.d("ZramShell: disksize output: '$output'");

      if (output.isEmpty) {
        logger.w("ZramShell: disksize file is empty");
        // Try to read from persistence file
        final persistedSize = await exec(
            'cat /data/adb/modules/rootify/data/ZRAM-SIZE 2>/dev/null',
            silent: true);
        if (persistedSize.isNotEmpty) {
          final mb = int.tryParse(persistedSize.trim()) ?? 0;
          logger.i("ZramShell: Using persisted size: ${mb}MB");
          return mb;
        }
        return 0;
      }

      final bytes = int.tryParse(output.trim()) ?? 0;
      final mb = bytes ~/ (1024 * 1024);
      logger.d("ZramShell: Parsed size: $mb MB ($bytes bytes)");
      return mb;
    } catch (e, stack) {
      logger.e("ZramShell: Size read error", e, stack, true);
      return 0;
    }
  }

  // Comment: RESTORED - Required for memory mapping and limit calculations
  Future<int> getTotalRam() async {
    logger.d("ZramShell: Reading total system RAM...");
    try {
      final output =
          await exec("cat /proc/meminfo | grep MemTotal", silent: true);
      final parts = output.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return (int.tryParse(parts[1]) ?? 0) ~/ 1024;
      }
      return 0;
    } catch (e, stack) {
      logger.e("ZramShell: Total RAM read error", e, stack, true);
      return 0;
    }
  }

  // --- Sub
  Future<void> applyParameters({
    required int sizeMB,
    required String algo,
  }) async {
    const modPath = "/data/adb/modules/rootify/shell";

    // 1. Use the atomic config script
    final result = await exec("sh $modPath/ZRAM-CONFIG.sh $sizeMB $algo");

    logger.i("ZramShell: Config Result -> $result");

    if (result.contains("ERROR")) {
      logger.e(
          "ZramShell: Atomic application failed: $result", null, null, true);
    }
  }

  // --- Sub
  // Capability Inquiry
  Future<List<String>> getAvailableAlgorithms() async {
    try {
      final output = await exec(
          "cat /sys/block/zram0/comp_algorithm 2>/dev/null",
          silent: true);
      if (output.isEmpty) return [];
      return output
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(' ')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    } catch (e, stack) {
      logger.e("ZramShell: Algorithm fetch error", e, stack, true);
      return [];
    }
  }

  Future<String> getActiveAlgorithm() async {
    try {
      final output = await exec(
          "cat /sys/block/zram0/comp_algorithm 2>/dev/null",
          silent: true);
      final match = RegExp(r'\[(.*?)\]').firstMatch(output);
      return match?.group(1) ?? "unknown";
    } catch (e) {
      return "unknown";
    }
  }

  // --- Sub
  // Telemetry Dashboard
  Future<ZramStats> getMmStats() async {
    try {
      // Comment: Reads multi-metric line from mm_stat node
      final output =
          await exec("cat /sys/block/zram0/mm_stat 2>/dev/null", silent: true);
      if (output.isEmpty) return const ZramStats();

      final parts = output.trim().split(RegExp(r'\s+'));
      if (parts.length < 7) return const ZramStats();

      return ZramStats(
        origDataSize: int.tryParse(parts[0]) ?? 0,
        comprDataSize: int.tryParse(parts[1]) ?? 0,
        memUsedTotal: int.tryParse(parts[2]) ?? 0,
        memLimit: int.tryParse(parts[3]) ?? 0,
        memUsedMax: int.tryParse(parts[4]) ?? 0,
        samePages: int.tryParse(parts[5]) ?? 0,
        pagesCompact: int.tryParse(parts[6]) ?? 0,
      );
    } catch (e) {
      return const ZramStats();
    }
  }

  // Comment: RESTORED - Required for granular size updates
  Future<void> setZramSize(int sizeMB) async {
    final currentAlgo = await getActiveAlgorithm();
    await applyParameters(sizeMB: sizeMB, algo: currentAlgo);
  }

  // Comment: RESTORED - Required for granular algorithm updates
  Future<void> setAlgorithm(String algo) async {
    final currentSize = await getZramSize();
    await applyParameters(sizeMB: currentSize, algo: algo);
  }
}

// ---- MAJOR ---
// Global Providers
final zramShellProvider = Provider((ref) {
  final session = ShellSession(); // Comment: Reuses singleton shell bridge
  return ShellZramService(session);
});

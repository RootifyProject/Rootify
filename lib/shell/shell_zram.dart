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
      final output =
          await exec('cat /sys/block/zram0/disksize 2>/dev/null', silent: true);
      if (output.isEmpty) return 0;
      final bytes = int.tryParse(output.trim()) ?? 0;
      return bytes ~/ (1024 * 1024);
    } catch (e) {
      logger.e("ZramShell: Size read error", e);
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
    } catch (_) {
      return 0;
    }
  }

  // --- Sub
  // Atomic Parameter Management
  Future<void> applyParameters({
    required int sizeMB,
    required String algo,
  }) async {
    if (sizeMB < 0) return;

    final bytes = sizeMB * 1024 * 1024;
    logger.i(
        "ZramShell: Applying ZRAM configuration -> Size: ${sizeMB}MB, Algo: $algo");

    // Comment: Ordering is critical for ZRAM kernel stability
    final cmd = '''
      # 1. Disable current swap usage
      swapoff /dev/block/zram0 2>/dev/null || true
      
      # 2. Reset device for architecture changes
      echo 1 > /sys/block/zram0/reset 2>/dev/null
      
      # 3. Configure compression algorithm (pre-sizing requirement)
      echo "$algo" > /sys/block/zram0/comp_algorithm 2>/dev/null
      
      # 4. Define and Format partition
      if [ $bytes -gt 0 ]; then
        echo $bytes > /sys/block/zram0/disksize 2>/dev/null
        mkswap /dev/block/zram0 2>/dev/null
        swapon /dev/block/zram0 2>/dev/null
      fi
    ''';
    await exec(cmd);
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
    } catch (e) {
      logger.e("ZramShell: Algorithm fetch error", e);
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

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
import '../shell/shellsession.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Hardware Identification Data Model
class VendorDetails {
  final String manufacturer;
  final String model;
  final String codename;
  final String androidVersion;
  final int sdkLevel;
  final String securityPatch;
  final String board;
  final String hardwareChipset;
  final String kernel;
  final String graphics;
  final String arch;

  const VendorDetails({
    required this.manufacturer,
    required this.model,
    required this.codename,
    required this.androidVersion,
    required this.sdkLevel,
    required this.securityPatch,
    required this.board,
    required this.hardwareChipset,
    required this.kernel,
    required this.graphics,
    required this.arch,
  });

  factory VendorDetails.empty() {
    return const VendorDetails(
      manufacturer: 'Unknown',
      model: 'Unknown',
      codename: 'Unknown',
      androidVersion: 'Unknown',
      sdkLevel: 0,
      securityPatch: 'Unknown',
      board: 'Unknown',
      hardwareChipset: 'Unknown',
      kernel: 'Unknown',
      graphics: 'Unknown',
      arch: 'Unknown',
    );
  }
}

// ---- MAJOR ---
// Device & Chipset Identification Service
class VendorInfoService {
  // --- Sub
  // Singleton Pattern
  static final VendorInfoService _instance = VendorInfoService._internal();
  factory VendorInfoService() => _instance;
  VendorInfoService._internal();

  // --- Sub
  // Private Logic Containers
  final _shell = ShellSession();

  // --- Sub
  // Hardware Query Logic
  Future<VendorDetails> getDetails() async {
    try {
      // Comment: Execute multi-command batch to minimize shell bridge latency
      final result = await _shell.exec("getprop ro.product.manufacturer; "
          "getprop ro.product.model; "
          "getprop ro.product.device; "
          "getprop ro.build.version.release; "
          "getprop ro.build.version.sdk; "
          "getprop ro.build.version.security_patch; "
          "uname -r; "
          "getprop ro.board.platform; "
          "grep -m1 'Hardware' /proc/cpuinfo | cut -d: -f2; "
          "dumpsys SurfaceFlinger | grep GLES: | head -n1 | cut -d: -f2; "
          "uname -m");

      final lines = result.split('\n').map((e) => e.trim()).toList();

      final manufacturer = _val(lines, 0);
      final model = _val(lines, 1);
      final codename = _val(lines, 2);
      final androidVer = _val(lines, 3);
      final api = int.tryParse(_val(lines, 4)) ?? 0;
      final patch = _val(lines, 5);
      final kernel = _val(lines, 6);
      final vendorChip = _val(lines, 7);
      final hwChip = _val(lines, 8);
      final graphics = _val(lines, 9);
      final arch = _val(lines, 10);

      final details = VendorDetails(
        manufacturer: manufacturer,
        model: model,
        codename: codename,
        androidVersion: androidVer,
        sdkLevel: api,
        securityPatch: patch,
        board: vendorChip.toUpperCase(),
        hardwareChipset: hwChip.isEmpty ? vendorChip.toUpperCase() : hwChip,
        kernel: kernel,
        graphics: graphics,
        arch: arch,
      );

      logger.d("VendorInfo: Identification successful for ${details.model}");
      return details;
    } catch (e, st) {
      logger.e("VendorInfo: Identification failed", e, st);
      return VendorDetails.empty();
    }
  }

  // --- Sub
  // String Utilities
  String _val(List<String> lines, int index) {
    if (index >= lines.length) return 'Unknown';
    final v = lines[index];
    return v.isEmpty ? 'Unknown' : v;
  }
}

// ---- MAJOR ---
// Global Instances & Providers
final vendorInfoService = VendorInfoService();

final vendorInfoProvider = FutureProvider<VendorDetails>((ref) async {
  return await vendorInfoService.getDetails();
});

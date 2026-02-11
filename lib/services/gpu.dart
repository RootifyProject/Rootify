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
import 'dart:async';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../services/shell_services.dart';

// ---- MAJOR ---
// GPU Metadata Container
// --- Sub
// Hardware Identification
class GpuDetails {
  final String vendor;
  final String renderer;

  const GpuDetails({
    required this.vendor,
    required this.renderer,
  });

  factory GpuDetails.empty() {
    return const GpuDetails(
      vendor: 'Unknown',
      renderer: 'Unknown',
    );
  }
}

// ---- MAJOR ---
// Hardware Discovery Service
class GpuInfoService {
  // --- Sub
  // Singleton Pattern
  static final GpuInfoService _instance = GpuInfoService._internal();
  factory GpuInfoService() => _instance;
  GpuInfoService._internal();

  // --- Sub
  // Private Logic Containers
  ShellService? _shell;

  // --- Sub
  // Lifecycle Handlers
  void init(ShellService shell) {
    _shell = shell;
  }

  // --- Sub
  // Hardware Query Logic
  Future<GpuDetails> getGpuDetails() async {
    if (_shell == null) return GpuDetails.empty();
    try {
      // Comment: "dumpsys SurfaceFlinger" provides GLES renderer/vendor info.
      final result = await _shell!.exec("dumpsys SurfaceFlinger | grep GLES:");

      if (result.isEmpty || !result.contains('GLES:')) {
        return GpuDetails.empty();
      }

      final cleanResult = result.replaceAll('GLES:', '').trim();
      final parts = cleanResult.split(',').map((e) => e.trim()).toList();

      final vendor = parts.isNotEmpty ? parts[0] : 'Unknown';
      final renderer = parts.length > 1 ? parts[1] : 'Unknown';

      return GpuDetails(
        vendor: vendor,
        renderer: renderer,
      );
    } catch (e) {
      return GpuDetails.empty();
    }
  }
}

// ---- MAJOR ---
// Global Instances & Providers
final gpuInfoService = GpuInfoService();

final gpuInfoProvider = FutureProvider<GpuDetails>((ref) async {
  final service = gpuInfoService;
  service.init(ref.read(shellServiceProvider));
  return await service.getGpuDetails();
});

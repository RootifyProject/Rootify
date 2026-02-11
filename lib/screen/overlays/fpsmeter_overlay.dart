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
import 'package:flutter/material.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// ---- LOCAL ---
import '../../services/system_monitor.dart';

// ---- MAJOR ---
// Main Overlay Component
class FpsMeterOverlay extends ConsumerStatefulWidget {
  const FpsMeterOverlay({super.key});

  @override
  ConsumerState<FpsMeterOverlay> createState() => _FpsMeterOverlayState();
}

class _FpsMeterOverlayState extends ConsumerState<FpsMeterOverlay> {
  // --- Fields
  bool _isLocked = false;

  // --- Lifecycle
  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && data.containsKey('locked')) {
        final locked = data['locked'] == true;
        setState(() {
          _isLocked = locked;
        });

        // Jump logic
        if (locked) {
          FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 0));
        } else {
          FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 400));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Hapus FittedBox & Center.
    // Struktur: Directionality -> GestureDetector -> Container (Pill).
    // Ini bikin widgetnya cuma segede isinya (shrink wrap).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Cuma nangkep touch di visual widget
        onPanUpdate: (details) {
          if (!_isLocked) {
            FlutterOverlayWindow.moveOverlay(
              OverlayPosition(
                details.globalPosition.dx,
                details.globalPosition.dy,
              ),
            );
          }
        },
        // Widget Pill langsung di sini, tanpa wrapper layout yang aneh-aneh
        child: _FpsPill(isLocked: _isLocked),
      ),
    );
  }
}

// ---- UI COMPONENT ---
class _FpsPill extends ConsumerWidget {
  final bool isLocked;
  const _FpsPill({this.isLocked = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(systemMonitorProvider).asData?.value;
    final double fps = stats?.fps ?? 0.0;

    Color statusColor = const Color(0xFF00E676);
    if (fps < 30) {
      statusColor = const Color(0xFFFF1744);
    } else if (fps < 50) {
      statusColor = const Color(0xFFFF9100);
    }

    // Gunakan Material disini HANYA untuk styling, bukan layouting
    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(
                0xCC000000), // Sedikit lebih gelap biar solid (0xCC)
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: [
              // Opsional: Shadow tipis biar makin keliatan "melayang" pisah dari background
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min, // PENTING: Biar gak melar
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "FPS",
              style: TextStyle(
                fontSize: 10, // Sedikit digedein biar enak baca
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              fps.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontFamily: 'Monospace',
                color: statusColor,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

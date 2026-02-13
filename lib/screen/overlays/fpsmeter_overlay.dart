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
// Primary Overlay Component for Real-time FPS Monitoring
// --- FpsMeterOverlay
class FpsMeterOverlay extends ConsumerStatefulWidget {
  const FpsMeterOverlay({super.key});

  @override
  ConsumerState<FpsMeterOverlay> createState() => _FpsMeterOverlayState();
}

class _FpsMeterOverlayState extends ConsumerState<FpsMeterOverlay> {
  // --- Sub
  // Overlay Lock State
  bool _isLocked = false;

  // --- Sub
  // Lifecycle Management
  @override
  void initState() {
    super.initState();
    // Detail: Listen for lock status updates from the main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && data.containsKey('locked')) {
        final locked = data['locked'] == true;
        setState(() {
          _isLocked = locked;
        });

        // Detail: Handle overlay jump based on lock state
        if (locked) {
          FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 0));
        } else {
          FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 400));
        }
      }
    });
  }

  // --- Sub
  // UI Builder
  @override
  Widget build(BuildContext context) {
    // Detail: Maintain LTR directionality for overlay content
    // Detail: Implement pan gestures for manual positioning
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
        // Detail: Render the visual FPS pill
        child: _FpsPill(isLocked: _isLocked),
      ),
    );
  }
}

// ---- MAJOR ---
// Stylized Pill Widget for FPS Display
// --- FpsPill
class _FpsPill extends ConsumerWidget {
  final bool isLocked;
  const _FpsPill({this.isLocked = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(systemMonitorProvider).asData?.value;
    final double fps = stats?.fps ?? 0.0;

    // --- Sub
    // Color thresholds for performance feedback
    Color statusColor = const Color(0xFF00E676);
    if (fps < 30) {
      statusColor = const Color(0xFFFF1744);
    } else if (fps < 50) {
      statusColor = const Color(0xFFFF9100);
    }

    // --- Sub
    // Visual Assembly
    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0xCC000000),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: [
              // Detail: Subtle shadow for depth separation
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "FPS",
              style: TextStyle(
                fontSize: 10,
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

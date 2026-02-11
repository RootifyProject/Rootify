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
 * distributed under the License is distributed on an "(\"AS IS\"); BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ---- SYSTEM ---
import 'package:flutter/material.dart';

// ---- EXTERNAL ---
import 'package:lucide_icons/lucide_icons.dart';

// ---- MAJOR ---
// Fallback Interface for Non-MTK Devices
class FpsGoNotSupportedView extends StatelessWidget {
  final VoidCallback onExit;

  const FpsGoNotSupportedView({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    // --- Component Assembly
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Sub
            // Warning Icon Context
            const Icon(LucideIcons.alertTriangle,
                size: 48, color: Colors.orange),
            const SizedBox(height: 16),

            // --- Sub
            // Primary Feedback Labels
            const Text("Unsupported Hardware",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "FPSGO is specific to MediaTek SoCs and requires perfmgr drivers.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // --- Sub
            // Navigation Fallback Action
            OutlinedButton.icon(
              onPressed: onExit,
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text("Go Back"),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

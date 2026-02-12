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
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import 'about_widgets.dart';

// ---- MAJOR ---
// Developer Section for About App
// --- DeveloperSection
class DeveloperSection extends StatelessWidget {
  final Function(String) onTelegramTap;

  const DeveloperSection({
    super.key,
    required this.onTelegramTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Sub
        // Header
        const AboutSectionHeader(title: "Developer"),
        // --- Sub
        // Developer Card
        AboutContactCard(
          icon: LucideIcons.github,
          title: "Aby - FoxLabs",
          subtitle: "Lead Developer & UX Designer",
          userId: "7146954165",
          isClickable: true,
          onTap: () => onTelegramTap("7146954165"),
        ),
      ],
    );
  }
}

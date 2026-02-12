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
// Special Thanks Section for About App
// --- SpecialThanksSection
class SpecialThanksSection extends StatelessWidget {
  final List<CreditItem> items;
  final Function(String) onTelegramTap;

  const SpecialThanksSection({
    super.key,
    required this.items,
    required this.onTelegramTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Validation
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Sub
        // Header
        const AboutSectionHeader(title: "Special Thanks"),
        // --- Sub
        // Items List
        ...items.map((credit) => AboutContactCard(
              icon: LucideIcons.heart,
              title: credit.name,
              userId: credit.tgid == "none" ? null : credit.tgid,
              subtitle: credit.description,
              role: credit.descriptionType,
              isClickable: credit.tgid != "none",
              onTap: credit.tgid == "none"
                  ? null
                  : () => onTelegramTap(credit.tgid),
            )),
      ],
    );
  }
}

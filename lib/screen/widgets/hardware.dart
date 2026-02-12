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
import '../../services/vendor.dart';
import '../../widgets/cards.dart';
import 'info_widgets.dart';

// ---- MAJOR ---
// Hardware Information Section
// --- HardwareSection
class HardwareSection extends StatelessWidget {
  final VendorDetails info;

  const HardwareSection({
    super.key,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return RootifyCard(
      title: "Hardware",
      icon: LucideIcons.cog,
      child: Column(
        children: [
          InfoDetailTile(
            icon: LucideIcons.tag,
            label: "Model",
            value: info.model,
          ),
          InfoDetailTile(
            icon: LucideIcons.factory,
            label: "Manufacturer",
            value: info.manufacturer,
          ),
          InfoDetailTile(
            icon: LucideIcons.box,
            label: "Codename",
            value: info.codename,
          ),
          InfoDetailTile(
            icon: LucideIcons.cpu,
            label: "Platform",
            value: info.board,
          ),
        ],
      ),
    );
  }
}

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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ---- LOCAL ---
import '../../services/vendor.dart';
import '../../widgets/cards.dart';
import 'info_widgets.dart';

// ---- MAJOR ---
// Kernel Information Section
// --- KernelSection
class KernelSection extends StatelessWidget {
  final VendorDetails info;

  const KernelSection({
    super.key,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return RootifyCard(
      title: "Kernel",
      icon: LucideIcons.terminal,
      child: Column(
        children: [
          InfoDetailTile(
            icon: FontAwesomeIcons.linux,
            label: "Kernel Version",
            value: info.kernel.split('#').first.trim(),
          ),
          InfoDetailTile(
            icon: LucideIcons.cpu,
            label: "Architecture",
            value: info.arch,
          ),
        ],
      ),
    );
  }
}

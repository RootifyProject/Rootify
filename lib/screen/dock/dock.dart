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
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../animations/dock_animation.dart';
import '../../effects/rootify_blur.dart';
import '../../theme/theme_provider.dart';

// ---- MAJOR ---
// Dock Constants
const double _kDockBorderRadius = 30.0;
const double _kItemBorderRadius = 16.0;
const double _kPillBorderRadius = 18.0;
const double _kGap = 6.0;
const double _kIconSize = 22.0;
const double _kItemPaddingV = 14.0;
const double _kPillHeight = 56.0;

// ---- MAJOR ---
// Rootify Dock Component
class RootifyDock extends ConsumerStatefulWidget {
  // --- Fields
  final VoidCallback onTweaksTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onUtilsTap;
  final VoidCallback onAddonsTap;
  final VoidCallback onDeviceInfoTap;
  final VoidCallback? onHomeTap;
  final int selectedIndex;
  final bool isTapped;

  const RootifyDock({
    required this.onTweaksTap,
    required this.onSettingsTap,
    required this.onUtilsTap,
    required this.onAddonsTap,
    required this.onDeviceInfoTap,
    required this.selectedIndex,
    this.isTapped = false,
    this.onHomeTap,
    super.key,
  });

  @override
  ConsumerState<RootifyDock> createState() => _RootifyDockState();
}

// ---- MAJOR ---
// Dock State Management
class _RootifyDockState extends ConsumerState<RootifyDock>
    with SingleTickerProviderStateMixin {
  // --- Properties
  late final AnimationController _floatController;
  late final List<({IconData icon, VoidCallback cb})> _dockItems;

  // --- Lifecycle
  @override
  void initState() {
    super.initState();

    // Initializers
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _dockItems = [
      (icon: LucideIcons.home, cb: widget.onHomeTap ?? () {}),
      (icon: LucideIcons.zap, cb: widget.onTweaksTap),
      (icon: LucideIcons.packagePlus, cb: widget.onAddonsTap),
      (icon: LucideIcons.wrench, cb: widget.onUtilsTap),
      (icon: LucideIcons.smartphone, cb: widget.onDeviceInfoTap),
      (icon: LucideIcons.settings, cb: widget.onSettingsTap),
    ];
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  // ---- MAJOR ---
  // UI Builder
  @override
  Widget build(BuildContext context) {
    // Theme & Context Config
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Responsive Layout
    final screenWidth = MediaQuery.of(context).size.width;
    final accentColor = theme.colorScheme.primary;

    // Dynamic Sizing
    // Adjust padding based on screen width for tablet/phone flexibility
    final responsivePaddingH = screenWidth * 0.045;
    final double itemSlotWidth = _kIconSize + (responsivePaddingH * 2);

    final dockBackgroundColor = isDarkMode
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerLow;

    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.4);

    // Component Tree
    return DockAnimation(
      controller: _floatController,
      child: RootifyBlur(
        category: BlurCategory.dock,
        color: dockBackgroundColor,
        borderRadius: BorderRadius.circular(_kDockBorderRadius),
        border: Border.all(color: borderColor, width: 3.0),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: ConstrainedBox(
          // Limit dock width on larger screens (Tablets/Landscape)
          constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_kDockBorderRadius - 3.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Layer 1: Nav Icons
                  RepaintBoundary(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _dockItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;

                        return Padding(
                          padding: EdgeInsets.only(
                            right: idx != _dockItems.length - 1 ? _kGap : 0,
                          ),
                          child: _buildItemButton(
                            idx,
                            item.icon,
                            item.cb,
                            accentColor,
                            responsivePaddingH,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Layer 2: Dynamic Selection Pill
                  _buildPill(itemSlotWidth, accentColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- MAJOR ---
  // Sub-View Builders

  // --- Sub
  // Builds an individual navigation item
  Widget _buildItemButton(int index, IconData icon, VoidCallback onTap,
      Color accentColor, double paddingH) {
    final theme = Theme.of(context);
    final isSelected = widget.selectedIndex == index;
    final inactiveColor =
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: paddingH,
          vertical: _kItemPaddingV,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_kItemBorderRadius),
        ),
        child: Icon(
          icon,
          color: isSelected ? accentColor : inactiveColor,
          size: _kIconSize,
        ),
      ),
    );
  }

  // --- Sub
  // Builds the animated background indicator
  Widget _buildPill(double itemSlotWidth, Color accentColor) {
    final double pillOffset = widget.selectedIndex * (itemSlotWidth + _kGap);

    return AnimatedDockPill(
      isTapped: widget.isTapped,
      offset: pillOffset,
      child: RepaintBoundary(
        child: Container(
          width: itemSlotWidth,
          height: _kPillHeight,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(_kPillBorderRadius),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: -2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

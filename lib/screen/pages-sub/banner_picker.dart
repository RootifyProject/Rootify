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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

// ---- LOCAL ---
import '../../theme/theme_provider.dart';
import '../statusbar/sb_bannerpicker.dart';
import '../../widgets/toast.dart';
import '../../widgets/cards.dart';

// ---- MAJOR ---
// Customizable Visual Identity & Hero Banner Image Selection
class BannerPickerPage extends ConsumerStatefulWidget {
  const BannerPickerPage({super.key});

  @override
  ConsumerState<BannerPickerPage> createState() => _BannerPickerPageState();
}

class _BannerPickerPageState extends ConsumerState<BannerPickerPage> {
  // ---- STATE VARIABLES ---
  List<File> _customBanners = [];
  bool _isLoadingCustom = true;

  final List<String> _builtInBanners = [
    'assets/banner/banner-1.jpg',
    'assets/banner/banner-2.jpg',
    'assets/banner/banner-3.jpg',
    'assets/banner/banner-4.jpg',
    'assets/banner/banner-5.jpg',
    'assets/banner/banner-6.jpg',
    'assets/banner/banner-7.jpg',
    'assets/banner/banner-8.jpg',
  ];

  // ---- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    _loadCustomBanners();
  }

  // ---- DATA ENGINE ---

  Future<void> _loadCustomBanners() async {
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir == null) return;

      // Ensure /banner/ subdirectory exists
      final bannerDir = Directory('${extDir.parent.path}/banner');
      if (!await bannerDir.exists()) {
        await bannerDir.create(recursive: true);
      }

      final files = await bannerDir.list().toList();
      setState(() {
        _customBanners = files
            .whereType<File>()
            .where((f) =>
                f.path.endsWith('.jpg') ||
                f.path.endsWith('.jpeg') ||
                f.path.endsWith('.png'))
            .toList();
        _isLoadingCustom = false;
      });
    } catch (e) {
      debugPrint('Error loading custom banners: $e');
      setState(() => _isLoadingCustom = false);
    }
  }

  // ---- EVENT HANDLERS ---

  Future<void> _pickNewBanner() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final extDir = await getExternalStorageDirectory();
      if (extDir == null) return;

      final bannerDir = Directory('${extDir.parent.path}/banner');
      if (!await bannerDir.exists()) {
        await bannerDir.create(recursive: true);
      }

      // Copy to our banner directory
      final fileName = p.basename(image.path);
      final newFile = File('${bannerDir.path}/$fileName');
      await File(image.path).copy(newFile.path);

      await _loadCustomBanners();
      if (!mounted) return;
      RootifyToast.show(context, 'Image added to custom banners');
    } catch (e) {
      if (!mounted) return;
      RootifyToast.show(context, 'Failed to pick image: $e', isError: true);
    }
  }

  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Context
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top;
    final screenWidth = mq.size.width;

    // --- Sub
    // Calculate centered alignment for tablets
    final bool isWide = screenWidth > 900;
    final double horizontalPadding = isWide ? (screenWidth - 850) / 2 : 16.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // --- Sub
            // 1. Mirrored Dynamic Mesh Background
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainerHigh,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Primary Glow
                    Positioned(
                      top: -120,
                      left: -120,
                      child: Container(
                        width: 450,
                        height: 450,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.15),
                              colorScheme.primary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(30, -30),
                          end: const Offset(-30, 30),
                          duration: 12.seconds),
                    ),
                    // Secondary Glow
                    Positioned(
                      bottom: -80,
                      right: -80,
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.secondary.withValues(alpha: 0.1),
                              colorScheme.secondary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(-30, 30),
                          end: const Offset(30, -30),
                          duration: 10.seconds),
                    ),
                  ],
                ),
              ),
            ),

            // --- Sub
            // 2. Main Scrolling Content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Space
                SliverToBoxAdapter(child: SizedBox(height: topPadding + 85)),

                // Dimensional Scaling Container
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Technical Guidance Card
                      _buildInfoCard(theme),
                      const SizedBox(height: 16),

                      // System Dynamic Mode
                      _buildBannerCard(
                        context,
                        title: 'Default Dynamic',
                        subtitle: 'Use system theme colors & blurs',
                        isSelected:
                            themeState.heroBannerType == HeroBannerType.dynamic,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setHeroBanner(HeroBannerType.dynamic, null);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.4),
                                colorScheme.secondary.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Built-in Asset Library
                      Row(
                        children: [
                          Icon(LucideIcons.image,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('BUILT-IN BANNERS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: colorScheme.primary,
                              )),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),

                // Responsive Grid for Assets
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final path = _builtInBanners[index];
                        return _buildBannerCard(
                          context,
                          isSelected: themeState.heroBannerType ==
                                  HeroBannerType.asset &&
                              themeState.heroBannerPath == path,
                          onTap: () {
                            ref
                                .read(themeProvider.notifier)
                                .setHeroBanner(HeroBannerType.asset, path);
                            RootifyToast.show(
                                context, 'Built-in banner applied');
                          },
                          child: Image.asset(path, fit: BoxFit.cover),
                        );
                      },
                      childCount: _builtInBanners.length,
                    ),
                  ),
                ),

                // User-defined Custom Assets
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: 32,
                      bottom: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.folderOpen,
                                size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('CUSTOM BANNERS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: colorScheme.primary,
                                )),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _pickNewBanner,
                              icon: const Icon(LucideIcons.plus, size: 20),
                              tooltip: 'Pick from Gallery',
                            ),
                            IconButton(
                              onPressed: _loadCustomBanners,
                              icon: const Icon(LucideIcons.rotateCw, size: 16),
                              tooltip: 'Refresh Folder',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isLoadingCustom)
                  const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    )),
                  )
                else if (_customBanners.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(LucideIcons.fileQuestion,
                              size: 48,
                              color: theme.hintColor.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No images found in:\nAndroid/data/com.aby.rootify/banner/',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final file = _customBanners[index];
                          return _buildBannerCard(
                            context,
                            isSelected: themeState.heroBannerType ==
                                    HeroBannerType.custom &&
                                themeState.heroBannerPath == file.path,
                            onTap: () {
                              ref.read(themeProvider.notifier).setHeroBanner(
                                  HeroBannerType.custom, file.path);
                              RootifyToast.show(
                                  context, 'Custom banner applied');
                            },
                            child: Image.file(file, fit: BoxFit.cover),
                          );
                        },
                        childCount: _customBanners.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // --- Sub
            // 3. Floating Status Bar
            Positioned(
              top: topPadding + 10,
              left: 0,
              right: 0,
              child: const BannerPickerStatusBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ---- HELPER BUILDERS ---

  Widget _buildInfoCard(ThemeData theme) {
    return RootifyCard(
      title: "IMPORTANT NOTICE",
      subtitle: "Best with 2:1 Aspect Ratio",
      icon: LucideIcons.alertTriangle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Min: 1080x500px | Max: 2160x1000px",
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(
    BuildContext context, {
    required Widget child,
    required bool isSelected,
    required VoidCallback onTap,
    String? title,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(28);

    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        height: title != null ? 120 : null,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Positioned.fill(child: child),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.check,
                        size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (title == null) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        if (subtitle != null)
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: theme.hintColor)),
        const SizedBox(height: 12),
        card,
      ],
    );
  }
}

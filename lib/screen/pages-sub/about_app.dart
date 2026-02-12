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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ---- LOCAL ---
import '../../theme/theme_provider.dart';
import '../../utils/app_logger.dart';
import '../statusbar/sb_aboutapp.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';
import 'legal_details.dart';

// ---- MAJOR ---
// Rootify Software Information Page
class AppInfoPage extends ConsumerStatefulWidget {
  const AppInfoPage({super.key});

  @override
  ConsumerState<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends ConsumerState<AppInfoPage> {
  // ---- STATE VARIABLES ---

  late Future<PackageInfo> _packageInfo;
  List<_CreditItem> _credits = [];
  bool _showBanner = false;
  int _logoClickCount = 0;

  // ---- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    _loadCredits();
  }

  // ---- EVENT HANDLERS ---

  void _handleLogoTap() {
    final state = ref.read(themeProvider);
    if (state.isAdvancedBlurUnlocked) return;

    setState(() => _logoClickCount++);
    if (_logoClickCount == 10) {
      ref.read(themeProvider.notifier).unlockAdvancedBlur();
      RootifyToast.show(context, "Advanced Blur Unlocked!");
    }
  }

  void _toggleView() => setState(() => _showBanner = !_showBanner);

  // ... (existing _loadCredits, _launchUrl, _launchTelegramUser)

  Future<void> _loadCredits() async {
    try {
      final String response =
          await rootBundle.loadString('assets/credits.json');
      final List<dynamic> data = json.decode(response);
      if (mounted) {
        setState(() {
          _credits = data.map((item) => _CreditItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      logger.e('Error loading credits: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchTelegramUser(String userId) async {
    final Uri uri = Uri.parse('tg://user?id=$userId');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      logger.e('Error launching Telegram: $e');
    }
  }

  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

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
            // Background Layer
            Positioned.fill(
              child: Container(
                color: colorScheme.surface,
              ),
            ),

            // --- Sub
            // Main Scrolling Content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // About: Premium Header Space
                SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),

                // About: Branding & Version Metadata
                SliverToBoxAdapter(
                  child: FutureBuilder<PackageInfo>(
                    future: _packageInfo,
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? "0.0.0";
                      final build = snapshot.data?.buildNumber ?? "0";

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _showBanner
                            ? GestureDetector(
                                onTap: _toggleView,
                                child: Container(
                                  key: const ValueKey('banner'),
                                  height: 200,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                          'assets/banner/about-banner.png'),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                key: const ValueKey('branding'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _handleLogoTap,
                                    onLongPress: _toggleView,
                                    child: SvgPicture.asset(
                                      'assets/svg/logo.svg',
                                      width: 85,
                                      height: 85,
                                      colorFilter: ColorFilter.mode(
                                          colorScheme.primary, BlendMode.srcIn),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "ROOTIFY",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Version $version ($build)",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: _toggleView,
                                        icon: const Icon(LucideIcons.image,
                                            size: 16),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: Text(
                                      "an Root All In One application for Tweaking, Tuning Performance, AI Management on Your Device, Monitor System Resources, and More",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // About: Developer Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, "Developer"),
                        _buildClickableContactRow(
                          context,
                          icon: LucideIcons.user,
                          username: '@Dizzy',
                          userId: '7146954165',
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                if (_credits.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, "Credits"),
                          ..._credits.map((credit) => _buildClickableContactRow(
                                context,
                                icon: LucideIcons.sparkles,
                                username: '@${credit.name}',
                                userId: credit.tgid,
                                subtitle: credit.description,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // About: Special Thanks
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, "Special Thanks"),
                        _buildClickableContactRow(
                          context,
                          icon: LucideIcons.heart,
                          username: 'TRAVEL - Transsion Developments',
                          userId: null,
                          subtitle:
                              "The birthplace of ideas and a hub for brilliant developers who guided me through complex challenges. A heartfelt thank you to all members for their unwavering support.",
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // About: Ecosystem & Support Links
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, "Ecosystem"),
                        _InfoLinkTile(
                          icon: LucideIcons.github,
                          title: "GitHub Repository",
                          subtitle: "Source code and development",
                          onTap: () => _launchUrl(
                              "https://github.com/RootifyProject/rootify"),
                        ),
                        _InfoLinkTile(
                          icon: LucideIcons.send,
                          title: "Telegram Support Group",
                          subtitle: "Latest news and updates",
                          onTap: () => _launchUrl("https://t.me/AbyRootify"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // About: Legal & Attribution Information
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, "Legal"),
                        _InfoLinkTile(
                          icon: LucideIcons.gavel,
                          title: "Rootify EULA",
                          subtitle: "End-User License Agreement",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LegalDetailsPage(
                                title: "Rootify License",
                                assetPath: "assets/license/LICENSE-Rootify",
                                icon: LucideIcons.gavel,
                              ),
                            ),
                          ),
                        ),
                        _InfoLinkTile(
                          icon: LucideIcons.scale,
                          title: "Laya Kernel Tuner",
                          subtitle: "Licensed under GPL-3.0",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LegalDetailsPage(
                                title: "Laya Kernel Tuner License",
                                assetPath:
                                    "assets/license/LICENSE-LayaKernelTuner",
                                icon: LucideIcons.scale,
                              ),
                            ),
                          ),
                        ),
                        _InfoLinkTile(
                          icon: LucideIcons.feather,
                          title: "Laya Battery Monitor",
                          subtitle: "Licensed under MIT",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LegalDetailsPage(
                                title: "Laya Battery Monitor License",
                                assetPath:
                                    "assets/license/LICENSE-LayaBatteryMonitor",
                                icon: LucideIcons.feather,
                              ),
                            ),
                          ),
                        ),
                        _InfoLinkTile(
                          icon: LucideIcons.package,
                          title: "OSS Licenses",
                          subtitle: "Open source attribution",
                          onTap: () => showLicensePage(context: context),
                        ),
                        _InfoLinkTile(
                          icon: LucideIcons.shield,
                          title: "Privacy Policy",
                          subtitle: "How we handle your data",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LegalDetailsPage(
                                title: "Privacy Policy",
                                assetPath:
                                    "assets/license/PRIVACY-POLICY-Rootify",
                                icon: LucideIcons.shield,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),

            // --- Sub
            // Floating Status Bar
            Positioned(
              top: topPadding + 10,
              left: 0,
              right: 0,
              child: const AboutAppStatusBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ---- HELPER BUILDERS ---

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildClickableContactRow(
    BuildContext context, {
    required IconData icon,
    required String username,
    String? userId,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final isClickable = userId != null && userId.isNotEmpty;

    return RootifyCard(
      onTap: isClickable ? () => _launchTelegramUser(userId) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (isClickable)
            Icon(
              LucideIcons.externalLink,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }
}

// ---- SUPPORTING ---

class _CreditItem {
  final String name;
  final String tgid;
  final String description;

  _CreditItem({
    required this.name,
    required this.tgid,
    required this.description,
  });

  factory _CreditItem.fromJson(Map<String, dynamic> json) {
    return _CreditItem(
      name: json['name'] as String,
      tgid: json['tgid'] as String,
      description: json['description'] as String,
    );
  }
}

// Clean Link Tile for External Resource Navigation
class _InfoLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InfoLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RootifyCard(
      onTap: onTap,
      child: Row(
        children: [
          // Detail: Destination Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          // Detail: Destination Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.externalLink,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

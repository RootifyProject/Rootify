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
import '../../widgets/toast.dart';
import '../pages-sub/details.dart';

// Modular Sections
import '../widgets/about_widgets.dart';
import '../widgets/developer.dart';
import '../widgets/special_thanks.dart';
import '../widgets/credits.dart';
import '../widgets/ecosystem.dart';
import '../widgets/legal.dart';

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
  List<CreditItem> _credits = [];
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
          _credits = data.map((item) => CreditItem.fromJson(item)).toList();
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

    // --- Logic
    // Group credits by type
    final specialThanksItems = _credits
        .where((c) => c.type.toLowerCase() == "special thanks")
        .toList();
    final generalCreditsItems =
        _credits.where((c) => c.type.toLowerCase() == "credits").toList();

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

                // About: Developer Profile
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DeveloperSection(
                      onTelegramTap: _launchTelegramUser,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // About: Special Thanks (Dynamic)
                if (specialThanksItems.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SpecialThanksSection(
                        items: specialThanksItems,
                        onTelegramTap: _launchTelegramUser,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],

                // About: Credits (Dynamic)
                if (generalCreditsItems.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CreditsSection(
                        items: generalCreditsItems,
                        onTelegramTap: _launchTelegramUser,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],

                // About: Ecosystem & Support Links
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EcosystemSection(
                      onSourceCodeTap: () => _launchUrl(
                          'https://github.com/RootifyProject/rootify'),
                      onSupportTap: () => _launchUrl('https://t.me/AbyRootify'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // About: Legal & Attribution Links
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LegalSection(
                      onEulaTap: () => _navigateToDetails(
                        context,
                        "Rootify EULA",
                        'assets/license/LICENSE-Rootify',
                        LucideIcons.gavel,
                      ),
                      onLicenseTap: () => _navigateToDetails(
                        context,
                        "Laya Kernel Tuner License",
                        'assets/license/LICENSE-LayaKernelTuner',
                        LucideIcons.scale,
                      ),
                      onPrivacyPolicyTap: () => _navigateToDetails(
                        context,
                        "Privacy Policy",
                        'assets/license/PRIVACY-POLICY-Rootify',
                        LucideIcons.shield,
                      ),
                      onOssLicensesTap: () => showLicensePage(context: context),
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

  // --- Navigation Helpers

  void _navigateToDetails(
      BuildContext context, String title, String assetPath, IconData icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPage(
          title: title,
          assetPath: assetPath,
          icon: icon,
        ),
      ),
    );
  }
}

// ---- SUPPORTING ---

// Clean Link Tile for External Resource Navigation

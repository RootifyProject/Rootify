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

// ---- LOCAL ---
import '../../theme/rootify_background_provider.dart';
import '../../widgets/cards.dart';
import '../statusbar/statusbar.dart';

// ---- MAJOR ---
// Generic Detail Page for displaying text content from assets
class DetailsPage extends StatefulWidget {
  final String title;
  final String assetPath;
  final IconData icon;

  const DetailsPage({
    super.key,
    required this.title,
    required this.assetPath,
    required this.icon,
  });

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  String _content = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final data = await rootBundle.loadString(widget.assetPath);
      if (mounted) {
        setState(() {
          _content = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _content = 'Error loading content: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        body: RootifySubBackground(
          child: Stack(
            children: [
              // Main Content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),

                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: RootifyCard(
                        padding: const EdgeInsets.all(2),
                        child: _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : SelectableText(
                                _content,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: theme.colorScheme.onSurface,
                                  fontFamily: 'Monospace',
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // Status Bar
              Positioned(
                top: topPadding + 10,
                left: 0,
                right: 0,
                child: SystemStatusBar(
                  title: widget.title.toUpperCase(),
                  showBackButton: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';

/// Onboarding screen — shown only on first app launch.
class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingView({super.key, required this.onComplete});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Page view
          PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            children: [
              _buildSlide1(isDark),
              _buildSlide2(isDark),
              _buildSlide3(isDark),
            ],
          ),

          // Bottom bar with indicators & buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Container(
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        // Skip button
                        if (_currentPage < 2)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _completeOnboarding,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(
                                  color: AppTheme.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Lewati'),
                            ),
                          ),

                        if (_currentPage < 2) const SizedBox(width: 12),

                        // Next / Selesai button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < 2) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _completeOnboarding();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _currentPage < 2 ? 'Lanjut' : 'Selesai',
                                key: ValueKey(_currentPage < 2 ? 'lanjut' : 'selesai'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Slide 1: Welcome ────────────────────────────────

  Widget _buildSlide1(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withAlpha(isDark ? 30 : 15),
            AppTheme.primaryColor.withAlpha(isDark ? 15 : 5),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withAlpha(isDark ? 40 : 25),
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withAlpha(isDark ? 60 : 35),
                    ),
                  ),
                  // Icon
                  Icon(
                    Icons.store_rounded,
                    size: 100,
                    color: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Kelola Bisnis Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LabaKu membantu Anda mengelola toko dengan mudah, dari stok barang hingga analisis keuntungan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Slide 2: Features ───────────────────────────────

  Widget _buildSlide2(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor.withAlpha(isDark ? 30 : 15),
            AppTheme.accentColor.withAlpha(isDark ? 15 : 5),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative shapes
                  Positioned(
                    top: 20,
                    left: 30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppTheme.accentColor.withAlpha(isDark ? 50 : 30),
                      ),
                      child: Icon(Icons.shopping_bag_rounded,
                          color: isDark
                              ? AppTheme.accentColor.withAlpha(128)
                              : AppTheme.accentColor),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppTheme.primaryColor.withAlpha(isDark ? 50 : 30),
                      ),
                      child: Icon(Icons.bar_chart_rounded,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor),
                    ),
                  ),
                  // Center icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.infoColor.withAlpha(isDark ? 60 : 40),
                    ),
                    child: Icon(
                      Icons.dashboard_rounded,
                      size: 60,
                      color: isDark
                          ? Colors.lightBlue.shade200
                          : AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Fitur Lengkap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kelola produk, catat penjualan, tracking pengeluaran, dan analisis keuntungan bisnis secara real-time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Slide 3: Cloud Backup ──────────────────────────

  Widget _buildSlide3(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withAlpha(isDark ? 30 : 15),
            Colors.orange.withAlpha(isDark ? 15 : 5),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cloud background
                  Container(
                    width: 180,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      color: Colors.orange.withAlpha(isDark ? 50 : 30),
                    ),
                  ),
                  // Data icon
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          color: Colors.blue.withAlpha(isDark ? 60 : 40),
                        ),
                        child: Icon(
                          Icons.cloud_rounded,
                          size: 40,
                          color: isDark
                              ? Colors.blue.shade200
                              : Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 24,
                        color: isDark
                            ? Colors.blue.shade200
                            : Colors.blue.shade600,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 80,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          color: Colors.blue.withAlpha(isDark ? 60 : 40),
                        ),
                        child: Icon(
                          Icons.storage_rounded,
                          color: isDark
                              ? Colors.blue.shade200
                              : Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Data Selalu Aman',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Backup otomatis ke cloud setiap minggu. Data bisnis Anda aman, bahkan saat offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

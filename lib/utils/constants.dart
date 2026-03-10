import 'package:flutter/material.dart';

/// Responsive layout helper for tablet/mobile views
class ResponsiveHelper {
  /// Get button width for tablet/mobile responsive design
  /// Returns percentage width on tablet in landscape mode, full width in portrait
  static double getButtonWidth(BuildContext context, {double tabletPercent = 0.4}) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    
    // Only constrain on tablets in landscape mode
    // In portrait, always use full width
    if (width > 600 && orientation == Orientation.landscape) {
      return width * tabletPercent;
    }
    return double.infinity;
  }

  /// Get whether device is in tablet mode (only in landscape)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    return width > 600 && orientation == Orientation.landscape;
  }

  /// Get main axis alignment for tablet/mobile
  static MainAxisAlignment getMainAxisAlignment(BuildContext context) {
    return isTablet(context) ? MainAxisAlignment.center : MainAxisAlignment.start;
  }
}

/// App-wide constants.
class AppConstants {
  static const String appName = 'LabaKu';
  static const String appTagline = 'Kelola Bisnis Lebih Mudah';

  // API Base URL
  // Production: https://ucs.mathlab.id/api
  // Android emulator (local dev): http://10.0.2.2/api_labaku
  static const String apiBaseUrl = 'https://ucs.mathlab.id/api';

  // Product units
  static const List<String> productUnits = [
    'pcs',
    'kg',
    'gram',
    'liter',
    'ml',
    'porsi',
    'bungkus',
    'botol',
    'dus',
  ];

  // Product categories
  static const List<String> productCategories = [
    'Umum',
    'Makanan',
    'Minuman',
    'Snack',
    'Bahan Baku',
    'Kemasan',
    'Lainnya',
  ];

  // Low stock threshold
  static const int lowStockThreshold = 5;
}

/// Date range helper.
class DateRangeHelper {
  static DateTimeRange today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    return DateTimeRange(start: start, end: end);
  }

  static DateTimeRange thisWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startDay = DateTime(start.year, start.month, start.day);
    final end = startDay.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
    return DateTimeRange(start: startDay, end: end);
  }

  static DateTimeRange thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
    return DateTimeRange(start: start, end: end);
  }

  static DateTimeRange last30Days() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = end.subtract(const Duration(days: 30));
    return DateTimeRange(start: start, end: end);
  }
}

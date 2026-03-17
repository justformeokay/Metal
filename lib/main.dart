import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/auth_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/transaction_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/settings_controller.dart';
import 'services/cloud_backup_service.dart';
import 'services/app_version_service.dart';
import 'utils/theme.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/store_setup_screen.dart';
import 'views/home_shell.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/app/force_update_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize locale data for Indonesian
  await initializeDateFormatting('id_ID', null);
  runApp(const LabaKuApp());
}

class LabaKuApp extends StatelessWidget {
  const LabaKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => TransactionController()),
        ChangeNotifierProvider(create: (_) => ExpenseController()),
        ChangeNotifierProvider(create: (_) => SettingsController()..load()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'LabaKu',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [
              Locale('id', 'ID'),
              Locale('en', 'US'),
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Decides whether to show LoginScreen or HomeShell based on auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _onboardingDone = false;
  VersionCheckResult? _versionBlock; // non-null = show force update page

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkOnboarding();
    _checkVersionThenAuth();
  }

  /// Request runtime permissions needed by the app (Bluetooth, Camera, Location).
  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.camera,
    ].request();
  }

  Future<void> _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_done') ?? false;
      if (mounted) setState(() => _onboardingDone = done);
    } catch (e) {
      if (mounted) setState(() => _onboardingDone = true);
    }
  }

  Future<void> _checkVersionThenAuth() async {
    // Run version check and auth check concurrently
    final results = await Future.wait([
      AppVersionService.check(),
      _runAuthCheck(),
    ]);

    final versionResult = results[0] as VersionCheckResult?;

    if (mounted) {
      setState(() {
        // Block if update is required or server is in maintenance
        if (versionResult != null &&
            (!versionResult.isSupported || versionResult.maintenanceMode)) {
          _versionBlock = versionResult;
        }
        _checking = false;
      });
    }
  }

  Future<void> _runAuthCheck() async {
    final auth = context.read<AuthController>();
    await auth.tryAutoLogin();

    if (auth.isLoggedIn && !auth.needsStoreSetup) {
      await _reloadControllers();
      CloudBackupService.checkAutoBackup();
    }
  }

  /// Reload all data controllers after user switch / login.
  Future<void> _reloadControllers() async {
    await context.read<ProductController>().loadProducts();
    await context.read<ExpenseController>().loadExpenses();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboardingDone) {
      return OnboardingView(onComplete: _completeOnboarding);
    }

    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Force update or maintenance screen — blocks all navigation
    if (_versionBlock != null) {
      return ForceUpdateView(versionInfo: _versionBlock!);
    }

    return Consumer<AuthController>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn) {
          if (auth.needsStoreSetup) return const StoreSetupScreen();
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}

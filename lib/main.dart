import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/settings/pin_lock_screen.dart';

/// Initializes Flutter, opens the local database, loads persisted state, and
/// starts the app with the shared providers already ready to use.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initDatabase();

  final settingsProvider = SettingsProvider();
  final productProvider = ProductProvider();
  final cartProvider = CartProvider();
  final transactionProvider = TransactionProvider();

  await settingsProvider.loadSettings();
  await productProvider.loadProducts();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ChangeNotifierProvider<TransactionProvider>.value(
          value: transactionProvider,
        ),
      ],
      child: const TindaTapApp(),
    ),
  );
}

class TindaTapApp extends StatelessWidget {
  const TindaTapApp({super.key});

  /// Builds the app's single light theme so colors and controls stay
  /// consistent across every screen.
  ThemeData _lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    );

    return base.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override

  /// Builds the root MaterialApp and routes the user into setup, lock, or the
  /// main home screen depending on the current app state.
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TindaTap',
      theme: _lightTheme(),
      // Enforce single light theme only
      home: const AppGate(),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _configured = false;
  bool _lastKnownPinEnabled = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeoutTimer?.cancel();
    super.dispose();
  }

  /// Starts or refreshes the inactivity timer that locks the app after the
  /// configured timeout period.
  void _startTimeoutTimer(int minutes) {
    _timeoutTimer?.cancel();
    if (minutes <= 0) return;
    _timeoutTimer = Timer(Duration(minutes: minutes), () {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      if (settings.pinEnabled) {
        setState(() => _locked = true);
      }
    });
  }

  /// Clears the lock flag after a successful PIN unlock and restarts the idle
  /// timer so the app can lock again later.
  void _unlock() {
    final settings = context.read<SettingsProvider>();
    setState(() => _locked = false);
    _startTimeoutTimer(settings.pinTimeoutMinutes);
  }

  @override

  /// Reacts to lifecycle changes so the app can cancel timers when paused and
  /// re-lock itself when the user returns.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<SettingsProvider>();
    if (!settings.pinEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _timeoutTimer?.cancel();
    }

    if (state == AppLifecycleState.resumed && settings.isSetupComplete) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (!settings.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_configured || _lastKnownPinEnabled != settings.pinEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _configured = true;
          _lastKnownPinEnabled = settings.pinEnabled;
          _locked = settings.pinEnabled;
        });
        if (settings.pinEnabled) {
          _startTimeoutTimer(settings.pinTimeoutMinutes);
        } else {
          _timeoutTimer?.cancel();
        }
      });
    }

    if (!settings.isSetupComplete) {
      return const SetupScreen();
    }

    if (settings.pinEnabled && _locked) {
      return PinLockScreen(onUnlocked: _unlock);
    }

    return const HomeScreen();
  }
}

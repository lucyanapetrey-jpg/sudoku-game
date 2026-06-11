import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'services/review_service.dart';
import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/purchase_service.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'widgets/remove_ads_offer.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Guard service init so any failure (e.g. missing AdMob app id, no store
  // connectivity) cannot crash app launch — required after Apple 2.1(a) reject.
  try {
    await PurchaseService.instance.initialize();
  } catch (_) {}
  // App Tracking Transparency is requested natively in the iOS AppDelegate
  // (no Flutter plugin) — the app_tracking_transparency pod broke `pod install`
  // on CI, so we match the working games' native ATTrackingManager approach.

  unawaited(AdsService.instance.initialize());
  ReviewService.instance.registerLaunch();
  AudioService.instance.init();
  NotificationService.instance.scheduleDailyReminder(
    title: 'Sudoku Summer',
    body: 'Antrenează-ți mintea cu un Sudoku rapid! 🧩',
  );
  runApp(const SudokuApp());
}

class SudokuApp extends StatefulWidget {
  const SudokuApp({super.key});

  @override
  State<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends State<SudokuApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Show the upsell right after a full-screen ad (App Open / interstitial) closes.
    AdsService.instance.adClosedTick.addListener(_onAdClosed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AdsService.instance.adClosedTick.removeListener(_onAdClosed);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdsService.instance.showAppOpenIfReady();
    }
  }

  void _onAdClosed() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) RemoveAdsOffer.maybeShow(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Summer',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: UpgradeAlert(child: const HomeScreen()),
    );
  }
}

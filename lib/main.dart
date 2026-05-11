import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Guard service init so any failure (e.g. missing AdMob app id, no store
  // connectivity) cannot crash app launch — required after Apple 2.1(a) reject.
  try {
    await PurchaseService.instance.initialize();
  } catch (_) {}
  unawaited(AdsService.instance.initialize());
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Summer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: const HomeScreen(),
    );
  }
}

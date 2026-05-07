import 'package:flutter/material.dart';
import '../game/sudoku_generator.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'SUDOKU',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Puzzle clasic 9×9',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const Spacer(),
              _DifficultyButton(label: 'Ușor', d: Difficulty.easy, color: Colors.green),
              const SizedBox(height: 12),
              _DifficultyButton(label: 'Mediu', d: Difficulty.medium, color: Colors.orange),
              const SizedBox(height: 12),
              _DifficultyButton(label: 'Greu', d: Difficulty.hard, color: Colors.red),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final Difficulty d;
  final Color color;
  const _DifficultyButton({required this.label, required this.d, required this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(difficulty: d)),
      ),
      child: Text(label),
    );
  }
}

import 'package:flutter/material.dart';
import '../game/sudoku_generator.dart';
import '../services/rewards_service.dart';
import 'daily_reward_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rewards = RewardsService();
  int _coins = 0;
  bool _dailyDone = false;

  @override
  void initState() {
    super.initState();
    _checkDaily();
  }

  Future<void> _checkDaily() async {
    final r = await _rewards.claimDailyIfAvailable();
    if (r.reward > 0 && mounted) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => DailyRewardScreen(day: r.day, reward: r.reward)));
    }
    _load();
  }

  Future<void> _load() async {
    final c = await _rewards.getCoins();
    final d = await _rewards.isDailyPuzzleDone();
    if (mounted) setState(() { _coins = c; _dailyDone = d; });
  }

  int get _todaySeed {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1565C0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFAB00), size: 20),
                        const SizedBox(width: 6),
                        Text('$_coins',
                            style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 28),
              // Daily puzzle card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _dailyDone
                        ? [const Color(0xFFA5D6A7), const Color(0xFF66BB6A)]
                        : [const Color(0xFFFFAB00), const Color(0xFFFF6F00)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Puzzle Zilnic',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                          Text(_dailyDone
                              ? 'Făcut! Recompensă +50 coins'
                              : 'Rezolvă pentru +50 coins',
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    if (!_dailyDone)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF6F00),
                        ),
                        onPressed: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => GameScreen(
                                      difficulty: Difficulty.medium,
                                      isDaily: true,
                                      seed: _todaySeed)));
                          _load();
                        },
                        child: const Text('JOACĂ', style: TextStyle(fontWeight: FontWeight.w900)),
                      )
                    else
                      const Icon(Icons.check_circle, color: Colors.white, size: 32),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Joc liber',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              const SizedBox(height: 12),
              _DifficultyButton(label: 'Ușor', d: Difficulty.easy, color: Colors.green, onDone: _load),
              const SizedBox(height: 12),
              _DifficultyButton(label: 'Mediu', d: Difficulty.medium, color: Colors.orange, onDone: _load),
              const SizedBox(height: 12),
              _DifficultyButton(label: 'Greu', d: Difficulty.hard, color: Colors.red, onDone: _load),
              const Spacer(),
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
  final VoidCallback onDone;
  const _DifficultyButton({required this.label, required this.d, required this.color, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameScreen(difficulty: d)),
        );
        onDone();
      },
      child: Text(label),
    );
  }
}

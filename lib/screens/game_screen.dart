import 'dart:async';
import 'package:flutter/material.dart';
import '../game/sudoku_generator.dart';
import '../services/ads_service.dart';
import '../services/rewards_service.dart';
import '../widgets/banner_ad_widget.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final bool isDaily;
  final int? seed;
  const GameScreen({super.key, required this.difficulty, this.isDaily = false, this.seed});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SudokuPuzzle _p;
  int _selR = -1, _selC = -1;
  int _seconds = 0;
  Timer? _timer;
  int _mistakes = 0;
  bool _won = false;
  int _hintsUsed = 0;
  int _extraHints = 0;
  final List<_Move> _history = [];
  final _rewards = RewardsService();

  @override
  void initState() {
    super.initState();
    _p = SudokuGenerator().generate(widget.difficulty);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_won && mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _enter(int n) {
    if (_selR < 0 || _won) return;
    if (_p.given[_selR][_selC]) return;
    setState(() {
      _history.add(_Move(_selR, _selC, _p.puzzle[_selR][_selC]));
      _p.puzzle[_selR][_selC] = n;
      if (n != 0 && _p.solution[_selR][_selC] != n) {
        _mistakes++;
      }
      _checkWin();
    });
  }

  Future<void> _useHint() async {
    if (_won) return;
    if (_selR < 0 || _p.given[_selR][_selC]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectează o celulă goală')),
      );
      return;
    }
    if (_hintsUsed == 0) {
      _applyHint();
      return;
    }
    if (_extraHints > 0) {
      setState(() => _extraHints--);
      _applyHint();
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Indiciu suplimentar'),
        content: const Text('Vezi un scurt videoclip pentru un indiciu gratuit.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Renunță')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Vezi video'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final earned = await AdsService.instance.showRewarded();
    if (!mounted) return;
    if (earned) {
      _applyHint();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reclama nu e disponibilă acum, încearcă din nou.')),
      );
    }
  }

  void _applyHint() {
    setState(() => _hintsUsed++);
    _enter(_p.solution[_selR][_selC]);
  }

  Future<void> _buyExtraHints() async {
    if (_won) return;
    final earned = await AdsService.instance.showRewarded();
    if (!mounted) return;
    if (earned) {
      setState(() => _extraHints += 3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎁 +3 indicii adăugate!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reclama nu e disponibilă acum, încearcă din nou.')),
      );
    }
  }

  Future<void> _skipPuzzleViaAd() async {
    if (_won) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sari peste puzzle'),
        content: const Text('Vezi un scurt videoclip pentru a marca puzzle-ul ca rezolvat și a primi monede.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Renunță')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Vezi video'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final earned = await AdsService.instance.showRewarded();
    if (!mounted) return;
    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reclama nu e disponibilă acum, încearcă din nou.')),
      );
      return;
    }
    setState(() {
      for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
          _p.puzzle[i][j] = _p.solution[i][j];
        }
      }
    });
    _checkWin();
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      final m = _history.removeLast();
      _p.puzzle[m.r][m.c] = m.prev;
    });
  }

  void _checkWin() {
    for (var i = 0; i < 9; i++) {
      for (var j = 0; j < 9; j++) {
        if (_p.puzzle[i][j] != _p.solution[i][j]) return;
      }
    }
    _won = true;
    _timer?.cancel();
    final coins = widget.isDaily ? 50 : (widget.difficulty == Difficulty.easy ? 10 : (widget.difficulty == Difficulty.medium ? 25 : 50));
    _rewards.addCoins(coins);
    if (widget.isDaily) _rewards.markDailyPuzzleDone();
    AdsService.instance.maybeShowInterstitial();
    Future.microtask(() {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🎉 Felicitări!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Puzzle complet!\nTimp: ${_fmtTime(_seconds)}\nGreșeli: $_mistakes'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFAB00)),
                    const SizedBox(width: 6),
                    Text('+$coins coins',
                        style: const TextStyle(
                            color: Color(0xFFFF6F00),
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Acasă'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _p = SudokuGenerator().generate(widget.difficulty);
                  _seconds = 0;
                  _mistakes = 0;
                  _hintsUsed = 0;
                  _extraHints = 0;
                  _won = false;
                  _history.clear();
                });
                _timer = Timer.periodic(const Duration(seconds: 1), (_) {
                  if (!_won && mounted) setState(() => _seconds++);
                });
              },
              child: const Text('Din nou'),
            ),
          ],
        ),
      );
    });
  }

  String _fmtTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  String get _diffLabel => switch (widget.difficulty) {
        Difficulty.easy => 'Ușor',
        Difficulty.medium => 'Mediu',
        Difficulty.hard => 'Greu',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: Text('Sudoku · $_diffLabel'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Sari peste puzzle (reclamă)',
            icon: const Icon(Icons.skip_next),
            onPressed: _won ? null : _skipPuzzleViaAd,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18),
                      const SizedBox(width: 4),
                      Text(_fmtTime(_seconds), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('$_mistakes', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBoard()),
            _buildKeypad(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, c) {
              final size = c.maxWidth;
              final cell = size / 9;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Stack(
                  children: [
                    for (var r = 0; r < 9; r++)
                      for (var c2 = 0; c2 < 9; c2++)
                        Positioned(
                          left: c2 * cell,
                          top: r * cell,
                          width: cell,
                          height: cell,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selR = r;
                              _selC = c2;
                            }),
                            child: _buildCell(r, c2, cell),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int r, int c, double cell) {
    final v = _p.puzzle[r][c];
    final given = _p.given[r][c];
    final selected = r == _selR && c == _selC;
    final highlight = _selR >= 0 &&
        (_selR == r ||
            _selC == c ||
            (r ~/ 3 == _selR ~/ 3 && c ~/ 3 == _selC ~/ 3));
    final sameNumber = _selR >= 0 &&
        v != 0 &&
        v == _p.puzzle[_selR][_selC];
    final wrong = !given && v != 0 && v != _p.solution[r][c];

    Color bg = Colors.white;
    if (sameNumber) bg = const Color(0xFFBBDEFB);
    else if (selected) bg = const Color(0xFF90CAF9);
    else if (highlight) bg = const Color(0xFFE3F2FD);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: BorderSide(
            color: Colors.black,
            width: ((c + 1) % 3 == 0 && c != 8) ? 2 : 0.4,
          ),
          bottom: BorderSide(
            color: Colors.black,
            width: ((r + 1) % 3 == 0 && r != 8) ? 2 : 0.4,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: v == 0
          ? const SizedBox.shrink()
          : Text(
              '$v',
              style: TextStyle(
                fontSize: cell * 0.5,
                fontWeight: given ? FontWeight.w700 : FontWeight.w400,
                color: wrong
                    ? Colors.red
                    : (given ? Colors.black : const Color(0xFF1565C0)),
              ),
            ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 1; i <= 9; i++) _keyButton('$i', () => _enter(i)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(Icons.undo, 'Înapoi', _undo),
              _actionButton(Icons.backspace_outlined, 'Șterge', () => _enter(0)),
              _actionButton(Icons.lightbulb_outline,
                  _extraHints > 0 ? 'Indiciu ($_extraHints)' : 'Indiciu', _useHint),
              _actionButton(Icons.ondemand_video, '💡 +3 reclamă', _buyExtraHints),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyButton(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: const Color(0xFF1565C0)),
                  Text(label, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Move {
  final int r, c, prev;
  _Move(this.r, this.c, this.prev);
}

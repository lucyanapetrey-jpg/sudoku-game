import 'dart:math';

enum Difficulty { easy, medium, hard }

class SudokuPuzzle {
  final List<List<int>> solution; // full 9x9
  final List<List<int>> puzzle;   // with 0 for blanks
  final List<List<bool>> given;   // true if cell is from the puzzle (locked)

  SudokuPuzzle({required this.solution, required this.puzzle, required this.given});
}

class SudokuGenerator {
  final _rng = Random();

  SudokuPuzzle generate(Difficulty d) {
    final board = List.generate(9, (_) => List.filled(9, 0));
    _fill(board);
    final solution = board.map((r) => List<int>.from(r)).toList();

    int holes;
    switch (d) {
      case Difficulty.easy:
        holes = 36;
        break;
      case Difficulty.medium:
        holes = 46;
        break;
      case Difficulty.hard:
        holes = 54;
        break;
    }

    final puzzle = solution.map((r) => List<int>.from(r)).toList();
    int removed = 0;
    while (removed < holes) {
      final r = _rng.nextInt(9);
      final c = _rng.nextInt(9);
      if (puzzle[r][c] != 0) {
        puzzle[r][c] = 0;
        removed++;
      }
    }
    final given = List.generate(9, (i) => List.generate(9, (j) => puzzle[i][j] != 0));
    return SudokuPuzzle(solution: solution, puzzle: puzzle, given: given);
  }

  bool _fill(List<List<int>> board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          final nums = List.generate(9, (i) => i + 1)..shuffle(_rng);
          for (final n in nums) {
            if (_safe(board, r, c, n)) {
              board[r][c] = n;
              if (_fill(board)) return true;
              board[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _safe(List<List<int>> b, int r, int c, int n) {
    for (var i = 0; i < 9; i++) {
      if (b[r][i] == n) return false;
      if (b[i][c] == n) return false;
    }
    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        if (b[br + i][bc + j] == n) return false;
      }
    }
    return true;
  }
}

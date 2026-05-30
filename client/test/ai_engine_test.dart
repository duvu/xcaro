import 'package:flutter_test/flutter_test.dart';
import 'package:xcaro/ai/ai_engine.dart';

void main() {
  group('AiEngine difficulty', () {
    test('Easy AI returns move quickly', () {
      final board = List.generate(15, (_) => List.filled(15, 0));
      // Place some stones
      board[7][7] = 1;
      board[7][8] = 2;
      final move = AiEngine.bestMove(board, 2, difficulty: AiDifficulty.easy);
      expect(move.containsKey('x'), isTrue);
      expect(move.containsKey('y'), isTrue);
    });

    test('Medium AI returns valid move', () {
      final board = List.generate(15, (_) => List.filled(15, 0));
      board[7][7] = 1;
      final move = AiEngine.bestMove(board, 2, difficulty: AiDifficulty.medium);
      expect(board[move['x']!][move['y']!], 0); // Cell must be empty
    });

    test('Hard AI returns valid move', () {
      final board = List.generate(15, (_) => List.filled(15, 0));
      board[7][7] = 1;
      board[7][8] = 1;
      board[7][9] = 1;
      final move = AiEngine.bestMove(board, 2, difficulty: AiDifficulty.hard);
      expect(board[move['x']!][move['y']!], 0);
    });
  });
}

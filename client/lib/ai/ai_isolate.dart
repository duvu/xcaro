import 'dart:isolate';
import 'ai_engine.dart';

Future<Map<String, int>> computeAiMove(
    List<List<int>> board, int aiPlayer,
    {AiDifficulty difficulty = AiDifficulty.medium}) async {
  // Deep copy board for isolate
  final boardCopy = board.map((row) => List<int>.from(row)).toList();
  return await Isolate.run(
      () => AiEngine.bestMove(boardCopy, aiPlayer, difficulty: difficulty));
}

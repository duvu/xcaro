import 'dart:isolate';
import '../ai_engine.dart';
import 'chess_ai_engine.dart';

/// Runs [ChessAiEngine.bestMove] in a separate isolate.
Future<String?> computeChessAiMove(String fen, AiDifficulty difficulty) async {
  return await Isolate.run(() => ChessAiEngine.bestMove(fen, difficulty));
}

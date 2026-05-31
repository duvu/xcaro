import 'caro/caro_module.dart';
import 'chess/chess_module.dart';
import 'game_module.dart';

class GameRegistry {
  GameRegistry._();

  static const List<GameModule> modules = [caroGameModule, chessGameModule];

  static GameModule? find(String gameType) {
    for (final module in modules) {
      if (module.gameType == gameType) return module;
    }
    return null;
  }
}

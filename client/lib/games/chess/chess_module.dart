import '../game_module.dart';

const chessGameModule = GameModule(
  gameType: 'chess',
  createRoomRoute: '/chess_online',
  joinRoomRoute: '/chess_join',
  aiRoute: '/chess_ai',
  supportsOnline: true,
  supportsAI: true,
);

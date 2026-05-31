import '../game_module.dart';

const caroGameModule = GameModule(
  gameType: 'caro',
  createRoomRoute: '/create_room',
  joinRoomRoute: '/join_room',
  aiRoute: '/ai_game',
  supportsOnline: true,
  supportsAI: true,
);

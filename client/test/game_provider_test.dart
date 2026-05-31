import 'package:flutter_test/flutter_test.dart';
import 'package:playverse/providers/chat_provider.dart';
import 'package:playverse/providers/game_provider.dart';
import 'package:playverse/services/api_service.dart';
import 'package:playverse/services/websocket_service.dart';

void main() {
  test('applies quick-match game_state with minimal WS users', () {
    final provider = GameProvider(
      ApiService(),
      WebSocketService(),
      ChatProvider(),
    );

    final board = List.generate(
        15,
        (x) => List.generate(15, (y) {
              if (x == 7 && y == 7) return 1;
              return 0;
            }));

    provider.handleQuickMatchFound({
      'room_id': 'room-1',
      'room_code': 'ABC123',
      'game_state': {
        'room_id': 'room-1',
        'room_code': 'ABC123',
        'board': board,
        'turn': 2,
        'started': true,
        'status': 'active',
        'players': {
          'x': {'user_id': 'user-x', 'username': 'Alice'},
          'o': {'user_id': 'user-o', 'username': 'Bob'},
        },
      },
    });

    expect(provider.roomId, 'room-1');
    expect(provider.roomCode, 'ABC123');
    expect(provider.hasOnlineRoom, isTrue);
    expect(provider.started, isTrue);
    expect(provider.board[7][7], 1);
    expect(provider.playerX?.id, 'user-x');
    expect(provider.playerX?.username, 'Alice');
    expect(provider.playerO?.id, 'user-o');
    expect(provider.currentTurn, 'user-o');
    expect(provider.gameOver, isFalse);

    provider.dispose();
  });

  test('resetOnlineGameState clears online room and errors', () {
    final provider = GameProvider(
      ApiService(),
      WebSocketService(),
      ChatProvider(),
    );

    provider.handleQuickMatchFound({
      'room_id': 'room-1',
      'room_code': 'ABC123',
      'game_state': {
        'room_id': 'room-1',
        'room_code': 'ABC123',
        'started': true,
      },
    });

    provider.resetOnlineGameState();

    expect(provider.roomId, isNull);
    expect(provider.roomCode, isNull);
    expect(provider.hasOnlineRoom, isFalse);
    expect(provider.started, isFalse);
    expect(provider.currentTurn, isNull);

    provider.dispose();
  });
}

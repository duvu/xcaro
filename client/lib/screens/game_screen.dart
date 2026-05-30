import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/offline_game_provider.dart';
import '../services/local_storage_service.dart';
import '../services/websocket_service.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('XCaro'),
        actions: [
          if (!isAuthenticated)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Đăng nhập'),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
              },
            ),
        ],
      ),
      body: !isAuthenticated
          ? ChangeNotifierProvider(
              create: (context) => OfflineGameProvider(
                context.read<LocalStorageService>(),
              ),
              child: const OfflineGameView(),
            )
          : const OnlineGameView(),
    );
  }
}

class OfflineGameView extends StatelessWidget {
  const OfflineGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineGameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.currentGame == null) {
          return Center(
            child: ElevatedButton(
              onPressed: () => gameProvider.startNewGame(),
              child: const Text('Bắt đầu chơi'),
            ),
          );
        }

        final game = gameProvider.currentGame!;
        final isMyTurn = game.currentPlayer == gameProvider.currentUser;

        return Column(
          children: [
            _TurnIndicator(
              label: isMyTurn ? 'Lượt của bạn (X)' : 'Lượt của đối thủ (O)',
              isMyTurn: isMyTurn,
            ),
            Expanded(
              child: GameBoard(
                board: game.board,
                onTap: (x, y) => gameProvider.makeMove(x, y),
                canTap: (x, y) =>
                    game.status == 'playing' && isMyTurn && game.board[x][y].isEmpty,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (game.status == 'finished')
                    Text(
                      game.winner == null
                          ? 'Hòa!'
                          : 'Người thắng: ${game.winner == gameProvider.currentUser ? "Bạn (X)" : "Đối thủ (O)"}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ElevatedButton(
                    onPressed: () => gameProvider.startNewGame(),
                    child: const Text('Chơi lại'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class OnlineGameView extends StatefulWidget {
  const OnlineGameView({super.key});

  @override
  State<OnlineGameView> createState() => _OnlineGameViewState();
}

class _OnlineGameViewState extends State<OnlineGameView> {
  bool _dialogShown = false;
  bool _chatOpen = false;

  void _showEndDialog(BuildContext context, GameProvider gameProvider) {
    if (_dialogShown) return;
    _dialogShown = true;

    final winner = gameProvider.winner;
    final auth = context.read<AuthProvider>();
    final myId = auth.currentUser?.id;

    String message;
    if (winner == null || winner == 'draw') {
      message = 'Hòa! 🤝';
    } else if (winner == 'disconnect') {
      message = 'Đối thủ đã ngắt kết nối! 🚫';
    } else {
      // winner is player id
      message = winner == myId ? 'Bạn thắng! 🎉' : 'Bạn thua! 😞';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Kết thúc trận đấu'),
          content: Text(message, style: const TextStyle(fontSize: 20)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _dialogShown = false;
                gameProvider.resetOnlineGameState();
              },
              child: const Text('Chơi lại'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _dialogShown = false;
                gameProvider.clearCurrentGame();
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Trang chủ'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (gameProvider.gameOver) {
          _showEndDialog(context, gameProvider);
        } else {
          _dialogShown = false;
        }

        final game = gameProvider.currentGame;
        if (game == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/create_room'),
                  child: const Text('Tạo phòng mới'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/join_room'),
                  child: const Text('Tham gia phòng'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/home'),
                  child: const Text('Danh sách phòng'),
                ),
              ],
            ),
          );
        }

        final auth = context.read<AuthProvider>();
        final myId = auth.currentUser?.id;
        final isMyTurn = gameProvider.currentTurn == myId;

        // Convert int board to string board for GameBoard widget
        final stringBoard = gameProvider.board
            .map((row) => row.map((v) => v == 1 ? 'X' : v == 2 ? 'O' : '').toList())
            .toList();

        return Column(
          children: [
            _TurnIndicator(
              label: isMyTurn ? 'Lượt của bạn' : 'Lượt của đối thủ',
              isMyTurn: isMyTurn,
            ),
            Expanded(
              child: GameBoard(
                board: stringBoard,
                onTap: (x, y) => gameProvider.makeMove(x, y),
                canTap: (x, y) => isMyTurn && !gameProvider.gameOver,
              ),
            ),
            // Chat panel
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _chatOpen ? 250 : 0,
              child: ClipRect(
                child: _chatOpen
                    ? _ChatPanel(
                        onClose: () =>
                            setState(() => _chatOpen = false),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Chat',
                    onPressed: () =>
                        setState(() => _chatOpen = !_chatOpen),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      gameProvider.clearCurrentGame();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: const Text('Thoát'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChatPanel extends StatefulWidget {
  final VoidCallback onClose;

  const _ChatPanel({required this.onClose});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<WebSocketService>().send({
      'type': 'chat_message',
      'payload': {'content': text},
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final messages = chatProvider.messages;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin nhắn',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('[${msg.timestamp}] ${msg.content}'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnIndicator extends StatelessWidget {
  final String label;
  final bool isMyTurn;

  const _TurnIndicator({required this.label, required this.isMyTurn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isMyTurn
          ? Colors.green.withOpacity(0.15)
          : Colors.grey.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: isMyTurn ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMyTurn ? Colors.green : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

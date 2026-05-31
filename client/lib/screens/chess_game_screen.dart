import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squares/squares.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/chat_provider.dart';
import '../services/websocket_service.dart';
import '../ai/chess/chess_ai_engine.dart';

class ChessGameScreen extends StatefulWidget {
  const ChessGameScreen({super.key});

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  final _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  String? get _myId => context.read<AuthProvider>().currentUser?.id;

  /// Convert FEN + my player info to BoardState for squares widget.
  BoardState _buildBoardState(GameProvider gp) {
    final fen = gp.fen;
    if (fen == null) return BoardState.empty();

    final flatBoard = ChessAiEngine.fenToSquaresBoard(fen);
    final squaresTurn = ChessAiEngine.turnFromFen(fen);

    // Orientation: white=0 if I'm player_x (white), else black=1
    final myId = _myId;
    final iAmWhite = gp.playerX?.id == myId;
    final orientation = iAmWhite ? Squares.white : Squares.black;

    return BoardState(
      board: flatBoard,
      turn: squaresTurn,
      orientation: orientation,
    );
  }

  /// Build legal moves list (empty since moves come from server; we rely on server validation).
  /// We use an empty list so all squares are tappable and server will reject illegal moves.
  List<Move> _buildLegalMoves(GameProvider gp) {
    // Since we are server-authoritative, we don't compute legal moves on client.
    // Build all pseudo-legal moves from FEN for visual highlighting.
    final fen = gp.fen;
    if (fen == null || gp.gameOver || !gp.started) return [];
    final myId = _myId;
    final iAmWhite = gp.playerX?.id == myId;
    final isMyTurn = gp.currentTurn == myId;
    if (!isMyTurn) return [];

    // Parse moves from engine just for UI highlighting
    try {
      final board = ChessAiEngine.fenToSquaresBoard(fen);
      // Generate all moves for current player's pieces
      final rawMoves = <Move>[];
      // Since squares uses flat index 0=a8..63=h1, we build moves by checking
      // pieces on board. This is simplified - just enable from squares that have my pieces.
      for (int i = 0; i < 64; i++) {
        final piece = board[i];
        if (piece.isEmpty) continue;
        final isWhitePiece = piece == piece.toUpperCase();
        if (isWhitePiece == iAmWhite) {
          // Add placeholder moves to all empty/opponent squares for highlighting
          for (int j = 0; j < 64; j++) {
            if (i == j) continue;
            final target = board[j];
            if (target.isEmpty || (isWhitePiece ? target == target.toLowerCase() : target == target.toUpperCase())) {
              rawMoves.add(Move(from: i, to: j));
            }
          }
        }
      }
      return rawMoves;
    } catch (_) {
      return [];
    }
  }

  void _onMove(Move move, GameProvider gp) {
    final fromUci = ChessAiEngine.squareIndexToUci(move.from);
    final toUci = ChessAiEngine.squareIndexToUci(move.to);
    gp.makeChessMove(fromUci, toUci, promotion: move.promo);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, AuthProvider>(
      builder: (context, gp, auth, _) {
        final fen = gp.fen;
        final boardState = _buildBoardState(gp);
        final legalMoves = _buildLegalMoves(gp);
        final myId = auth.currentUser?.id;
        final isMyTurn = gp.currentTurn == myId && gp.started && !gp.gameOver;
        final playState = gp.gameOver
            ? PlayState.finished
            : (isMyTurn ? PlayState.ourTurn : PlayState.theirTurn);

        // Show end dialog when game over
        if (gp.gameOver && gp.result != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showEndDialog(context, gp, myId);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(gp.roomCode != null ? 'Cờ Vua #${gp.roomCode}' : 'Cờ Vua Online'),
            actions: [
              if (gp.started && !gp.gameOver)
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'Đầu hàng',
                  onPressed: () => _confirmResign(context, gp),
                ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Rời phòng',
                onPressed: () => _leaveRoom(context, gp),
              ),
            ],
          ),
          body: Column(
            children: [
              // Player info bar (opponent on top)
              _PlayerBar(gp: gp, showOpponent: true, myId: myId),

              // Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: fen == null
                      ? _WaitingBanner(roomCode: gp.roomCode)
                      : BoardController(
                          state: boardState,
                          playState: playState,
                          pieceSet: PieceSet.merida(),
                          theme: BoardTheme.brown,
                          moves: legalMoves,
                          onMove: (m) => _onMove(m, gp),
                          markerTheme: MarkerTheme(
                            empty: MarkerTheme.dot,
                            piece: MarkerTheme.corners(),
                          ),
                          promotionBehaviour: PromotionBehaviour.alwaysSelect,
                        ),
                ),
              ),

              // Player info bar (me on bottom)
              _PlayerBar(gp: gp, showOpponent: false, myId: myId),

              // Error banner
              if (gp.lastErrorCode != null)
                _ErrorBanner(
                    code: gp.lastErrorCode!, message: gp.lastErrorMessage),

              // Chat
              _ChatBar(
                controller: _chatController,
                chatProvider: context.watch<ChatProvider>(),
                onSend: () {
                  final text = _chatController.text.trim();
                  if (text.isNotEmpty) {
                    context.read<WebSocketService>().sendChatMessage(text);
                    _chatController.clear();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmResign(BuildContext context, GameProvider gp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đầu hàng?'),
        content: const Text('Bạn chắc chắn muốn đầu hàng?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WebSocketService>().resign();
            },
            child: const Text('Đầu hàng'),
          ),
        ],
      ),
    );
  }

  void _leaveRoom(BuildContext context, GameProvider gp) {
    context.read<WebSocketService>().leaveRoom(gp.roomId);
    gp.clearCurrentGame();
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _showEndDialog(BuildContext context, GameProvider gp, String? myId) {
    final result = gp.result ?? '';
    final winner = gp.winner ?? '';

    String title;
    String message;
    if (result == 'draw') {
      title = 'Hòa cờ!';
      message = 'Ván cờ kết thúc hòa.';
    } else if (winner == myId) {
      title = 'Bạn thắng! 🎉';
      message = result == 'resign'
          ? 'Đối thủ đã đầu hàng.'
          : result == 'forfeit'
              ? 'Đối thủ mất kết nối.'
              : 'Chiếu hết!';
    } else {
      title = 'Bạn thua!';
      message = result == 'resign'
          ? 'Bạn đã đầu hàng.'
          : result == 'forfeit'
              ? 'Bạn mất kết nối.'
              : 'Đối thủ chiếu hết.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _leaveRoom(context, gp);
            },
            child: const Text('Trang chủ'),
          ),
        ],
      ),
    );
  }
}

class _WaitingBanner extends StatelessWidget {
  final String? roomCode;
  const _WaitingBanner({this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Đang chờ đối thủ...', style: TextStyle(fontSize: 16)),
          if (roomCode != null) ...[
            const SizedBox(height: 8),
            Text('Mã phòng: $roomCode',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Chia sẻ mã này cho đối thủ của bạn.'),
          ],
        ],
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final GameProvider gp;
  final bool showOpponent;
  final String? myId;

  const _PlayerBar(
      {required this.gp, required this.showOpponent, required this.myId});

  @override
  Widget build(BuildContext context) {
    final iAmWhite = gp.playerX?.id == myId;
    final player = showOpponent
        ? (iAmWhite ? gp.playerO : gp.playerX)
        : (iAmWhite ? gp.playerX : gp.playerO);
    final isMyTurn = gp.currentTurn == player?.id && !gp.gameOver;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isMyTurn ? Colors.amber.withValues(alpha: 0.15) : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(player?.username.isNotEmpty == true
                ? player!.username[0].toUpperCase()
                : '?'),
          ),
          const SizedBox(width: 8),
          Text(player?.username ?? 'Chờ...', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (isMyTurn) ...[
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: Colors.amber)),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String code;
  final String? message;
  const _ErrorBanner({required this.code, this.message});

  @override
  Widget build(BuildContext context) {
    final msg = _errorMsg(code, message);
    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(msg, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
    );
  }

  String _errorMsg(String code, String? serverMsg) {
    switch (code) {
      case 'illegal_move':
        return 'Nước đi không hợp lệ.';
      case 'not_your_turn':
        return 'Chưa đến lượt của bạn.';
      case 'game_already_over':
        return 'Ván cờ đã kết thúc.';
      default:
        return serverMsg ?? code;
    }
  }
}

class _ChatBar extends StatelessWidget {
  final TextEditingController controller;
  final ChatProvider chatProvider;
  final VoidCallback onSend;

  const _ChatBar(
      {required this.controller,
      required this.chatProvider,
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatProvider.messages.length,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemBuilder: (_, i) {
                final m = chatProvider.messages[i];
                return Text(
                  '${m.senderId}: ${m.content}',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Nhắn tin...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: InputBorder.none,
                  ),
                  maxLength: 500,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  onSubmitted: (_) => onSend(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, size: 18),
                onPressed: onSend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:squares/squares.dart';
import '../ai/ai_engine.dart';
import '../ai/chess/chess_ai_engine.dart';
import '../ai/chess/chess_ai_isolate.dart';

class ChessAiGameScreen extends StatefulWidget {
  const ChessAiGameScreen({super.key});

  @override
  State<ChessAiGameScreen> createState() => _ChessAiGameScreenState();
}

class _ChessAiGameScreenState extends State<ChessAiGameScreen> {
  AiDifficulty _difficulty = AiDifficulty.medium;
  bool _difficultySelected = false;
  bool _aiThinking = false;

  // Player plays white (0), AI plays black (1).
  // FEN tracks the current board state.
  String _fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  String? _lastFrom;
  String? _lastTo;
  bool _gameOver = false;
  String? _resultMessage;
  int _moveCount = 0;

  BoardState get _boardState {
    final flatBoard = ChessAiEngine.fenToSquaresBoard(_fen);
    final turn = ChessAiEngine.turnFromFen(_fen);
    final lastFromIdx = _lastFrom != null ? ChessAiEngine.squareIndex(_lastFrom!) : null;
    final lastToIdx = _lastTo != null ? ChessAiEngine.squareIndex(_lastTo!) : null;
    return BoardState(
      board: flatBoard,
      turn: turn,
      orientation: Squares.white, // player always sees white at bottom
      lastFrom: lastFromIdx,
      lastTo: lastToIdx,
    );
  }

  PlayState get _playState {
    if (_gameOver) return PlayState.finished;
    final turn = ChessAiEngine.turnFromFen(_fen);
    return (turn == Squares.white) ? PlayState.ourTurn : PlayState.theirTurn;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDifficultySheet());
  }

  void _showDifficultySheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _DifficultySheet(
        selected: _difficulty,
        onSelected: (d) {
          setState(() {
            _difficulty = d;
            _difficultySelected = true;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onMove(Move move) async {
    if (_gameOver || _aiThinking) return;

    final fromUci = ChessAiEngine.squareIndexToUci(move.from);
    final toUci = ChessAiEngine.squareIndexToUci(move.to);
    final promo = move.promo; // lowercase promotion piece or null

    // Build the UCI move string for our engine
    final moveStr = promo != null ? '$fromUci$toUci$promo' : '$fromUci$toUci';

    // Apply player move using engine
    try {
      // Apply move to get new FEN (reuse server engine logic via applying the move)
      final newFen = _applyMoveToFen(_fen, moveStr);
      if (newFen == null) return; // invalid move

      setState(() {
        _fen = newFen;
        _lastFrom = fromUci;
        _lastTo = toUci;
        _moveCount++;
      });

      // Check game over after player move
      if (_checkGameOver(newFen)) return;

      // AI move
      setState(() => _aiThinking = true);
      final aiMove = await computeChessAiMove(newFen, _difficulty);
      if (!mounted) return;

      if (aiMove == null) {
        // No AI moves = stalemate or checkmate
        setState(() {
          _aiThinking = false;
          _gameOver = true;
          _resultMessage = 'Hết nước đi! Hòa cờ.';
        });
        _showEndDialog();
        return;
      }

      final aiFrom = aiMove.substring(0, 2);
      final aiTo = aiMove.substring(2, 4);
      final afterAiFen = _applyMoveToFen(newFen, aiMove);
      if (!mounted) return;

      setState(() {
        _aiThinking = false;
        if (afterAiFen != null) {
          _fen = afterAiFen;
          _lastFrom = aiFrom;
          _lastTo = aiTo;
          _moveCount++;
        }
      });

      _checkGameOver(afterAiFen ?? _fen);
    } catch (e) {
      setState(() => _aiThinking = false);
    }
  }

  /// Apply a UCI move to a FEN and return the new FEN.
  /// Uses the same logic as ChessAiEngine internals.
  String? _applyMoveToFen(String fen, String move) {
    // This calls into ChessAiEngine's FEN parsing and move application.
    // Since _applyMove is private in the engine, we replicate minimal logic here
    // by re-using the existing engine bestMove to detect valid state changes.
    // For correctness without re-implementing the FEN serializer, we use the
    // notnil/chess server for authority and just update the FEN from server in
    // online mode. For AI mode, we need client-side FEN update.
    // We'll implement a simplified FEN serializer here.
    return _simpleFenApply(fen, move);
  }

  String? _simpleFenApply(String fen, String move) {
    if (move.length < 4) return null;
    final parts = fen.split(' ');
    if (parts.length < 6) return null;

    final rows = parts[0].split('/');
    if (rows.length != 8) return null;

    // Parse board to 8x8
    final squares = List.generate(8, (_) => List.filled(8, '', growable: false));
    for (int r = 0; r < 8; r++) {
      int f = 0;
      for (final ch in rows[r].split('')) {
        final n = int.tryParse(ch);
        if (n != null) { f += n; } else { squares[r][f] = ch; f++; }
      }
    }

    final fromUci = move.substring(0, 2);
    final toUci = move.substring(2, 4);
    final promo = move.length == 5 ? move[4] : null;

    int fr = 8 - int.parse(fromUci[1]);
    int ff = fromUci.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int tr = 8 - int.parse(toUci[1]);
    int tf = toUci.codeUnitAt(0) - 'a'.codeUnitAt(0);

    if (fr < 0 || fr >= 8 || ff < 0 || ff >= 8) return null;
    if (tr < 0 || tr >= 8 || tf < 0 || tf >= 8) return null;

    final piece = squares[fr][ff];
    if (piece.isEmpty) return null;

    final isWhite = piece == piece.toUpperCase();

    // En passant
    final enPassantSq = parts[3];
    if (piece.toLowerCase() == 'p' && enPassantSq != '-') {
      final epr = 8 - int.parse(enPassantSq[1]);
      final epf = enPassantSq.codeUnitAt(0) - 'a'.codeUnitAt(0);
      if (tr == epr && tf == epf) {
        final captRow = isWhite ? tr + 1 : tr - 1;
        squares[captRow][tf] = '';
      }
    }

    // Castling rook
    if (piece == 'K' && ff == 4 && fr == 7) {
      if (tf == 6) { squares[7][5] = squares[7][7]; squares[7][7] = ''; }
      else if (tf == 2) { squares[7][3] = squares[7][0]; squares[7][0] = ''; }
    } else if (piece == 'k' && ff == 4 && fr == 0) {
      if (tf == 6) { squares[0][5] = squares[0][7]; squares[0][7] = ''; }
      else if (tf == 2) { squares[0][3] = squares[0][0]; squares[0][0] = ''; }
    }

    // Move
    final movingPiece = promo != null ? (isWhite ? promo.toUpperCase() : promo) : piece;
    squares[tr][tf] = movingPiece;
    squares[fr][ff] = '';

    // Double pawn advance → en passant target
    String newEp = '-';
    if (piece.toLowerCase() == 'p' && (fr - tr).abs() == 2) {
      final epRow = (fr + tr) ~/ 2;
      final epFile = String.fromCharCode('a'.codeUnitAt(0) + tf);
      newEp = '$epFile${8 - epRow}';
    }

    // Update castling rights
    String castling = parts[2];
    if (piece == 'K') castling = castling.replaceAll('K', '').replaceAll('Q', '');
    if (piece == 'k') castling = castling.replaceAll('k', '').replaceAll('q', '');
    if (fr == 7 && ff == 0) castling = castling.replaceAll('Q', '');
    if (fr == 7 && ff == 7) castling = castling.replaceAll('K', '');
    if (fr == 0 && ff == 0) castling = castling.replaceAll('q', '');
    if (fr == 0 && ff == 7) castling = castling.replaceAll('k', '');
    if (castling.isEmpty) castling = '-';

    // Rebuild FEN position string
    final newFenRows = <String>[];
    for (int r = 0; r < 8; r++) {
      final sb = StringBuffer();
      int empty = 0;
      for (int f = 0; f < 8; f++) {
        final sq = squares[r][f];
        if (sq.isEmpty) {
          empty++;
        } else {
          if (empty > 0) { sb.write(empty); empty = 0; }
          sb.write(sq);
        }
      }
      if (empty > 0) sb.write(empty);
      newFenRows.add(sb.toString());
    }

    final turn = parts[1] == 'w' ? 'b' : 'w';
    final halfMove = piece.toLowerCase() == 'p' || squares[tr][tf].isNotEmpty ? 0 : (int.tryParse(parts[4]) ?? 0) + 1;
    final fullMove = parts[1] == 'b' ? (int.tryParse(parts[5]) ?? 1) + 1 : int.tryParse(parts[5]) ?? 1;

    return '${newFenRows.join('/')} $turn $castling $newEp $halfMove $fullMove';
  }

  bool _checkGameOver(String fen) {
    // Check for stalemate/no moves (simplified)
    final isWhite = ChessAiEngine.turnFromFen(fen) == Squares.white;
    final aiMove = ChessAiEngine.bestMove(fen, AiDifficulty.easy);
    if (aiMove == null) {
      setState(() {
        _gameOver = true;
        _resultMessage = isWhite ? 'Đen chiếu hết! Bạn thua.' : 'Trắng chiếu hết! Bạn thắng! 🎉';
      });
      _showEndDialog();
      return true;
    }
    return false;
  }

  void _showEndDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Kết thúc ván cờ'),
          content: Text(_resultMessage ?? 'Ván cờ đã kết thúc.', style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              },
              child: const Text('Chơi lại'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Trang chủ'),
            ),
          ],
        ),
      );
    });
  }

  void _resetGame() {
    setState(() {
      _fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      _lastFrom = null;
      _lastTo = null;
      _gameOver = false;
      _resultMessage = null;
      _moveCount = 0;
      _aiThinking = false;
    });
    _showDifficultySheet();
  }

  @override
  Widget build(BuildContext context) {
    if (!_difficultySelected) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cờ Vua với AI')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cờ Vua với AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Chơi lại',
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // AI player header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Máy (${_difficultyLabel(_difficulty)})',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (_aiThinking) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),

          // Board
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: BoardController(
                state: _boardState,
                playState: _playState,
                pieceSet: PieceSet.merida(),
                theme: BoardTheme.brown,
                moves: _playState == PlayState.ourTurn ? _buildLegalMoves() : [],
                onMove: _onMove,
                markerTheme: MarkerTheme(
                  empty: MarkerTheme.dot,
                  piece: MarkerTheme.corners(),
                ),
                promotionBehaviour: PromotionBehaviour.alwaysSelect,
                draggable: !_aiThinking,
              ),
            ),
          ),

          // Human player footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                const Text('Bạn (Trắng)', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Nước $_moveCount', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Move> _buildLegalMoves() {
    final flatBoard = ChessAiEngine.fenToSquaresBoard(_fen);
    final moves = <Move>[];
    for (int i = 0; i < 64; i++) {
      final p = flatBoard[i];
      if (p.isEmpty || p != p.toUpperCase()) continue; // only white pieces
      for (int j = 0; j < 64; j++) {
        if (i == j) continue;
        final target = flatBoard[j];
        if (target.isEmpty || target == target.toLowerCase()) {
          moves.add(Move(from: i, to: j));
        }
      }
    }
    return moves;
  }

  String _difficultyLabel(AiDifficulty d) {
    switch (d) {
      case AiDifficulty.easy:
        return 'Dễ';
      case AiDifficulty.medium:
        return 'Trung bình';
      case AiDifficulty.hard:
        return 'Khó';
    }
  }
}

class _DifficultySheet extends StatelessWidget {
  final AiDifficulty selected;
  final void Function(AiDifficulty) onSelected;

  const _DifficultySheet({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Chọn độ khó',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          for (final d in AiDifficulty.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: OutlinedButton(
                onPressed: () => onSelected(d),
                child: Text(_label(d)),
              ),
            ),
        ],
      ),
    );
  }

  String _label(AiDifficulty d) {
    switch (d) {
      case AiDifficulty.easy:
        return 'Dễ';
      case AiDifficulty.medium:
        return 'Trung bình';
      case AiDifficulty.hard:
        return 'Khó';
    }
  }
}

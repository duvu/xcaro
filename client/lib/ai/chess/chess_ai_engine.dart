import '../ai_engine.dart';

/// Client-side chess AI using minimax with alpha-beta pruning.
/// Operates entirely on FEN strings.
/// Depths: Easy=1, Medium=2, Hard=3.
class ChessAiEngine {
  // Piece values for evaluation
  static const Map<String, int> _pieceValues = {
    'p': -100,
    'n': -320,
    'b': -330,
    'r': -500,
    'q': -900,
    'k': -20000,
    'P': 100,
    'N': 320,
    'B': 330,
    'R': 500,
    'Q': 900,
    'K': 20000,
  };

  /// Returns best move as UCI string (e.g. "e2e4" or "e7e8q") given a FEN.
  /// Returns null if no legal moves available.
  static String? bestMove(String fen, AiDifficulty difficulty) {
    final board = _parseFen(fen);
    if (board == null) return null;

    final isWhite = fen.split(' ')[1] == 'w';
    final moves = _generateMoves(board, isWhite);
    if (moves.isEmpty) return null;

    int searchDepth;
    switch (difficulty) {
      case AiDifficulty.easy:
        searchDepth = 1;
      case AiDifficulty.medium:
        searchDepth = 2;
      case AiDifficulty.hard:
        searchDepth = 3;
    }

    final deadline = DateTime.now().add(const Duration(milliseconds: 900));
    int bestScore = isWhite ? -9999999 : 9999999;
    String bestMove = moves.first;

    for (final move in moves) {
      if (DateTime.now().isAfter(deadline)) break;
      final newBoard = _applyMove(board, move);
      if (newBoard == null) continue;
      final score = _minimax(
          newBoard, searchDepth - 1, -9999999, 9999999, !isWhite, deadline);
      if (isWhite && score > bestScore) {
        bestScore = score;
        bestMove = move;
      } else if (!isWhite && score < bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  static int _minimax(_ChessBoard board, int depth, int alpha, int beta,
      bool maximizing, DateTime deadline) {
    if (depth == 0 || DateTime.now().isAfter(deadline)) {
      return _evaluate(board);
    }

    final moves = _generateMoves(board, maximizing);
    if (moves.isEmpty) {
      // No moves: stalemate or checkmate
      if (_isInCheck(board, maximizing)) {
        return maximizing ? -9000000 : 9000000; // checkmate
      }
      return 0; // stalemate
    }

    if (maximizing) {
      int maxEval = -9999999;
      for (final move in moves) {
        final child = _applyMove(board, move);
        if (child == null) continue;
        final e = _minimax(child, depth - 1, alpha, beta, false, deadline);
        if (e > maxEval) maxEval = e;
        if (e > alpha) alpha = e;
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 9999999;
      for (final move in moves) {
        final child = _applyMove(board, move);
        if (child == null) continue;
        final e = _minimax(child, depth - 1, alpha, beta, true, deadline);
        if (e < minEval) minEval = e;
        if (e < beta) beta = e;
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  static int _evaluate(_ChessBoard board) {
    int score = 0;
    for (int r = 0; r < 8; r++) {
      for (int f = 0; f < 8; f++) {
        final piece = board.squares[r][f];
        if (piece.isNotEmpty) {
          score += _pieceValues[piece] ?? 0;
        }
      }
    }
    return score;
  }

  // ------ FEN parsing ------
  static _ChessBoard? _parseFen(String fen) {
    final parts = fen.split(' ');
    if (parts.isEmpty) return null;
    final rows = parts[0].split('/');
    if (rows.length != 8) return null;

    final squares =
        List.generate(8, (_) => List.filled(8, '', growable: false));
    for (int r = 0; r < 8; r++) {
      int f = 0;
      for (final ch in rows[r].split('')) {
        final n = int.tryParse(ch);
        if (n != null) {
          f += n;
        } else {
          if (f < 8) squares[r][f] = ch;
          f++;
        }
      }
    }

    final isWhiteTurn = parts.length < 2 || parts[1] == 'w';
    final enPassantStr = parts.length >= 4 ? parts[3] : '-';
    final enPassant =
        enPassantStr != '-' ? _squareFromAlgebraic(enPassantStr) : null;
    final castling = parts.length >= 3 ? parts[2] : 'KQkq';

    return _ChessBoard(
      squares: squares,
      isWhiteTurn: isWhiteTurn,
      enPassant: enPassant,
      castlingRights: castling,
    );
  }

  // ------ Move generation (pseudo-legal, no check validation for speed) ------
  static List<String> _generateMoves(_ChessBoard board, bool white) {
    final List<String> moves = [];
    for (int r = 0; r < 8; r++) {
      for (int f = 0; f < 8; f++) {
        final piece = board.squares[r][f];
        if (piece.isEmpty) continue;
        final isWhitePiece = piece == piece.toUpperCase();
        if (isWhitePiece != white) continue;

        final lower = piece.toLowerCase();
        switch (lower) {
          case 'p':
            moves.addAll(_pawnMoves(board, r, f, white));
          case 'n':
            moves.addAll(_knightMoves(board, r, f, white));
          case 'b':
            moves.addAll(_slidingMoves(board, r, f, white, _bishopDirs));
          case 'r':
            moves.addAll(_slidingMoves(board, r, f, white, _rookDirs));
          case 'q':
            moves.addAll(
                _slidingMoves(board, r, f, white, [..._bishopDirs, ..._rookDirs]));
          case 'k':
            moves.addAll(_kingMoves(board, r, f, white));
        }
      }
    }
    return moves;
  }

  static const _rookDirs = [
    [-1, 0], [1, 0], [0, -1], [0, 1]
  ];
  static const _bishopDirs = [
    [-1, -1], [-1, 1], [1, -1], [1, 1]
  ];

  static List<String> _pawnMoves(_ChessBoard b, int r, int f, bool white) {
    final List<String> moves = [];
    final dir = white ? -1 : 1;
    final startRow = white ? 6 : 1;
    final promoRow = white ? 0 : 7;

    // Forward
    final nr = r + dir;
    if (nr >= 0 && nr < 8 && b.squares[nr][f].isEmpty) {
      if (nr == promoRow) {
        for (final p in ['q', 'r', 'b', 'n']) {
          moves.add('${_toUci(r, f)}${_toUci(nr, f)}$p');
        }
      } else {
        moves.add('${_toUci(r, f)}${_toUci(nr, f)}');
      }
      // Double advance from start
      if (r == startRow) {
        final nr2 = r + 2 * dir;
        if (b.squares[nr2][f].isEmpty) {
          moves.add('${_toUci(r, f)}${_toUci(nr2, f)}');
        }
      }
    }

    // Captures
    for (final df in [-1, 1]) {
      final nf = f + df;
      if (nf < 0 || nf >= 8) continue;
      if (nr < 0 || nr >= 8) continue;
      final target = b.squares[nr][nf];
      final isEnPassant =
          b.enPassant != null && b.enPassant == [nr, nf];

      if ((target.isNotEmpty &&
              (white
                  ? target == target.toLowerCase()
                  : target == target.toUpperCase())) ||
          isEnPassant) {
        if (nr == promoRow) {
          for (final p in ['q', 'r', 'b', 'n']) {
            moves.add('${_toUci(r, f)}${_toUci(nr, nf)}$p');
          }
        } else {
          moves.add('${_toUci(r, f)}${_toUci(nr, nf)}');
        }
      }
    }

    return moves;
  }

  static List<String> _knightMoves(_ChessBoard b, int r, int f, bool white) {
    final List<String> moves = [];
    const offsets = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1]
    ];
    for (final o in offsets) {
      final nr = r + o[0];
      final nf = f + o[1];
      if (nr < 0 || nr >= 8 || nf < 0 || nf >= 8) continue;
      final target = b.squares[nr][nf];
      if (target.isEmpty ||
          (white
              ? target == target.toLowerCase()
              : target == target.toUpperCase())) {
        moves.add('${_toUci(r, f)}${_toUci(nr, nf)}');
      }
    }
    return moves;
  }

  static List<String> _slidingMoves(
      _ChessBoard b, int r, int f, bool white, List<List<int>> dirs) {
    final List<String> moves = [];
    for (final dir in dirs) {
      int nr = r + dir[0];
      int nf = f + dir[1];
      while (nr >= 0 && nr < 8 && nf >= 0 && nf < 8) {
        final target = b.squares[nr][nf];
        if (target.isEmpty) {
          moves.add('${_toUci(r, f)}${_toUci(nr, nf)}');
        } else {
          if (white
              ? target == target.toLowerCase()
              : target == target.toUpperCase()) {
            moves.add('${_toUci(r, f)}${_toUci(nr, nf)}');
          }
          break;
        }
        nr += dir[0];
        nf += dir[1];
      }
    }
    return moves;
  }

  static List<String> _kingMoves(_ChessBoard b, int r, int f, bool white) {
    final List<String> moves = [];
    const offsets = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1], [0, 1],
      [1, -1], [1, 0], [1, 1]
    ];
    for (final o in offsets) {
      final nr = r + o[0];
      final nf = f + o[1];
      if (nr < 0 || nr >= 8 || nf < 0 || nf >= 8) continue;
      final target = b.squares[nr][nf];
      if (target.isEmpty ||
          (white
              ? target == target.toLowerCase()
              : target == target.toUpperCase())) {
        moves.add('${_toUci(r, f)}${_toUci(nr, nf)}');
      }
    }
    // Castling (simple: only check empty squares, not check status)
    if (white && r == 7 && f == 4) {
      if (b.castlingRights.contains('K') &&
          b.squares[7][5].isEmpty &&
          b.squares[7][6].isEmpty) {
        moves.add('e1g1');
      }
      if (b.castlingRights.contains('Q') &&
          b.squares[7][3].isEmpty &&
          b.squares[7][2].isEmpty &&
          b.squares[7][1].isEmpty) {
        moves.add('e1c1');
      }
    } else if (!white && r == 0 && f == 4) {
      if (b.castlingRights.contains('k') &&
          b.squares[0][5].isEmpty &&
          b.squares[0][6].isEmpty) {
        moves.add('e8g8');
      }
      if (b.castlingRights.contains('q') &&
          b.squares[0][3].isEmpty &&
          b.squares[0][2].isEmpty &&
          b.squares[0][1].isEmpty) {
        moves.add('e8c8');
      }
    }
    return moves;
  }

  // ------ Apply move ------
  static _ChessBoard? _applyMove(_ChessBoard board, String move) {
    if (move.length < 4) return null;
    final from = _squareFromUci(move.substring(0, 2));
    final to = _squareFromUci(move.substring(2, 4));
    final promo = move.length == 5 ? move[4] : null;
    if (from == null || to == null) return null;

    final squares =
        List.generate(8, (r) => List<String>.from(board.squares[r]));
    final piece = squares[from[0]][from[1]];
    if (piece.isEmpty) return null;

    final isWhite = piece == piece.toUpperCase();
    int? newEnPassant;

    // En passant capture
    if (piece.toLowerCase() == 'p' &&
        board.enPassant != null &&
        to[0] == board.enPassant![0] &&
        to[1] == board.enPassant![1]) {
      final capturedRow = isWhite ? to[0] + 1 : to[0] - 1;
      squares[capturedRow][to[1]] = '';
    }

    // Double pawn advance: set en passant square
    if (piece.toLowerCase() == 'p' && (from[0] - to[0]).abs() == 2) {
      final epRow = (from[0] + to[0]) ~/ 2;
      newEnPassant = epRow * 8 + to[1]; // encode as flat index for detection
    }

    // Castling rook move
    if (piece == 'K' && from[0] == 7 && from[1] == 4) {
      if (to[1] == 6) {
        squares[7][5] = squares[7][7];
        squares[7][7] = '';
      } else if (to[1] == 2) {
        squares[7][3] = squares[7][0];
        squares[7][0] = '';
      }
    } else if (piece == 'k' && from[0] == 0 && from[1] == 4) {
      if (to[1] == 6) {
        squares[0][5] = squares[0][7];
        squares[0][7] = '';
      } else if (to[1] == 2) {
        squares[0][3] = squares[0][0];
        squares[0][0] = '';
      }
    }

    // Move piece
    final movingPiece =
        promo != null ? (isWhite ? promo.toUpperCase() : promo) : piece;
    squares[to[0]][to[1]] = movingPiece;
    squares[from[0]][from[1]] = '';

    // Update castling rights
    String castling = board.castlingRights;
    if (piece == 'K') castling = castling.replaceAll('K', '').replaceAll('Q', '');
    if (piece == 'k') castling = castling.replaceAll('k', '').replaceAll('q', '');
    if (from[0] == 7 && from[1] == 0) castling = castling.replaceAll('Q', '');
    if (from[0] == 7 && from[1] == 7) castling = castling.replaceAll('K', '');
    if (from[0] == 0 && from[1] == 0) castling = castling.replaceAll('q', '');
    if (from[0] == 0 && from[1] == 7) castling = castling.replaceAll('k', '');
    if (castling.isEmpty) castling = '-';

    // Decode newEnPassant
    List<int>? ep;
    if (newEnPassant != null) {
      ep = [newEnPassant ~/ 8, newEnPassant % 8];
    }

    return _ChessBoard(
      squares: squares,
      isWhiteTurn: !board.isWhiteTurn,
      enPassant: ep,
      castlingRights: castling,
    );
  }

  // ------ Check detection ------
  static bool _isInCheck(_ChessBoard board, bool white) {
    // Find king
    int kr = -1, kf = -1;
    for (int r = 0; r < 8; r++) {
      for (int f = 0; f < 8; f++) {
        final p = board.squares[r][f];
        if (white && p == 'K') {
          kr = r;
          kf = f;
        } else if (!white && p == 'k') {
          kr = r;
          kf = f;
        }
      }
    }
    if (kr == -1) return true; // king captured (shouldn't happen)

    // Check if any opponent piece attacks king
    for (int r = 0; r < 8; r++) {
      for (int f = 0; f < 8; f++) {
        final p = board.squares[r][f];
        if (p.isEmpty) continue;
        final isOpp = white ? p == p.toLowerCase() : p == p.toUpperCase();
        if (!isOpp) continue;
        final oppMoves = _generateMovesForPiece(board, r, f, !white);
        for (final m in oppMoves) {
          final to = _squareFromUci(m.substring(2, 4));
          if (to != null && to[0] == kr && to[1] == kf) return true;
        }
      }
    }
    return false;
  }

  static List<String> _generateMovesForPiece(
      _ChessBoard board, int r, int f, bool white) {
    final piece = board.squares[r][f].toLowerCase();
    switch (piece) {
      case 'p':
        return _pawnMoves(board, r, f, white);
      case 'n':
        return _knightMoves(board, r, f, white);
      case 'b':
        return _slidingMoves(board, r, f, white, _bishopDirs);
      case 'r':
        return _slidingMoves(board, r, f, white, _rookDirs);
      case 'q':
        return _slidingMoves(
            board, r, f, white, [..._bishopDirs, ..._rookDirs]);
      case 'k':
        return _kingMoves(board, r, f, white);
      default:
        return [];
    }
  }

  // ------ Coordinate helpers ------
  /// Converts [row, file] to UCI square string: row 0 = rank 8, row 7 = rank 1.
  static String _toUci(int r, int f) {
    return '${String.fromCharCode('a'.codeUnitAt(0) + f)}${8 - r}';
  }

  /// Parses UCI square like "e2" → [row, file].
  static List<int>? _squareFromUci(String s) {
    if (s.length != 2) return null;
    final f = s.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final r = 8 - int.parse(s[1]);
    if (f < 0 || f >= 8 || r < 0 || r >= 8) return null;
    return [r, f];
  }

  /// Parses algebraic en passant square (e.g. "e3") → [row, file].
  static List<int>? _squareFromAlgebraic(String s) => _squareFromUci(s);

  /// Converts FEN piece string to squares-compatible BoardState.
  /// Returns a flat 64-element list of piece strings, row-major a8→h1.
  static List<String> fenToSquaresBoard(String fen) {
    final parts = fen.split(' ');
    final rows = parts[0].split('/');
    if (rows.length != 8) return List.filled(64, '');

    final result = <String>[];
    for (int r = 0; r < 8; r++) {
      int f = 0;
      for (final ch in rows[r].split('')) {
        final n = int.tryParse(ch);
        if (n != null) {
          for (int i = 0; i < n; i++) {
            result.add('');
          }
          f += n;
        } else {
          result.add(ch);
          f++;
        }
      }
      // Fill remainder if row is short
      while (f < 8) {
        result.add('');
        f++;
      }
    }
    return result;
  }

  /// Returns the squares (0-based, row-major 0=a8) index for a UCI square.
  static int? squareIndex(String uci) {
    final parsed = _squareFromUci(uci);
    if (parsed == null) return null;
    return parsed[0] * 8 + parsed[1];
  }

  /// Returns UCI square for a squares index.
  static String squareIndexToUci(int idx) {
    return _toUci(idx ~/ 8, idx % 8);
  }

  /// Whose turn from FEN: 0=white, 1=black.
  static int turnFromFen(String fen) {
    final parts = fen.split(' ');
    return (parts.length >= 2 && parts[1] == 'b') ? 1 : 0;
  }
}

class _ChessBoard {
  final List<List<String>> squares;
  final bool isWhiteTurn;
  final List<int>? enPassant;
  final String castlingRights;

  const _ChessBoard({
    required this.squares,
    required this.isWhiteTurn,
    this.enPassant,
    required this.castlingRights,
  });
}

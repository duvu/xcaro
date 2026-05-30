import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game_board.dart';
import '../audio_manager.dart';

class CaroGame extends FlameGame with TapCallbacks, DragCallbacks {
  final GameBoard gameBoard;
  final AudioManager audioManager = AudioManager();
  static const double cellSize = 40.0;
  Vector2 boardPosition = Vector2.zero();
  Vector2 targetPosition = Vector2.zero();
  bool isAnimating = false;
  double animationProgress = 0.0;
  final double animationDuration = 0.5;
  bool isDragging = false;
  Vector2 dragStart = Vector2.zero();
  Vector2 initialBoardPosition = Vector2.zero();

  // Thêm biến để theo dõi vị trí của viewport
  int viewportStartRow = 0;
  int viewportStartCol = 0;

  CaroGame(this.gameBoard);

  // Chuyển đổi từ tọa độ canvas sang tọa độ ô cờ
  (int, int) canvasToCell(Vector2 position) {
    final relativeX = position.x - boardPosition.x;
    final relativeY = position.y - boardPosition.y;
    final col = (relativeX / cellSize).floor();
    final row = (relativeY / cellSize).floor();
    return (row, col);
  }

  // Kiểm tra xem một ô có nằm trong vùng hợp lệ không
  bool isValidCell(int row, int col) {
    return row >= 0 && col >= 0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final screenCenter = Vector2(size.x / 2, size.y / 2);
    const boardSize = cellSize * GameBoard.size;
    boardPosition = Vector2(
      screenCenter.x - boardSize / 2,
      screenCenter.y - boardSize / 2,
    );
    initialBoardPosition = boardPosition.clone();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Lưu trạng thái canvas hiện tại
    canvas.save();

    // Vẽ lưới vô hạn với z-index thấp
    canvas.translate(0, 0);
    _drawInfiniteGrid(canvas);

    // Khôi phục trạng thái canvas
    canvas.restore();

    // Vẽ các quân cờ trên cùng
    _drawPieces(canvas);

    // Vẽ overlay thông tin lượt chơi
    _drawTurnOverlay(canvas);
  }

  void _drawInfiniteGrid(Canvas canvas) {
    final Paint gridPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8) // Giảm độ đục của nền
      ..style = PaintingStyle.fill;

    // Tính toán số lượng ô cần vẽ để phủ kín màn hình
    final startX = ((-boardPosition.x) / cellSize).floor() - 1;
    final startY = ((-boardPosition.y) / cellSize).floor() - 1;
    final endX = ((size.x - boardPosition.x) / cellSize).ceil() + 1;
    final endY = ((size.y - boardPosition.y) / cellSize).ceil() + 1;

    // Cập nhật viewport
    viewportStartRow = startY;
    viewportStartCol = startX;

    // Vẽ nền trắng cho toàn bộ khu vực game
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = Colors.white);

    for (var i = startY; i < endY; i++) {
      for (var j = startX; j < endX; j++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            boardPosition.x + j * cellSize,
            boardPosition.y + i * cellSize,
            cellSize,
            cellSize,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, backgroundPaint);
        canvas.drawRRect(rect, gridPaint);
      }
    }
  }

  void _drawPieces(Canvas canvas) {
    final startX = ((-boardPosition.x) / cellSize).floor() - 1;
    final startY = ((-boardPosition.y) / cellSize).floor() - 1;
    final endX = ((size.x - boardPosition.x) / cellSize).ceil() + 1;
    final endY = ((size.y - boardPosition.y) / cellSize).ceil() + 1;

    for (var i = startY; i < endY; i++) {
      for (var j = startX; j < endX; j++) {
        final value = gameBoard.getCellValue(i, j);
        if (value.isNotEmpty) {
          final textConfig = TextPaint(
            style: TextStyle(
              fontSize: cellSize * 0.6,
              fontWeight: FontWeight.bold,
              color: value == 'X' ? Colors.blue : Colors.red,
            ),
          );

          textConfig.render(
            canvas,
            value,
            Vector2(
              boardPosition.x + j * cellSize + cellSize / 2,
              boardPosition.y + i * cellSize + cellSize / 2,
            ),
            anchor: Anchor.center,
          );
        }
      }
    }
  }

  void _drawTurnOverlay(Canvas canvas) {
    final String turnText = gameBoard.isGameOver
        ? "🏆 Game Over - Winner: ${gameBoard.lastPlayer}"
        : "👉 Lượt của: ${gameBoard.currentPlayer}";

    final textConfig = TextPaint(
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
      ),
    );

    // Tính toán kích thước text bằng TextPainter
    final textPainter = TextPainter(
      text: TextSpan(
        text: turnText,
        style: textConfig.style,
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Vẽ nền cho text
    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.x / 2 - textPainter.width / 2 - 20,
        20,
        textPainter.width + 40,
        40,
      ),
      const Radius.circular(20),
    );

    canvas.drawRRect(
      backgroundRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      backgroundRect,
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Vẽ text
    textConfig.render(
      canvas,
      turnText,
      Vector2(size.x / 2, 40),
      anchor: Anchor.center,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isAnimating) {
      animationProgress += dt / animationDuration;
      if (animationProgress >= 1.0) {
        animationProgress = 1.0;
        isAnimating = false;
        gameBoard.completeAnimation();
      }

      final progress = Curves.easeInOut.transform(animationProgress);
      final currentX =
          boardPosition.x + (targetPosition.x - boardPosition.x) * progress;
      final currentY =
          boardPosition.y + (targetPosition.y - boardPosition.y) * progress;
      boardPosition = Vector2(currentX, currentY);
    }
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (isAnimating) {
      return false;
    }
    if (gameBoard.isGameOver) {
      return false;
    }
    isDragging = true;
    dragStart = event.canvasPosition;
    initialBoardPosition = boardPosition.clone();
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (isDragging && !isAnimating) {
      final newPosition = initialBoardPosition + event.localDelta;

      // Giới hạn vùng di chuyển
      final minY = -size.y * 0.2; // Giới hạn trên
      final maxY = size.y * 0.6; // Giới hạn dưới
      final minX = -size.x * 0.2; // Giới hạn trái
      final maxX = size.x * 0.6; // Giới hạn phải

      boardPosition = Vector2(
        newPosition.x.clamp(minX, maxX),
        newPosition.y.clamp(minY, maxY),
      );
    }
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    return true;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    isDragging = false;
  }

  void startAnimation(Vector2 target) {
    targetPosition = target;
    isAnimating = true;
    animationProgress = 0.0;
  }

  void centerBoard(int fromRow, int fromCol, int toRow, int toCol) {
    // Tính toán vị trí mới để đưa quân cờ vào giữa màn hình
    final screenCenter = Vector2(size.x / 2, size.y / 2);
    final targetCellCenter = Vector2(
      toCol * cellSize + cellSize / 2,
      toRow * cellSize + cellSize / 2,
    );

    // Tính toán vị trí mới cho bàn cờ để đưa ô đích vào giữa màn hình
    final newPosition = Vector2(
      screenCenter.x - targetCellCenter.x,
      screenCenter.y - targetCellCenter.y,
    );

    // Giới hạn vùng di chuyển
    final minY = -size.y * 0.2; // Giới hạn trên
    final maxY = size.y * 0.6; // Giới hạn dưới
    final minX = -size.x * 0.2; // Giới hạn trái
    final maxX = size.x * 0.6; // Giới hạn phải

    // Đảm bảo vị trí mới nằm trong giới hạn
    final clampedPosition = Vector2(
      newPosition.x.clamp(minX, maxX),
      newPosition.y.clamp(minY, maxY),
    );

    startAnimation(clampedPosition);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (isAnimating) {
      return false;
    }

    if (gameBoard.isGameOver) {
      return false;
    }

    final (row, col) = canvasToCell(event.canvasPosition);

    if (!isValidCell(row, col)) {
      return false;
    }

    if (gameBoard.getCellValue(row, col).isNotEmpty) {
      return false;
    }
    gameBoard.makeMove(row, col);
    audioManager.playMoveSound();
    return true;
  }
}

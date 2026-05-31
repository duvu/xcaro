import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Star-point positions (0-indexed row, col) for a standard 15×15 Gomoku board.
const _kStarPoints = [
  [3, 3], [3, 11],
  [7, 7],
  [11, 3], [11, 11],
];

class GameBoard extends StatelessWidget {
  final List<List<String>> board;
  final Function(int x, int y) onTap;
  final bool Function(int x, int y)? canTap;
  /// Winning cells as list of [row, col] pairs. Triggers win-line overlay.
  final List<List<int>>? winningCells;

  const GameBoard({
    super.key,
    required this.board,
    required this.onTap,
    this.canTap,
    this.winningCells,
  });

  @override
  Widget build(BuildContext context) {
    final rawCellSize = (MediaQuery.of(context).size.width - 32) / 15;
    final cellSize = rawCellSize.clamp(20.0, 40.0);
    final boardSide = cellSize * 15;

    return Center(
      child: SizedBox(
        width: boardSide,
        height: boardSide,
        child: Stack(
          children: [
            // Board SVG background (fills the full board area)
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/board.svg',
                fit: BoxFit.fill,
              ),
            ),
            // Star points
            ...(_kStarPoints.map((pt) => _StarPoint(
                  row: pt[0],
                  col: pt[1],
                  cellSize: cellSize,
                ))),
            // Cells (transparent tap areas + stones)
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 15,
              ),
              itemCount: board.length * board[0].length,
              itemBuilder: (context, index) {
                final x = index ~/ board[0].length;
                final y = index % board[0].length;
                final value = board[x][y];
                final enabled = canTap != null ? canTap!(x, y) : true;

                return _BoardCell(
                  value: value,
                  onTap: enabled && value.isEmpty ? () => onTap(x, y) : null,
                );
              },
            ),
            // Win-line overlay
            if (winningCells != null && winningCells!.length >= 2)
              Positioned.fill(
                child: _WinLineOverlay(
                  winningCells: winningCells!,
                  cellSize: cellSize,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Star point dot ──────────────────────────────────────────────────────────

class _StarPoint extends StatelessWidget {
  final int row;
  final int col;
  final double cellSize;

  const _StarPoint(
      {required this.row, required this.col, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    final left = col * cellSize + cellSize / 2 - 3;
    final top = row * cellSize + cellSize / 2 - 3;
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.brown.shade700,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Win line overlay ─────────────────────────────────────────────────────────

class _WinLineOverlay extends StatefulWidget {
  final List<List<int>> winningCells;
  final double cellSize;

  const _WinLineOverlay(
      {required this.winningCells, required this.cellSize});

  @override
  State<_WinLineOverlay> createState() => _WinLineOverlayState();
}

class _WinLineOverlayState extends State<_WinLineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) => CustomPaint(
        painter: _WinLinePainter(
          winningCells: widget.winningCells,
          cellSize: widget.cellSize,
          progress: _progress.value,
        ),
      ),
    );
  }
}

class _WinLinePainter extends CustomPainter {
  final List<List<int>> winningCells;
  final double cellSize;
  final double progress;

  _WinLinePainter(
      {required this.winningCells,
      required this.cellSize,
      required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (winningCells.length < 2) return;

    // Sort cells so line goes from first to last
    final sorted = List.of(winningCells);
    sorted.sort((a, b) {
      final rowCmp = a[0].compareTo(b[0]);
      return rowCmp != 0 ? rowCmp : a[1].compareTo(b[1]);
    });

    final start = Offset(
      sorted.first[1] * cellSize + cellSize / 2,
      sorted.first[0] * cellSize + cellSize / 2,
    );
    final end = Offset(
      sorted.last[1] * cellSize + cellSize / 2,
      sorted.last[0] * cellSize + cellSize / 2,
    );
    final current = Offset.lerp(start, end, progress)!;

    final paint = Paint()
      ..color = const Color(0xFFD4AF37) // AppColors.secondary / gold
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, current, paint);
  }

  @override
  bool shouldRepaint(_WinLinePainter old) =>
      old.progress != progress || old.winningCells != winningCells;
}

// ── Board cell ────────────────────────────────────────────────────────────────

class _BoardCell extends StatefulWidget {
  final String value;
  final VoidCallback? onTap;

  const _BoardCell({required this.value, this.onTap});

  @override
  State<_BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<_BoardCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  String _prevValue = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.value.isNotEmpty) {
      _controller.value = 1.0;
    }
    _prevValue = widget.value;
  }

  @override
  void didUpdateWidget(_BoardCell old) {
    super.didUpdateWidget(old);
    if (widget.value.isNotEmpty && _prevValue.isEmpty) {
      _controller.forward(from: 0.0);
    }
    _prevValue = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      // Transparent cell — board SVG shows through
      child: Container(
        color: Colors.transparent,
        child: widget.value.isEmpty
            ? null
            : Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: CustomPaint(
                    painter: _StonePainter(isBlack: widget.value == 'X'),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Stone painter ─────────────────────────────────────────────────────────────

class _StonePainter extends CustomPainter {
  final bool isBlack;

  const _StonePainter({required this.isBlack});

  @override
  void paint(Canvas canvas, Size size) {
    final double r = math.min(size.width, size.height) / 2 * 0.88;
    final center = Offset(size.width / 2, size.height / 2);

    // Radial gradient for 3-D effect
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 0.8,
      colors: isBlack
          ? [const Color(0xFF4A4A4A), const Color(0xFF1A1A1A)]
          : [const Color(0xFFFFFFFF), const Color(0xFFD0D0D0)],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);

    // Subtle ring border
    final borderPaint = Paint()
      ..color = (isBlack ? Colors.black : Colors.grey.shade400)
          .withValues(alpha: 0.6)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r, borderPaint);
  }

  @override
  bool shouldRepaint(_StonePainter old) => old.isBlack != isBlack;
}

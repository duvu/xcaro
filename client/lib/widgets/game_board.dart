import 'package:flutter/material.dart';

class GameBoard extends StatelessWidget {
  final List<List<String>> board;
  final Function(int x, int y) onTap;
  final bool Function(int x, int y)? canTap;

  const GameBoard({
    super.key,
    required this.board,
    required this.onTap,
    this.canTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawCellSize = (MediaQuery.of(context).size.width - 32) / 15;
    final effectiveCellSize = rawCellSize.clamp(20.0, 40.0);
    final boardSide = effectiveCellSize * 15;

    return Center(
      child: SizedBox(
        width: boardSide,
        height: boardSide,
        child: GridView.builder(
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
      ),
    );
  }
}

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
    final isX = widget.value == 'X';
    final color = isX ? Colors.blue : Colors.red;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
          color: Colors.amber.shade50,
        ),
        child: widget.value.isEmpty
            ? null
            : Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

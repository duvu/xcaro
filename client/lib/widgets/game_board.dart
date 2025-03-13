import 'package:flutter/material.dart';

class GameBoard extends StatelessWidget {
  final List<List<int>> board;
  final Function(int x, int y) onTap;

  const GameBoard({
    super.key,
    required this.board,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: board.length,
      ),
      itemCount: board.length * board.length,
      itemBuilder: (context, index) {
        final x = index ~/ board.length;
        final y = index % board.length;
        final value = board[x][y];

        return GestureDetector(
          onTap: () => onTap(x, y),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: value == 0
                  ? null
                  : Text(
                      value == 1 ? 'X' : 'O',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

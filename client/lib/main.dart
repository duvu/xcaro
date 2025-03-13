import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flame/game.dart';
import 'dart:math' show pi;
import 'game_board.dart';
import 'game/caro_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/local_storage_service.dart';
import 'services/connectivity_service.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/offline_game_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/offline_game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);
  final apiService = ApiService(storage);
  final gameBoard = GameBoard();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService, storage),
        ),
        ChangeNotifierProvider(
          create: (_) => GameProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => OfflineGameProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => GameBoard(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XCaro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ConfettiController _confettiController;
  late CaroGame _game;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    final gameBoard = context.read<GameBoard>();
    _game = CaroGame(gameBoard);

    // Đăng ký callback cho animation
    gameBoard.setAnimationCallback((fromRow, fromCol, toRow, toCol) {
      _game.centerBoard(fromRow, fromCol, toRow, toCol);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkGameState(GameBoard gameBoard) {
    if (gameBoard.isGameOver &&
        _confettiController.state == ConfettiControllerState.stopped) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caro Game'),
        centerTitle: true,
        leading: PopupMenuButton<GameMode>(
          icon: const Icon(Icons.gamepad),
          onSelected: (GameMode mode) {
            context.read<GameBoard>().setGameMode(mode);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<GameMode>>[
            const PopupMenuItem<GameMode>(
              value: GameMode.pvp,
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Chơi với người'),
                ],
              ),
            ),
            const PopupMenuItem<GameMode>(
              value: GameMode.pvc,
              child: Row(
                children: [
                  Icon(Icons.computer, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Chơi với máy'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isAuthenticated) {
                return TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Đăng nhập',
                      style: TextStyle(color: Colors.white)),
                );
              } else {
                return Row(
                  children: [
                    Text(authProvider.currentUser?.username ?? '',
                        style: const TextStyle(color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        authProvider.logout();
                      },
                    ),
                  ],
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GameBoard>().resetGame();
              if (_confettiController.state ==
                  ConfettiControllerState.playing) {
                _confettiController.stop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Consumer<GameBoard>(
                  builder: (context, gameBoard, child) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _checkGameState(gameBoard);
                    });
                    return const SizedBox.shrink();
                  },
                ),
                Expanded(
                  flex: 6,
                  child: GameWidget(
                    game: _game,
                  ),
                ),
                const Expanded(flex: 1, child: SizedBox()),
              ],
            ),
            // Thông tin người chơi X (góc trái)
            Positioned(
              left: 20,
              top: 20,
              child: Consumer<GameBoard>(
                builder: (context, gameBoard, child) {
                  return _buildPlayerInfo(
                    name: 'Người chơi X',
                    symbol: 'X',
                    thinkingTime: gameBoard.xThinkingTime,
                    moves: gameBoard.xMoves,
                    isCurrentPlayer: gameBoard.currentPlayer == 'X',
                    color: Colors.blue,
                  );
                },
              ),
            ),
            // Thông tin người chơi O (góc phải)
            Positioned(
              right: 20,
              top: 20,
              child: Consumer<GameBoard>(
                builder: (context, gameBoard, child) {
                  return _buildPlayerInfo(
                    name: gameBoard.gameMode == GameMode.pvc
                        ? 'Máy'
                        : 'Người chơi O',
                    symbol: 'O',
                    thinkingTime: gameBoard.oThinkingTime,
                    moves: gameBoard.oMoves,
                    isCurrentPlayer: gameBoard.currentPlayer == 'O',
                    color: Colors.red,
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 7,
                minBlastForce: 2,
                emissionFrequency: 0.08,
                numberOfParticles: 50,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.yellow,
                  Colors.green,
                  Colors.purple,
                  Colors.orange,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo({
    required String name,
    required String symbol,
    required int thinkingTime,
    required int moves,
    required bool isCurrentPlayer,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlayer ? color : Colors.grey,
          width: 2,
        ),
        boxShadow: isCurrentPlayer
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quân cờ: $symbol',
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thời gian: ${(thinkingTime / 1000).toStringAsFixed(1)}s',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Số nước: $moves',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

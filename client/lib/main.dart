import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/quick_match_waiting_screen.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/local_storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/offline_game_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/offline_game_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';
import 'screens/ai_game_screen.dart';
import 'screens/history_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/opponent_profile_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);
  final apiService = ApiService();
  final wsService = WebSocketService();
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  final chatProvider = ChatProvider();

  // Load app version once for error reports
  String appVersion = '1.0.0';
  try {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version;
  } catch (_) {}

  // Flutter framework error observer
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    apiService.submitErrorReport(
      platform: defaultTargetPlatform.name.toLowerCase(),
      version: appVersion,
      errorType: 'flutter_error',
      message: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
    );
  };

  // Uncaught async/platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    apiService.submitErrorReport(
      platform: defaultTargetPlatform.name.toLowerCase(),
      version: appVersion,
      errorType: 'platform_error',
      message: error.toString(),
      stackTrace: stack.toString(),
    );
    return true;
  };

  runZonedGuarded(
    () {
      runApp(
        MultiProvider(
          providers: [
            Provider<LocalStorageService>.value(value: storage),
            Provider<ApiService>.value(value: apiService),
            Provider<WebSocketService>.value(value: wsService),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(apiService),
            ),
            ChangeNotifierProvider(
              create: (_) => GameProvider(apiService, wsService, chatProvider),
            ),
            ChangeNotifierProvider(
              create: (_) => OfflineGameProvider(storage),
            ),
            ChangeNotifierProvider(
              create: (_) => LeaderboardProvider(),
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      apiService.submitErrorReport(
        platform: defaultTargetPlatform.name.toLowerCase(),
        version: appVersion,
        errorType: 'zone_error',
        message: error.toString(),
        stackTrace: stack.toString(),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'XCaro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
      home: const _AppRoot(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/game': (context) => const GameScreen(),
        '/online_game': (context) => const GameScreen(),
        '/create_room': (context) => const CreateRoomScreen(),
        '/join_room': (context) => const JoinRoomScreen(),
        '/ai_game': (context) => const AiGameScreen(),
        '/history': (context) => const HistoryScreen(),
        '/offline': (context) => const OfflineGameScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/opponent_profile': (context) => const OpponentProfileScreen(),
        '/onboarding': (context) => const OnboardingScreen(forceShow: true),
        '/quick_match': (context) => const QuickMatchWaitingScreen(),
      },
    );
  }
}

/// Root widget that shows splash while AuthProvider initializes,
/// then routes to Home or Login based on authentication state.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'XCaro',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const _OnboardingGate(child: HomeScreen());
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  final Widget child;

  const _OnboardingGate({required this.child});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_complete') ?? false;
    if (mounted) setState(() => _onboardingDone = done);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboardingDone!) {
      return const OnboardingScreen();
    }
    return widget.child;
  }
}

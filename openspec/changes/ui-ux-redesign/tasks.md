# UI/UX Redesign — Tasks

## Group 1: Design System Foundation

- [ ] 1.1 `client/pubspec.yaml`: add `google_fonts: ^6.0.0` to dependencies — expect `flutter pub get` resolves
- [ ] 1.2 `client/lib/theme/app_colors.dart`: create `AppColors` class with all brand/semantic colour constants — expect importable with no warnings
- [ ] 1.3 `client/lib/theme/app_spacing.dart`: create `AppSpacing` with xs/sm/md/lg/xl/radius/radiusLg/radiusFull constants — expect importable
- [ ] 1.4 `client/lib/theme/app_text_styles.dart`: create `AppTextStyles` with `textTheme()` (GoogleFonts.nunitoTextTheme) and named `TextStyle` getters — expect importable
- [ ] 1.5 `client/lib/theme/app_theme.dart`: create `AppTheme.light()` and `AppTheme.dark()` returning full `ThemeData` — expect 0 analyzer issues
- [ ] 1.6 `client/lib/main.dart`: replace `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` with `AppTheme.light()` and `AppTheme.dark()` — expect app boots

## Group 2: Auth Screens Redesign

- [ ] 2.1 `client/lib/screens/login_screen.dart`: add branded header (navy gradient + SVG logo + wordmark), wrap form in `Card`, remove AppBar, add password show/hide toggle — expect screen renders in dark + light mode
- [ ] 2.2 `client/lib/screens/register_screen.dart`: same header + card layout as login, add prefix icons to all fields, remove AppBar — expect screen renders
- [ ] 2.3 `client/test/widget_test.dart`: update smoke test selectors after restructure if login text is the same — expect test still passes

## Group 3: Home / Lobby Redesign

- [ ] 3.1 `client/lib/screens/main_scaffold.dart`: create `_MainScaffold` with `NavigationBar` (4 tabs) and `IndexedStack` — expect tab switching works
- [ ] 3.2 `client/lib/main.dart`: update `/home` route to point to `MainScaffold` — expect navigation unchanged
- [ ] 3.3 `client/lib/screens/home_screen.dart`: refactor into `HomeTab` (stateless about nav), remove AppBar history/leaderboard icons, keep title/theme/help icons — expect compiles
- [ ] 3.4 `client/lib/screens/home_screen.dart`: replace 2-row button layout with 2×2 `_ActionCard` grid — expect 4 cards visible at 360dp width
- [ ] 3.5 `client/lib/widgets/player_stats_card.dart`: create `PlayerStatsCard(stats, user)` widget — expect importable
- [ ] 3.6 `client/lib/screens/home_screen.dart`: replace `primaryContainer` stats row with `PlayerStatsCard` — expect stats display correctly
- [ ] 3.7 `client/lib/screens/home_screen.dart`: replace full-width WS `Container` banner with `AnimatedContainer` chip that hides when connected — expect animation works
- [ ] 3.8 `client/lib/screens/home_screen.dart`: replace `ListTile` game items with `_GameListCard` in `Card` — expect list renders
- [ ] 3.9 `client/lib/screens/history_screen.dart`: use `PlayerStatsCard` for stats row — expect compiles

## Group 4: Game Board Redesign

- [ ] 4.1 `client/lib/widgets/game_board.dart`: add `winningCells` optional parameter to `GameBoard` — expect existing callers unaffected
- [ ] 4.2 `client/lib/widgets/game_board.dart`: replace `Container(color: Colors.amber.shade50)` cell background with `Colors.transparent`; remove `Border.all` — expect cells clear
- [ ] 4.3 `client/lib/widgets/game_board.dart`: add `SvgPicture.asset('assets/images/board.svg')` as `Stack` background behind the grid overlay — expect SVG visible
- [ ] 4.4 `client/lib/widgets/game_board.dart`: create `_StonePainter` `CustomPainter` with radial gradient for black and white stones — expect stones render as gradient circles
- [ ] 4.5 `client/lib/widgets/game_board.dart`: replace `Container(color: color, shape: BoxShape.circle)` stone rendering with `CustomPaint(painter: _StonePainter(...))` — expect stones visible
- [ ] 4.6 `client/lib/widgets/game_board.dart`: remove letter text ("X"/"O") from inside stones — expect stone colour alone identifies player
- [ ] 4.7 `client/lib/widgets/game_board.dart`: add star-point dots at 5 standard positions in empty cells — expect dots visible on empty board
- [ ] 4.8 `client/lib/widgets/game_board.dart`: implement `_WinLinePainter` `CustomPainter` and animated draw when `winningCells` provided — expect gold line appears after win
- [ ] 4.9 `client/lib/screens/game_screen.dart`: pass `winningCells` from `GameProvider` to `GameBoard` when `gameOver` — expect winning line visible

## Group 5: In-Game HUD Redesign

- [ ] 5.1 `client/lib/widgets/player_hud.dart`: create `PlayerHud(playerXName, playerOName, activePlayerId, myId)` with two `_PlayerChip` widgets — expect importable
- [ ] 5.2 `client/lib/widgets/player_hud.dart`: add pulsing `AnimationController` glow for active chip — expect animation runs
- [ ] 5.3 `client/lib/screens/game_screen.dart`: replace `_TurnIndicator` with `PlayerHud` in `OnlineGameView` — expect HUD shows both player names
- [ ] 5.4 `client/lib/screens/game_screen.dart`: replace bottom `Row(chat icon, exit button)` with `FloatingActionButton.small(Icons.menu)` — expect FAB visible
- [ ] 5.5 `client/lib/screens/game_screen.dart`: implement `showModalBottomSheet` game menu with Chat/Đầu hàng/Thoát items — expect sheet opens and actions work
- [ ] 5.6 `client/lib/screens/game_screen.dart`: update `OfflineGameView` to use `PlayerHud` instead of `_TurnIndicator` — expect compiles
- [ ] 5.7 `client/lib/screens/ai_game_screen.dart`: use `PlayerHud` replacing any `_TurnIndicator` usage — expect compiles

## Group 6: Social Screens Redesign

- [ ] 6.1 `client/lib/screens/leaderboard_screen.dart`: replace `ListTile` with `_LeaderboardCard` in `Card` — expect cards render
- [ ] 6.2 `client/lib/screens/leaderboard_screen.dart`: add rank badges (gold/silver/bronze for top 3, grey for rest) — expect badges visible
- [ ] 6.3 `client/lib/screens/leaderboard_screen.dart`: wrap `CircleAvatar` in `Hero(tag: 'avatar-${entry.username}')` — expect hero tag set
- [ ] 6.4 `client/lib/screens/history_screen.dart`: replace `ListTile` with `_HistoryCard` in `Card`; result as `Chip` — expect cards render
- [ ] 6.5 `client/lib/screens/opponent_profile_screen.dart`: add hero `CircleAvatar(radius:40)` with `Hero` tag, gold border for top-10 — expect hero animation fires from leaderboard
- [ ] 6.6 `client/lib/screens/opponent_profile_screen.dart`: add `LinearProgressIndicator` win-rate bar — expect bar shows correct percentage
- [ ] 6.7 `client/lib/screens/opponent_profile_screen.dart`: use `PlayerStatsCard` for stats row — expect compiles

## Group 7: Onboarding Redesign

- [ ] 7.1 `client/lib/screens/onboarding_screen.dart`: add SVG illustrations to each of the 4 slides — expect SVGs render correctly
- [ ] 7.2 `client/lib/screens/onboarding_screen.dart`: apply `AppTextStyles` to slide title and body — expect typography consistent
- [ ] 7.3 `client/lib/screens/onboarding_screen.dart`: replace page indicator with `AnimatedContainer` dots (active = wide pill) — expect indicator animates
- [ ] 7.4 `client/lib/screens/onboarding_screen.dart`: update buttons to use `AppTheme` `ElevatedButton` style — expect button styling consistent

## Group 8: Verification

- [ ] 8.1 `client/`: run `flutter pub get` — expect resolves including `google_fonts`
- [ ] 8.2 `client/`: run `flutter analyze` — expect 0 issues
- [ ] 8.3 `client/`: run `flutter test` — expect all tests pass (update `widget_test.dart` if selectors changed)
- [ ] 8.4 `client/`: run `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 flutter build apk --release` — expect APK builds without error
- [ ] 8.5 Mark all tasks complete in this file

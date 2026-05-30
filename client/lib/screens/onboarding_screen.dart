import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final bool forceShow;

  const OnboardingScreen({super.key, this.forceShow = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _circleAnimController;
  late List<Animation<double>> _circleAnimations;

  @override
  void initState() {
    super.initState();
    _circleAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _circleAnimations = List.generate(5, (i) {
      final start = i * 0.15;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _circleAnimController,
          curve: Interval(start, start + 0.3, curve: Curves.easeIn),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _circleAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    if (page == 2) {
      _circleAnimController.forward(from: 0.0);
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  const _OnboardingPage(
                    icon: Icons.extension,
                    title: 'Cờ Caro là gì?',
                    description:
                        'Cờ Caro (Gomoku) là trò chơi trí tuệ cho 2 người trên bàn cờ 15×15. '
                        'Mỗi người lần lượt đặt quân cờ của mình (X hoặc O). '
                        'Mục tiêu là tạo ra 5 quân liên tiếp trước đối thủ.',
                  ),
                  const _OnboardingPage(
                    icon: Icons.touch_app,
                    title: 'Cách đặt quân',
                    description:
                        'Chạm vào ô trống bất kỳ trên bàn cờ để đặt quân của bạn. '
                        'Bạn chỉ có thể đặt quân khi đến lượt của mình. '
                        'Lượt chơi sẽ luân phiên giữa hai người.',
                  ),
                  _WinConditionPage(circleAnimations: _circleAnimations),
                  _GetStartedPage(onPressed: _complete),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WinConditionPage extends StatelessWidget {
  final List<Animation<double>> circleAnimations;

  const _WinConditionPage({required this.circleAnimations});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 32),
          Text(
            'Điều kiện thắng',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Người đầu tiên tạo được 5 quân liên tiếp theo hàng ngang, '
            'hàng dọc hoặc đường chéo sẽ chiến thắng!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return AnimatedBuilder(
                animation: circleAnimations[i],
                builder: (context, _) => Opacity(
                  opacity: circleAnimations[i].value,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('X',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GetStartedPage extends StatelessWidget {
  final VoidCallback onPressed;

  const _GetStartedPage({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch, size: 80, color: Colors.green),
          const SizedBox(height: 32),
          Text(
            'Bắt đầu thôi!',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn đã sẵn sàng chinh phục bàn cờ! Hãy tạo phòng hoặc thách đấu AI ngay.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.check),
            label: const Text('Đã hiểu!'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

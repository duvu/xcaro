import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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
                    title: 'Cờ Caro là gì?',
                    description:
                        'Cờ Caro (Gomoku) là trò chơi trí tuệ cho 2 người trên bàn cờ 15×15. '
                        'Mỗi người lần lượt đặt quân cờ của mình (X hoặc O). '
                        'Mục tiêu là tạo ra 5 quân liên tiếp trước đối thủ.',
                    svgAsset: 'assets/images/board.svg',
                  ),
                  const _OnboardingPage(
                    title: 'Cách đặt quân',
                    description:
                        'Chạm vào ô trống bất kỳ trên bàn cờ để đặt quân của bạn. '
                        'Bạn chỉ có thể đặt quân khi đến lượt của mình. '
                        'Lượt chơi sẽ luân phiên giữa hai người.',
                    svgAsset: 'assets/images/stone_black.svg',
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
                          ? AppColors.secondary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
  final String title;
  final String description;
  final String? svgAsset;

  const _OnboardingPage({
    required this.title,
    required this.description,
    this.svgAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG illustration if available; fall back to stone icon
          svgAsset != null
              ? SvgPicture.asset(svgAsset!, width: 80, height: 80)
              : const Icon(Icons.extension, size: 80, color: Colors.blue),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            style: AppTextStyles.bodyLarge,
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Điều kiện thắng',
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Người đầu tiên tạo được 5 quân liên tiếp theo hàng ngang, '
            'hàng dọc hoặc đường chéo sẽ chiến thắng!',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
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
                      color: AppColors.stoneBlack,
                      shape: BoxShape.circle,
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch, size: 80, color: Colors.green),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Bắt đầu thôi!',
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bạn đã sẵn sàng chinh phục bàn cờ! Hãy tạo phòng hoặc thách đấu AI ngay.',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.check),
            label: const Text('Đã hiểu!'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl + AppSpacing.md,
                  vertical: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }
}

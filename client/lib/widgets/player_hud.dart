import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Two-player HUD bar replacing the old _TurnIndicator strip.
///
/// Shows two [_PlayerChip] side-by-side with a pulsing glow on the
/// active player's chip.
class PlayerHud extends StatelessWidget {
  /// Player assigned to stone 1 (X / black).
  final User? playerX;

  /// Player assigned to stone 2 (O / white).
  final User? playerO;

  /// ID of the player whose turn it currently is.
  final String? currentTurnId;

  /// The current user's ID (used to label "Bạn").
  final String? myId;

  const PlayerHud({
    super.key,
    required this.playerX,
    required this.playerO,
    required this.currentTurnId,
    this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final xActive = currentTurnId != null && currentTurnId == playerX?.id;
    final oActive = currentTurnId != null && currentTurnId == playerO?.id;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: Theme.of(context)
          .colorScheme
          .surface
          .withValues(alpha: 0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PlayerChip(
            user: playerX,
            isActive: xActive,
            stoneColor: AppColors.stoneBlack,
            label: playerX?.id == myId ? 'Bạn (X)' : (playerX?.username ?? '...'),
          ),
          Icon(
            Icons.swap_horiz,
            color: Colors.grey.shade400,
            size: 20,
          ),
          _PlayerChip(
            user: playerO,
            isActive: oActive,
            stoneColor: AppColors.stoneWhite,
            label: playerO?.id == myId ? 'Bạn (O)' : (playerO?.username ?? '...'),
            reversed: true,
          ),
        ],
      ),
    );
  }
}

// ── PlayerChip ────────────────────────────────────────────────────────────────

class _PlayerChip extends StatefulWidget {
  final User? user;
  final bool isActive;
  final Color stoneColor;
  final String label;
  final bool reversed;

  const _PlayerChip({
    required this.user,
    required this.isActive,
    required this.stoneColor,
    required this.label,
    this.reversed = false,
  });

  @override
  State<_PlayerChip> createState() => _PlayerChipState();
}

class _PlayerChipState extends State<_PlayerChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.stoneColor == AppColors.stoneBlack;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.reversed
          ? [
              Text(widget.label, style: AppTextStyles.bodyMedium),
              const SizedBox(width: AppSpacing.xs),
              _StoneIndicator(
                  stoneColor: widget.stoneColor, isDark: isDark),
            ]
          : [
              _StoneIndicator(
                  stoneColor: widget.stoneColor, isDark: isDark),
              const SizedBox(width: AppSpacing.xs),
              Text(widget.label, style: AppTextStyles.bodyMedium),
            ],
    );

    if (!widget.isActive) return content;

    // Pulsing glow when it's this player's turn
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          color: AppColors.secondary
              .withValues(alpha: 0.08 + 0.12 * _glow.value),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary
                  .withValues(alpha: 0.25 * _glow.value),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
      child: content,
    );
  }
}

class _StoneIndicator extends StatelessWidget {
  final Color stoneColor;
  final bool isDark;

  const _StoneIndicator({required this.stoneColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: stoneColor,
        border: Border.all(
          color: isDark ? Colors.black54 : Colors.grey.shade400,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }
}

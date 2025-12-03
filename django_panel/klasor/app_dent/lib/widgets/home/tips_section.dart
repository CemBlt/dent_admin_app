import 'package:flutter/material.dart';
import '../../models/tip.dart';
import '../../theme/app_theme.dart';

class TipsSection extends StatelessWidget {
  final List<Tip> displayedTips;
  final int currentTipIndex;

  const TipsSection({
    super.key,
    required this.displayedTips,
    required this.currentTipIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (displayedTips.isEmpty) return const SizedBox.shrink();

    final currentTip = displayedTips[currentTipIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tealBlue.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Diş Sağlığı İpuçları',
                    style: AppTheme.headingSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Column(
                  key: ValueKey(currentTip.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTip.title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentTip.content,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildTipIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipIndicators() {
    return Row(
      children: List.generate(
        displayedTips.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          height: 6,
          width: index == currentTipIndex ? 32 : 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(index == currentTipIndex ? 0.9 : 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}


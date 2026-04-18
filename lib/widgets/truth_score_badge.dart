import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Compact badge showing truth score with color coding
class TruthScoreBadge extends StatelessWidget {
  final int score;
  final double fontSize;
  final bool showLabel;

  const TruthScoreBadge({
    super.key,
    required this.score,
    this.fontSize = 12,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    final bgColor = AppColors.scoreBgColor(score);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 10 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(
              'TRUTH SCORE',
              style: TextStyle(
                fontSize: fontSize * 0.75,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '$score',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trend badge showing Improving / Stable / Declining
class TrendBadge extends StatelessWidget {
  final String trend;

  const TrendBadge({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (trend.toLowerCase()) {
      case 'improving':
        color = AppColors.primary;
        icon = Icons.trending_up;
        break;
      case 'declining':
        color = AppColors.error;
        icon = Icons.trending_down;
        break;
      default:
        color = AppColors.warning;
        icon = Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            trend,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Score indicator row for dashboard metrics
class ScoreIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  const ScoreIndicator({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? AppColors.textTertiary, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

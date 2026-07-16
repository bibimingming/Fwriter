import 'package:flutter/material.dart';

/// 字数统计徽章组件
/// 用于显示当前章节字数、目标进度等
class WordCountBadge extends StatelessWidget {
  final int wordCount;
  final int? dailyGoal;
  final bool showGoal;

  const WordCountBadge({
    super.key,
    required this.wordCount,
    this.dailyGoal,
    this.showGoal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.text_fields, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          _formatCount(wordCount),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (showGoal && dailyGoal != null && dailyGoal! > 0) ...[
          const SizedBox(width: 4),
          Text(
            '/ ${_formatCount(dailyGoal!)}',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 6),
          // 进度条
          SizedBox(
            width: 60,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (wordCount / dailyGoal!).clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  wordCount >= dailyGoal!
                      ? colorScheme.primary
                      : colorScheme.tertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${((wordCount / dailyGoal!) * 100).clamp(0, 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: wordCount >= dailyGoal!
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/novel_provider.dart';
import '../models/novel.dart';
import '../widgets/chart_widgets.dart';
import '../utils/word_counter.dart';
import '../utils/frequency_analyzer.dart';

/// 统计看板页面
/// 展示字数趋势、章节分布、总览数据、高频词分析、的得地检查
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final statsProv = context.read<StatisticsProvider>();
      final novel = context.read<NovelProvider>().currentNovel;
      if (novel != null) statsProv.refresh(novel);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('统计看板'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '总览'),
            Tab(text: '字数趋势'),
            Tab(text: '高频词'),
          ],
        ),
      ),
      body: Consumer2<StatisticsProvider, NovelProvider>(
        builder: (context, statsProv, novelProv, child) {
          final novel = novelProv.currentNovel;
          if (novel == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('请先打开一部小说',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, colorScheme, statsProv, novelProv),
              _buildTrendTab(context, colorScheme, statsProv, novelProv),
              _buildFrequencyTab(context, colorScheme, statsProv, novelProv),
            ],
          );
        },
      ),
    );
  }

  // ========== 总览 Tab ==========
  Widget _buildOverviewTab(
    BuildContext context,
    ColorScheme colorScheme,
    StatisticsProvider statsProv,
    NovelProvider novelProv,
  ) {
    final novel = novelProv.currentNovel!;
    final chapterCount = novel.chapters.length;
    final totalWords = novel.totalWordCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总览卡片
          _buildStatCard(
            colorScheme: colorScheme,
            children: [
              _StatItem(
                icon: Icons.article_outlined,
                label: '总章节',
                value: '$chapterCount',
                colorScheme: colorScheme,
              ),
              _StatItem(
                icon: Icons.text_fields,
                label: '总字数',
                value: _formatCount(totalWords),
                colorScheme: colorScheme,
              ),
              _StatItem(
                icon: Icons.trending_up,
                label: '日均字数',
                value: _formatCount(statsProv.averageDailyWords),
                colorScheme: colorScheme,
              ),
              _StatItem(
                icon: Icons.local_fire_department,
                label: '单日最高',
                value: _formatCount(statsProv.maxDailyWordCount),
                colorScheme: colorScheme,
              ),
              _StatItem(
                icon: Icons.calendar_today,
                label: '写作天数',
                value: '${statsProv.writingDays}',
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 章节字数分布
          Text(
            '章节字数分布',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: _buildChapterDistribution(statsProv, colorScheme, novel: novel),
          ),

          // 的得地统计
          const SizedBox(height: 20),
          Text(
            '的得地使用统计',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _buildDeDeDiStats(novel, colorScheme),
        ],
      ),
    );
  }

  Widget _buildChapterDistribution(
    StatisticsProvider statsProv,
    ColorScheme colorScheme, {
    required Novel novel,
  }) {
    final distribution = statsProv.getChapterDistribution(novel);
    if (distribution.isEmpty) {
      return Center(
        child: Text('暂无数据', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    final maxVal = distribution.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) {
      return Center(
        child: Text('暂无数据', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    final keys = distribution.map((e) => e.key).toList();
    final values = distribution.map((e) => e.value).toList();

    // 最多显示20个章节
    final displayCount = keys.length > 20 ? 20 : keys.length;
    final barData = List.generate(displayCount, (i) {
      final colorTween = (values[i] / maxVal).clamp(0.0, 1.0);
      return BarChartData(
        label: '${i + 1}',
        value: values[i].toDouble(),
        color: Color.lerp(
          colorScheme.primaryContainer,
          colorScheme.primary,
          colorTween,
        ),
      );
    });

    return BarChart(
      data: barData,
      barColor: colorScheme.primary,
      gridColor: colorScheme.outlineVariant,
      barWidth: keys.length > 20 ? 16 : 24,
      maxBarHeight: 160,
      labelBuilder: (i) => keys.length > 12 ? '' : '第${keys[i]}章',
    );
  }

  Widget _buildDeDeDiStats(dynamic novel, ColorScheme colorScheme) {
    final deCount = WordCounter.countDeDiDe(novel.chapters
        .map((c) => c.content)
        .join('\n'));
    final totalChars = WordCounter.countChineseChars(
        novel.chapters.map((c) => c.content).join('\n'));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _DeItem(label: '的', count: deCount['的'] ?? 0,
                total: totalChars, colorScheme: colorScheme),
            const SizedBox(width: 16),
            _DeItem(label: '得', count: deCount['得'] ?? 0,
                total: totalChars, colorScheme: colorScheme),
            const SizedBox(width: 16),
            _DeItem(label: '地', count: deCount['地'] ?? 0,
                total: totalChars, colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  // ========== 字数趋势 Tab ==========
  Widget _buildTrendTab(
    BuildContext context,
    ColorScheme colorScheme,
    StatisticsProvider statsProv,
    NovelProvider novelProv,
  ) {
    return Column(
      children: [
        // 周期筛选
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _PeriodChip(
                label: '7天',
                selected: statsProv.trendPeriod == '7d',
                onTap: () => statsProv.setTrendPeriod('7d'),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: '30天',
                selected: statsProv.trendPeriod == '30d',
                onTap: () => statsProv.setTrendPeriod('30d'),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: '全部',
                selected: statsProv.trendPeriod == 'all',
                onTap: () => statsProv.setTrendPeriod('all'),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),

        // 趋势图
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTrendChart(statsProv, colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(StatisticsProvider statsProv, ColorScheme colorScheme) {
    final trendData = statsProv.getWordCountTrend();
    if (trendData.isEmpty) {
      return Center(
        child: Text('暂无写作数据', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    final points = trendData.map((r) {
      final day = '${r.date.month}/${r.date.day}';
      return LineChartPoint(label: day, value: r.wordCount.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '字数趋势',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChartWidget(
            points: points,
            lineColor: colorScheme.primary,
            fillColor: colorScheme.primary.withValues(alpha: 0.15),
            pointColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // ========== 高频词 Tab ==========
  Widget _buildFrequencyTab(
    BuildContext context,
    ColorScheme colorScheme,
    StatisticsProvider statsProv,
    NovelProvider novelProv,
  ) {
    final novel = novelProv.currentNovel;
    if (novel == null) return const SizedBox();

    final allContent = novel.chapters.map((c) => c.content).join('\n');
    final topWords = FrequencyAnalyzer.getTopWords(allContent);
    final overused = FrequencyAnalyzer.getOverusedWords(allContent);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 高频词前50
          Text(
            '高频词 Top 50',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topWords.take(30).map((e) {
                  final frequency = e.count;
                  final opacity = (frequency / topWords.first.count).clamp(0.3, 1.0);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: opacity * 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${e.word} ($frequency)',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 过度使用词警告
          if (overused.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: colorScheme.error),
                const SizedBox(width: 6),
                Text(
                  '过度使用词提醒',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: overused.take(15).map((msg) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        msg,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========== 通用组件 ==========

  Widget _buildStatCard({
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: children,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}w';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

// ========== 子组件 ==========

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DeItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final ColorScheme colorScheme;

  const _DeItem({
    required this.label,
    required this.count,
    required this.total,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) * 10000 : 0.0;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count 次',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}‱',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

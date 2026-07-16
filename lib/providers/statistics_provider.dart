import 'package:flutter/foundation.dart';
import '../models/novel.dart';
import '../models/statistics.dart';
import '../utils/word_counter.dart';
import '../utils/frequency_analyzer.dart';

/// 全文统计看板状态管理
class StatisticsProvider extends ChangeNotifier {

  NovelStatistics? _statistics;
  String _trendPeriod = '7天'; // 7天 / 30天 / 全部

  // Getters
  NovelStatistics? get statistics => _statistics;
  String get trendPeriod => _trendPeriod;

  /// 加载统计数据
  void loadStatistics(Novel novel) {
    // 从章节字数构建每日记录
    final records = <DailyRecord>[];
    for (int i = 0; i < novel.chapters.length; i++) {
      final wordCount = novel.chapters[i].content.replaceAll(RegExp(r'\s+'), '').length;
      if (wordCount > 0) {
        records.add(DailyRecord(
          date: DateTime.now().subtract(Duration(days: novel.chapters.length - i - 1)),
          wordCount: wordCount,
        ));
      }
    }
    _statistics = NovelStatistics(dailyRecords: records, totalWritingDays: records.length);
    notifyListeners();
  }

  /// 设置趋势周期
  void setTrendPeriod(String period) {
    _trendPeriod = period;
    notifyListeners();
  }

  /// 获取字数趋势数据（用于折线图）
  List<DailyRecord> getWordCountTrend() {
    if (_statistics == null) return [];

    final records = _statistics!.dailyRecords;
    if (records.isEmpty) return [];

    // 按周期过滤
    final now = DateTime.now();
    final filtered = records.where((r) {
      switch (_trendPeriod) {
        case '7天':
          return now.difference(r.date).inDays <= 7;
        case '30天':
          return now.difference(r.date).inDays <= 30;
        default:
          return true;
      }
    }).toList();

    // 按日期排序
    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  /// 获取章节字数分布（用于柱状图）
  List<MapEntry<String, int>> getChapterDistribution(Novel novel) {
    if (novel.chapters.isEmpty) return [];
    return novel.chapters
        .map((c) => MapEntry(c.title.isEmpty ? '未命名章节' : c.title,
            c.content.replaceAll(RegExp(r'\s+'), '').length))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  /// 刷新统计（重新计算）
  void refresh(Novel novel) {
    loadStatistics(novel);
  }

  /// 获取总字数
  int get totalWordCount => _statistics?.totalWordCount ?? 0;

  /// 获取章节数（从 NovelStatistics 计算）
  int get chapterCount => _statistics?.dailyRecords.length ?? 0;

  /// 获取日均字数
  int get averageDailyWords {
    if (_statistics == null) return 0;
    return _statistics!.averageDailyWords.round();
  }

  /// 获取单日最高字数
  int get maxDailyWordCount {
    if (_statistics == null) return 0;
    return _statistics!.maxDailyWordCount;
  }

  /// 获取写作天数
  int get writingDays {
    if (_statistics == null) return 0;
    return _statistics!.totalWritingDays;
  }

  /// 分析高频词
  Map<String, int> analyzeFrequencies(Novel novel) {
    final allContent =
        novel.chapters.map((c) => c.content).join('\n');
    final words = FrequencyAnalyzer.getTopWords(allContent);
    return {for (final w in words) w.word: w.count};
  }

  /// 获取全文字数统计详情
  Map<String, int> getFullWordCount(Novel novel) {
    final allContent =
        novel.chapters.map((c) => c.content).join('\n');
    final result = <String, int>{};
    result['中文字数'] = WordCounter.countChineseChars(allContent);
    result['总字符数'] = WordCounter.countAllChars(allContent);
    result['段落数'] = WordCounter.countParagraphs(allContent);
    return result;
  }

  /// 获取"的得地"统计
  Map<String, int> getDeDeDiStats(Novel novel) {
    final allContent =
        novel.chapters.map((c) => c.content).join('\n');
    return WordCounter.countDeDiDe(allContent);
  }
}

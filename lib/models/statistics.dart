class DailyRecord {
  final DateTime date;
  final int wordCount;
  final int sessionCount; // 写作段数

  DailyRecord({
    required this.date,
    required this.wordCount,
    this.sessionCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'wordCount': wordCount,
        'sessionCount': sessionCount,
      };

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
        date: DateTime.parse(json['date'] as String),
        wordCount: json['wordCount'] as int,
        sessionCount: json['sessionCount'] as int? ?? 0,
      );
}

class NovelStatistics {
  final List<DailyRecord> dailyRecords;
  final DateTime firstWritingDate;
  final int totalWritingDays;

  NovelStatistics({
    required this.dailyRecords,
    DateTime? firstWritingDate,
    this.totalWritingDays = 0,
  }) : firstWritingDate = firstWritingDate ?? DateTime.now();

  int get totalWordCount {
    int sum = 0;
    for (final r in dailyRecords) {
      sum += r.wordCount;
    }
    return sum;
  }

  double get averageDailyWords =>
      dailyRecords.isEmpty ? 0 : totalWordCount / dailyRecords.length;

  int get maxDailyWordCount {
    if (dailyRecords.isEmpty) return 0;
    int max = 0;
    for (final r in dailyRecords) {
      if (r.wordCount > max) max = r.wordCount;
    }
    return max;
  }

  /// 获取最近 N 天的记录
  List<DailyRecord> getRecentDays(int days) {
    if (dailyRecords.isEmpty) return [];
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return dailyRecords.where((r) => r.date.isAfter(cutoff)).toList();
  }

  Map<String, dynamic> toJson() => {
        'dailyRecords': dailyRecords.map((r) => r.toJson()).toList(),
        'firstWritingDate': firstWritingDate.toIso8601String(),
        'totalWritingDays': totalWritingDays,
      };

  factory NovelStatistics.fromJson(Map<String, dynamic> json) =>
      NovelStatistics(
        dailyRecords: (json['dailyRecords'] as List<dynamic>?)
                ?.map((r) => DailyRecord.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        firstWritingDate:
            DateTime.parse(json['firstWritingDate'] as String),
        totalWritingDays: json['totalWritingDays'] as int? ?? 0,
      );
}

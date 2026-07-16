import 'chapter.dart';

class Novel {
  String title;
  String author;
  List<Chapter> chapters;
  int dailyGoal; // 每日目标字数
  DateTime createdAt;
  DateTime updatedAt;
  String filePath; // .novel 文件路径

  Novel({
    required this.title,
    this.author = '',
    List<Chapter>? chapters,
    this.dailyGoal = 2000,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.filePath = '',
  })  : chapters = chapters ?? [Chapter(title: '第一章')],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get totalWordCount {
    int total = 0;
    for (final ch in chapters) {
      total += ch.wordCount;
    }
    return total;
  }

  int get chapterCount => chapters.length;

  Novel copyWith({
    String? title,
    String? author,
    List<Chapter>? chapters,
    int? dailyGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? filePath,
  }) {
    return Novel(
      title: title ?? this.title,
      author: author ?? this.author,
      chapters: chapters ?? this.chapters,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'dailyGoal': dailyGoal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory Novel.fromJson(Map<String, dynamic> json) {
    final chapterList = (json['chapters'] as List<dynamic>?)
            ?.map((c) => Chapter.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    return Novel(
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      chapters: chapterList,
      dailyGoal: json['dailyGoal'] as int? ?? 2000,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

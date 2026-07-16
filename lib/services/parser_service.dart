import '../models/novel.dart';
import '../models/chapter.dart';

/// .novel 文件解析与序列化服务
///
/// 文件格式：
/// ---
/// title: 我的小说
/// author: 作者
/// dailyGoal: 2000
/// ---
/// ## 第一章
/// 内容...
/// ---
/// ## 第二章
/// 内容...
class ParserService {
  /// 将 Novel 对象序列化为 .novel 格式字符串
  static String serialize(Novel novel) {
    final buffer = StringBuffer();
    // YAML 头部
    buffer.writeln('---');
    buffer.writeln('title: ${novel.title}');
    buffer.writeln('author: ${novel.author}');
    buffer.writeln('dailyGoal: ${novel.dailyGoal}');
    buffer.writeln('createdAt: ${novel.createdAt.toIso8601String()}');
    buffer.writeln('updatedAt: ${novel.updatedAt.toIso8601String()}');
    buffer.writeln('---');
    buffer.writeln();

    // 章节正文
    for (int i = 0; i < novel.chapters.length; i++) {
      final chapter = novel.chapters[i];
      buffer.writeln('## ${chapter.title}');
      buffer.writeln();
      if (chapter.content.isNotEmpty) {
        buffer.writeln(chapter.content);
      }
      buffer.writeln();
      if (i < novel.chapters.length - 1) {
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// 将 .novel 格式字符串解析为 Novel 对象
  static Novel deserialize(String data, {String filePath = ''}) {
    String title = '未命名作品';
    String author = '';
    int dailyGoal = 2000;
    DateTime? createdAt;
    DateTime? updatedAt;

    // 解析 YAML 头部
    final headerMatch = RegExp(r'^---\n(.*?)\n---', dotAll: true).firstMatch(data);
    if (headerMatch != null) {
      final header = headerMatch.group(1)!;
      for (final line in header.split('\n')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex == -1) continue;
        final key = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        switch (key) {
          case 'title':
            title = value;
            break;
          case 'author':
            author = value;
            break;
          case 'dailyGoal':
            dailyGoal = int.tryParse(value) ?? 2000;
            break;
          case 'createdAt':
            createdAt = DateTime.tryParse(value);
            break;
          case 'updatedAt':
            updatedAt = DateTime.tryParse(value);
            break;
        }
      }
      // 移除头部
      data = data.substring(headerMatch.end);
    }

    // 解析章节
    final List<Chapter> chapters = [];
    // 用 ## 标题 + --- 分隔符分割
    final chapterPattern = RegExp(r'^## (.+?)$\n(.*?)(?=\n---|\Z)', dotAll: true, multiLine: true);
    final matches = chapterPattern.allMatches(data);

    if (matches.isEmpty) {
      // 整个内容作为一章
      chapters.add(Chapter(
        title: title,
        content: data.trim(),
      ));
    } else {
      for (final match in matches) {
        final chapterTitle = match.group(1)?.trim() ?? '未命名章节';
        final chapterContent = match.group(2)?.trim() ?? '';
        chapters.add(Chapter(
          title: chapterTitle,
          content: chapterContent,
        ));
      }
    }

    return Novel(
      title: title,
      author: author,
      chapters: chapters,
      dailyGoal: dailyGoal,
      createdAt: createdAt,
      updatedAt: updatedAt,
      filePath: filePath,
    );
  }

  /// 获取 .novel 文件的默认存储目录名
  static String get novelsDirectoryName => 'Novels';
}

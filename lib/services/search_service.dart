import '../models/novel.dart';
import '../models/chapter.dart';

class SearchResult {
  final int chapterIndex;
  final String chapterTitle;
  final String matchedText;
  final int matchPosition; // 在章节内容中的位置
  final int lineNumber; // 所在行号（粗略）

  SearchResult({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.matchedText,
    required this.matchPosition,
    required this.lineNumber,
  });
}

class SearchService {
  /// 全文搜索关键词，返回所有匹配结果
  static List<SearchResult> search(Novel novel, String query,
      {bool caseSensitive = false, bool useRegex = false}) {
    if (query.trim().isEmpty) return [];
    final List<SearchResult> results = [];

    final pattern = useRegex
        ? RegExp(query, caseSensitive: caseSensitive)
        : RegExp(RegExp.escape(query), caseSensitive: caseSensitive);

    for (int i = 0; i < novel.chapters.length; i++) {
      final chapter = novel.chapters[i];
      final matches = pattern.allMatches(chapter.content);
      for (final match in matches) {
        // 计算行号（粗略）
        final textBefore = chapter.content.substring(0, match.start);
        final lineNumber = '\n'.allMatches(textBefore).length + 1;

        // 提取上下文
        final contextStart = (match.start - 20).clamp(0, match.start);
        final contextEnd =
            (match.end + 20).clamp(match.end, chapter.content.length);
        String context = chapter.content.substring(contextStart, contextEnd);
        if (contextStart > 0) context = '...$context';
        if (contextEnd < chapter.content.length) context = '$context...';

        results.add(SearchResult(
          chapterIndex: i,
          chapterTitle: chapter.title,
          matchedText: context,
          matchPosition: match.start,
          lineNumber: lineNumber,
        ));
      }
    }

    return results;
  }

  /// 替换单个匹配
  static Chapter replaceFirst(
      Chapter chapter, String query, String replacement,
      {bool caseSensitive = false}) {
    final pattern = RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
    return chapter.copyWith(
      content: chapter.content.replaceFirst(pattern, replacement),
    );
  }

  /// 替换全部匹配
  static Chapter replaceAll(Chapter chapter, String query, String replacement,
      {bool caseSensitive = false}) {
    final pattern = RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
    return chapter.copyWith(
      content: chapter.content.replaceAll(pattern, replacement),
    );
  }

  /// 统计关键词出现次数
  static int countOccurrences(Novel novel, String query,
      {bool caseSensitive = false}) {
    final pattern = RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
    int count = 0;
    for (final chapter in novel.chapters) {
      count += pattern.allMatches(chapter.content).length;
    }
    return count;
  }
}

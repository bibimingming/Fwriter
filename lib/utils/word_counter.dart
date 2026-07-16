class WordCounter {
  /// 统计纯中文字数（不含空格、标点、换行）
  static int countChineseChars(String text) {
    return text.replaceAll(RegExp(r'[^\u4e00-\u9fff]'), '').length;
  }

  /// 统计总字符数（含标点，不含空格换行）
  static int countAllChars(String text) {
    return text.replaceAll(RegExp(r'\s'), '').length;
  }

  /// 统计段落数
  static int countParagraphs(String text) {
    if (text.trim().isEmpty) return 0;
    return text
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .length;
  }

  /// 统计"的/地/得"使用次数
  static Map<String, int> countDeDiDe(String text) {
    return {
      '的': '的'.allMatches(text).length,
      '地': '地'.allMatches(text).length,
      '得': '得'.allMatches(text).length,
    };
  }

  /// 统计标点符号数
  static int countPunctuation(String text) {
    return text.replaceAll(RegExp(r'[^\u3000-\u303f\uff00-\uffef[:punct:]]'), '')
        .length;
  }
}

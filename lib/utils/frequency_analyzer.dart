class FrequencyAnalyzer {
  /// 停用词（中文常见虚词，排除干扰）
  static const _stopWords = <String>{
    '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一',
    '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着',
    '没有', '看', '好', '自己', '这', '他', '她', '它', '们', '那', '为',
    '与', '之', '及', '被', '把', '让', '从', '对', '以', '而', '但', '所',
    '如', '若', '其', '中', '或', '还', '能', '可', '将', '已', '吗', '呢',
    '啊', '吧', '嗯', '哦', '嘛', '呵', '呀', '哇', '哟', '哈', '嘿',
  };

  /// 获取全文高频词 Top N
  static List<WordFrequency> getTopWords(String text, {int topN = 50}) {
    // 只保留中文字符，分词按单字处理+双字组合
    final clean = text.replaceAll(RegExp(r'[^\u4e00-\u9fff]'), '');
    if (clean.isEmpty) return [];

    // 单字频率
    final Map<String, int> freq = {};
    for (int i = 0; i < clean.length; i++) {
      final char = clean[i];
      if (char.trim().isEmpty) continue;
      freq[char] = (freq[char] ?? 0) + 1;
    }

    // 双字词频率（滑动窗口）
    for (int i = 0; i < clean.length - 1; i++) {
      final bigram = '${clean[i]}${clean[i + 1]}';
      if (bigram.trim().length == 2) {
        freq[bigram] = (freq[bigram] ?? 0) + 1;
      }
    }

    // 过滤停用词，排序取 Top
    final sorted = freq.entries
        .where((e) => !_stopWords.contains(e.key) && e.key.length <= 2)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(topN)
        .map((e) => WordFrequency(word: e.key, count: e.value))
        .toList();
  }

  /// 获取当前章节过度使用警告
  static List<String> getOverusedWords(String text, {int threshold = 3}) {
    final topWords = getTopWords(text, topN: 10);
    return topWords
        .where((w) => w.count >= threshold && w.word.length == 1)
        .map((w) => '「${w.word}」出现了 ${w.count} 次')
        .toList();
  }
}

class WordFrequency {
  final String word;
  final int count;
  WordFrequency({required this.word, required this.count});
}

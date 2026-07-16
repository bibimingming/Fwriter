import 'package:flutter/foundation.dart';
import '../services/search_service.dart';
import '../models/novel.dart';
import '../utils/word_counter.dart';
import '../utils/frequency_analyzer.dart';

/// 搜索功能状态管理
class SearchProvider extends ChangeNotifier {

  String _query = '';
  String _replaceText = '';
  bool _useRegex = false;
  bool _matchCase = false;
  List<SearchResult> _results = [];
  bool _isSearching = false;
  int _totalReplaceCount = 0;
  int _selectedResultIndex = -1;

  // 高频词分析
  Map<String, int> _topKeywords = {};
  List<String> _overusedWords = [];

  // Getters
  String get query => _query;
  String get replaceText => _replaceText;
  bool get useRegex => _useRegex;
  bool get matchCase => _matchCase;
  List<SearchResult> get results => _results;
  bool get isSearching => _isSearching;
  int get totalReplaceCount => _totalReplaceCount;
  int get selectedResultIndex => _selectedResultIndex;
  Map<String, int> get topKeywords => _topKeywords;
  List<String> get overusedWords => _overusedWords;

  /// 设置搜索关键词
  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  /// 设置替换文本
  void setReplaceText(String value) {
    _replaceText = value;
    notifyListeners();
  }

  /// 切换正则模式
  void toggleRegex() {
    _useRegex = !_useRegex;
    notifyListeners();
  }

  /// 切换大小写敏感
  void toggleMatchCase() {
    _matchCase = !_matchCase;
    notifyListeners();
  }

  /// 执行搜索
  void search(Novel novel) {
    if (_query.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _selectedResultIndex = -1;
    notifyListeners();

    // 模拟异步以更新 UI
    Future.microtask(() {
      _results = SearchService.search(novel, _query,
          useRegex: _useRegex, caseSensitive: _matchCase);
      _isSearching = false;
      notifyListeners();
    });
  }

  /// 选中某个结果
  void selectResult(int index) {
    _selectedResultIndex = index;
    notifyListeners();
  }

  /// 替换单个
  void replaceSingle(Novel novel, int chapterIndex, int position, String oldText) {
    final chapter = novel.chapters[chapterIndex];
    final before = chapter.content.substring(0, position);
    final after = chapter.content.substring(position + oldText.length);
    chapter.content = before + _replaceText + after;
    // 重新搜索
    search(novel);
    notifyListeners();
  }

  /// 替换全部
  void replaceAll(Novel novel) {
    int count = 0;
    for (int i = 0; i < novel.chapters.length; i++) {
      final original = novel.chapters[i].content;
      final updated = SearchService.replaceAll(novel.chapters[i], _query, _replaceText,
          caseSensitive: _matchCase);
      if (updated.content != original) {
        final pattern = RegExp(
          _useRegex ? _query : RegExp.escape(_query),
          caseSensitive: _matchCase,
        );
        count += pattern.allMatches(original).length;
      }
    }
    _totalReplaceCount = count;
    _results = [];
    notifyListeners();
  }

  /// 分析高频词
  void analyzeFrequencies(Novel novel) {
    final allContent =
        novel.chapters.map((c) => c.content).join('\n');
    final words = FrequencyAnalyzer.getTopWords(allContent);
    _topKeywords = {for (final w in words) w.word: w.count};
    _overusedWords = FrequencyAnalyzer.getOverusedWords(allContent);
    notifyListeners();
  }

  /// 获取"的得地"统计
  Map<String, int> analyzeDeDeDi(Novel novel) {
    final allContent =
        novel.chapters.map((c) => c.content).join('\n');
    return WordCounter.countDeDiDe(allContent);
  }

  /// 清空搜索
  void clear() {
    _query = '';
    _replaceText = '';
    _results = [];
    _selectedResultIndex = -1;
    _totalReplaceCount = 0;
    notifyListeners();
  }
}

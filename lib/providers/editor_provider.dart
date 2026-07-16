import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/search_service.dart';
import '../models/novel.dart';
import '../models/chapter.dart';

/// 编辑器状态管理
/// 管理编辑状态、番茄钟、分屏模式等
class EditorProvider extends ChangeNotifier {
  // 番茄钟状态
  Timer? _pomodoroTimer;
  int _pomodoroSecondsRemaining = 0;
  int _pomodoroTotalSeconds = 25 * 60; // 默认25分钟
  bool _pomodoroRunning = false;
  bool _pomodoroBreak = false;

  // 分屏状态
  bool _isSplitMode = false;
  double _splitRatio = 0.5;
  int _splitLeftChapterIndex = 0;
  int _splitRightChapterIndex = 0;

  // 大纲状态
  bool _isOutlineVisible = false;

  // 写作统计（实时）
  int _sessionWordCount = 0;
  int _sessionStartWordCount = 0;
  DateTime _sessionStartTime = DateTime.now();
  Duration _writingDuration = Duration.zero;
  Timer? _writingTimer;

  // Getters
  int get pomodoroSecondsRemaining => _pomodoroSecondsRemaining;
  int get pomodoroTotalSeconds => _pomodoroTotalSeconds;
  bool get pomodoroRunning => _pomodoroRunning;
  bool get pomodoroBreak => _pomodoroBreak;
  bool get isSplitMode => _isSplitMode;
  double get splitRatio => _splitRatio;
  int get splitLeftChapterIndex => _splitLeftChapterIndex;
  int get splitRightChapterIndex => _splitRightChapterIndex;
  bool get isOutlineVisible => _isOutlineVisible;
  int get sessionWordCount => _sessionWordCount;
  Duration get writingDuration => _writingDuration;

  String get pomodoroDisplay {
    final minutes = _pomodoroSecondsRemaining ~/ 60;
    final seconds = _pomodoroSecondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get writingDurationDisplay {
    final hours = _writingDuration.inHours;
    final minutes = _writingDuration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}时${minutes}分';
    }
    return '${minutes}分';
  }

  /// === 番茄钟 ===

  /// 设置番茄钟时长（分钟）
  void setPomodoroDuration(int minutes) {
    if (!_pomodoroRunning) {
      _pomodoroTotalSeconds = minutes * 60;
      _pomodoroSecondsRemaining = _pomodoroTotalSeconds;
      notifyListeners();
    }
  }

  /// 开始番茄钟
  void startPomodoro() {
    if (_pomodoroRunning) return;
    if (_pomodoroSecondsRemaining <= 0) {
      _pomodoroSecondsRemaining = _pomodoroTotalSeconds;
    }
    _pomodoroRunning = true;
    _pomodoroBreak = false;
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pomodoroSecondsRemaining--;
      if (_pomodoroSecondsRemaining <= 0) {
        _pomodoroRunning = false;
        _pomodoroBreak = true;
        _pomodoroTimer?.cancel();
        _pomodoroTimer = null;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// 暂停番茄钟
  void pausePomodoro() {
    _pomodoroRunning = false;
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;
    notifyListeners();
  }

  /// 重置番茄钟
  void resetPomodoro() {
    pausePomodoro();
    _pomodoroSecondsRemaining = _pomodoroTotalSeconds;
    _pomodoroBreak = false;
    notifyListeners();
  }

  /// === 分屏模式 ===

  /// 切换分屏模式
  void toggleSplitMode() {
    _isSplitMode = !_isSplitMode;
    notifyListeners();
  }

  /// 设置分屏比例
  void setSplitRatio(double ratio) {
    _splitRatio = ratio.clamp(0.2, 0.8);
    notifyListeners();
  }

  /// 设置左屏章节
  void setSplitLeftChapter(int index) {
    _splitLeftChapterIndex = index;
    notifyListeners();
  }

  /// 设置右屏章节
  void setSplitRightChapter(int index) {
    _splitRightChapterIndex = index;
    notifyListeners();
  }

  /// === 大纲模式 ===

  /// 切换大纲显示
  void toggleOutline() {
    _isOutlineVisible = !_isOutlineVisible;
    notifyListeners();
  }

  /// === 写作计时 ===

  /// 开始写作计时
  void startWritingSession(int currentWordCount) {
    _sessionStartWordCount = currentWordCount;
    _sessionWordCount = 0;
    _sessionStartTime = DateTime.now();
    _writingDuration = Duration.zero;

    _writingTimer?.cancel();
    _writingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _writingDuration = DateTime.now().difference(_sessionStartTime);
      notifyListeners();
    });
    notifyListeners();
  }

  /// 更新写作字数
  void updateSessionWordCount(int currentWordCount) {
    _sessionWordCount =
        currentWordCount - _sessionStartWordCount;
    if (_sessionWordCount < 0) _sessionWordCount = 0;
    notifyListeners();
  }

  /// 结束写作计时
  void endWritingSession() {
    _writingTimer?.cancel();
    _writingTimer = null;
    notifyListeners();
  }

  /// === 搜索 ===

  /// 搜索关键词（使用静态方法）
  List<SearchResult> searchInNovel(Novel novel, String query,
      {bool useRegex = false, bool matchCase = false}) {
    return SearchService.search(novel, query,
        useRegex: useRegex, caseSensitive: matchCase);
  }

  /// 替换文本（返回找到的替换次数）
  int replaceInNovel(Novel novel, String search, String replace,
      {bool useRegex = false, bool matchCase = false}) {
    int replacedCount = 0;
    for (int i = 0; i < novel.chapters.length; i++) {
      final original = novel.chapters[i].content;
      final updated = SearchService.replaceAll(novel.chapters[i], search, replace,
          caseSensitive: matchCase);
      if (updated.content != original) {
        // 统计替换数量
        final pattern = RegExp(
          useRegex ? search : RegExp.escape(search),
          caseSensitive: matchCase,
        );
        replacedCount += pattern.allMatches(original).length;
      }
    }
    notifyListeners();
    return replacedCount;
  }

  /// 统计关键词出现次数
  int countKeyword(Novel novel, String keyword) {
    return SearchService.countOccurrences(novel, keyword);
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _writingTimer?.cancel();
    super.dispose();
  }
}

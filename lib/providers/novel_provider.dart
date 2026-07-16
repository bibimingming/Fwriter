import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/novel.dart';
import '../models/chapter.dart';
import '../models/statistics.dart';
import '../services/parser_service.dart';
import '../services/file_service.dart';

/// 小说数据状态管理
class NovelProvider extends ChangeNotifier {
  Novel? _currentNovel;
  int _currentChapterIndex = 0;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  String? _errorMessage;
  List<Novel> _recentNovels = [];

  // Getters
  Novel? get currentNovel => _currentNovel;
  int get currentChapterIndex => _currentChapterIndex;
  bool get isLoading => _isLoading;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  String? get errorMessage => _errorMessage;
  List<Novel> get recentNovels => _recentNovels;

  Chapter? get currentChapter {
    if (_currentNovel == null) return null;
    if (_currentChapterIndex < 0 ||
        _currentChapterIndex >= _currentNovel!.chapters.length) {
      return null;
    }
    return _currentNovel!.chapters[_currentChapterIndex];
  }

  int get totalWordCount => _currentNovel?.totalWordCount ?? 0;
  int get chapterCount => _currentNovel?.chapters.length ?? 0;

  /// 加载最近打开的小说列表
  Future<void> loadRecentNovels() async {
    try {
      final files = await FileService.listNovelFiles();
      final novels = <Novel>[];
      for (final file in files) {
        final novel = await FileService.loadNovel(file.path);
        if (novel != null) novels.add(novel);
      }
      _recentNovels = novels;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载小说列表失败: $e';
      notifyListeners();
    }
  }

  /// 打开小说
  Future<bool> openNovel(String filePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentNovel = await FileService.loadNovel(filePath);
      _currentChapterIndex = 0;
      _hasUnsavedChanges = false;
      _isLoading = false;
      notifyListeners();
      return _currentNovel != null;
    } catch (e) {
      _errorMessage = '打开小说失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 创建新小说
  Future<bool> createNovel({
    required String title,
    String author = '',
    int dailyGoal = 1000,
    String? savePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final novel = Novel(
        title: title,
        author: author,
        dailyGoal: dailyGoal,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 添加默认第一章
      novel.chapters.add(Chapter(title: '第一章', content: ''));

      // 保存小说
      await FileService.saveNovel(novel);

      _currentNovel = novel;
      _currentChapterIndex = 0;
      _hasUnsavedChanges = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '创建小说失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 保存当前小说
  Future<bool> saveCurrentNovel() async {
    if (_currentNovel == null) return false;

    try {
      _currentNovel!.updatedAt = DateTime.now();
      await FileService.saveNovel(_currentNovel!);

      _hasUnsavedChanges = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '保存失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 手动备份
  Future<bool> manualBackup() async {
    if (_currentNovel == null) return false;
    try {
      await FileService.manualBackup(_currentNovel!);
      return true;
    } catch (e) {
      _errorMessage = '备份失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 导出 TXT
  Future<bool> exportToTxt() async {
    if (_currentNovel == null) return false;
    try {
      await FileService.exportToTxt(_currentNovel!);
      return true;
    } catch (e) {
      _errorMessage = '导出失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 切换章节
  void switchChapter(int index) {
    if (_currentNovel == null) return;
    if (index >= 0 && index < _currentNovel!.chapters.length) {
      _currentChapterIndex = index;
      notifyListeners();
    }
  }

  /// 下一章
  void nextChapter() {
    if (_currentNovel == null) return;
    if (_currentChapterIndex < _currentNovel!.chapters.length - 1) {
      _currentChapterIndex++;
      notifyListeners();
    }
  }

  /// 上一章
  void previousChapter() {
    if (_currentNovel == null) return;
    if (_currentChapterIndex > 0) {
      _currentChapterIndex--;
      notifyListeners();
    }
  }

  /// 添加新章节
  void addChapter({String title = '新章节', String content = ''}) {
    if (_currentNovel == null) return;
    _currentNovel!.chapters.add(Chapter(title: title, content: content));
    _currentChapterIndex = _currentNovel!.chapters.length - 1;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 删除章节
  void deleteChapter(int index) {
    if (_currentNovel == null) return;
    if (_currentNovel!.chapters.length <= 1) return; // 至少保留一章
    _currentNovel!.chapters.removeAt(index);
    if (_currentChapterIndex >= _currentNovel!.chapters.length) {
      _currentChapterIndex = _currentNovel!.chapters.length - 1;
    }
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 更新当前章节内容
  void updateCurrentChapterContent(String content) {
    if (_currentNovel == null) return;
    if (_currentChapterIndex < 0 ||
        _currentChapterIndex >= _currentNovel!.chapters.length) {
      return;
    }
    _currentNovel!.chapters[_currentChapterIndex].content = content;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 重命名章节
  void renameChapter(int index, String newTitle) {
    if (_currentNovel == null) return;
    if (index >= 0 && index < _currentNovel!.chapters.length) {
      _currentNovel!.chapters[index].title = newTitle;
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 重新排序章节
  void reorderChapters(int oldIndex, int newIndex) {
    if (_currentNovel == null) return;
    if (newIndex > oldIndex) newIndex--;
    final chapter = _currentNovel!.chapters.removeAt(oldIndex);
    _currentNovel!.chapters.insert(newIndex, chapter);
    _currentChapterIndex = newIndex;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 更新章节大纲备注
  void updateChapterOutlineNote(int index, String note) {
    if (_currentNovel == null) return;
    if (index >= 0 && index < _currentNovel!.chapters.length) {
      _currentNovel!.chapters[index].outlineNote = note;
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 更新每日写作目标
  void updateDailyGoal(int goal) {
    if (_currentNovel == null) return;
    _currentNovel!.dailyGoal = goal;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 关闭当前小说
  void closeNovel() {
    _currentNovel = null;
    _currentChapterIndex = 0;
    _hasUnsavedChanges = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// 获取当前小说的统计数据
  NovelStatistics getStatistics() {
    if (_currentNovel == null) {
      return NovelStatistics(dailyRecords: []);
    }
    // 从章节字数构建每日记录（简化：一章当作一天）
    final records = <DailyRecord>[];
    for (int i = 0; i < _currentNovel!.chapters.length; i++) {
      final chapter = _currentNovel!.chapters[i];
      final wordCount = chapter.content.replaceAll(RegExp(r'\s+'), '').length;
      if (wordCount > 0) {
        records.add(DailyRecord(
          date: DateTime.now().subtract(Duration(days: _currentNovel!.chapters.length - i - 1)),
          wordCount: wordCount,
        ));
      }
    }
    return NovelStatistics(dailyRecords: records);
  }
}

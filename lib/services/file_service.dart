import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/novel.dart';
import 'parser_service.dart';

class FileService {
  static String? _customStoragePath;

  /// 设置自定义存储目录
  static Future<void> setStoragePath(String path) async {
    _customStoragePath = path;
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 获取存储目录
  static Future<String> getStoragePath() async {
    if (_customStoragePath != null) return _customStoragePath!;
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/${ParserService.novelsDirectoryName}';
  }

  /// 获取备份目录
  static Future<String> getBackupPath() async {
    final storage = await getStoragePath();
    final backupDir = Directory('$storage/backup');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  /// 获取所有 .novel 文件列表
  static Future<List<FileSystemEntity>> listNovelFiles() async {
    final storage = await getStoragePath();
    final dir = Directory(storage);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return [];
    }
    return dir.listSync()
        .where((e) => e is File && e.path.endsWith('.novel'))
        .toList();
  }

  /// 保存小说到文件
  static Future<void> saveNovel(Novel novel) async {
    final storage = await getStoragePath();
    // 文件名：小说名.novel
    final fileName = '${_sanitizeFilename(novel.title)}.novel';
    final filePath = '${storage}/$fileName';

    final content = ParserService.serialize(novel);
    final file = File(filePath);
    await file.writeAsString(content, flush: true);

    novel.filePath = filePath;

    // 自动备份
    await _autoBackup(novel);
  }

  /// 从文件加载小说
  static Future<Novel?> loadNovel(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final novel = ParserService.deserialize(content, filePath: filePath);
      return novel;
    } catch (e) {
      return null;
    }
  }

  /// 删除小说文件
  static Future<void> deleteNovel(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      // 先移动到回收站目录
      final storage = await getStoragePath();
      final trashDir = Directory('$storage/trash');
      if (!await trashDir.exists()) {
        await trashDir.create(recursive: true);
      }
      final baseName = filePath.split('/').last;
      final trashPath = '${trashDir.path}/$baseName';
      await file.rename(trashPath);
    }
  }

  /// 自动备份（保存时触发）
  static Future<void> _autoBackup(Novel novel) async {
    try {
      final backupDir = await getBackupPath();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final baseName = _sanitizeFilename(novel.title);
      final backupPath = '${backupDir}/${baseName}_$timestamp.novel.bak';

      final content = ParserService.serialize(novel);
      await File(backupPath).writeAsString(content, flush: true);

      // 清理旧备份（保留最近50个）
      await _cleanOldBackups(backupDir, baseName);
    } catch (_) {}
  }

  /// 手动备份
  static Future<String> manualBackup(Novel novel) async {
    final backupDir = await getBackupPath();
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final baseName = _sanitizeFilename(novel.title);
    final backupPath = '${backupDir}/${baseName}_manual_$timestamp.novel.bak';

    final content = ParserService.serialize(novel);
    await File(backupPath).writeAsString(content, flush: true);
    return backupPath;
  }

  /// 获取备份列表
  static Future<List<FileSystemEntity>> listBackups(String novelTitle) async {
    final backupDir = await getBackupPath();
    final dir = Directory(backupDir);
    if (!await dir.exists()) return [];
    final baseName = _sanitizeFilename(novelTitle);
    return dir.listSync()
        .where((e) => e is File && e.path.contains(baseName) && e.path.endsWith('.bak'))
        .toList();
  }

  /// 从备份恢复
  static Future<Novel?> restoreFromBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return ParserService.deserialize(content);
    } catch (_) {
      return null;
    }
  }

  /// 清理旧备份（保留最近50个）
  static Future<void> _cleanOldBackups(String backupDir, String baseName) async {
    final dir = Directory(backupDir);
    if (!await dir.exists()) return;
    final backups = dir.listSync()
        .where((e) => e is File && e.path.contains(baseName) && e.path.endsWith('.bak'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // 最新的在前

    if (backups.length > 50) {
      for (int i = 50; i < backups.length; i++) {
        await File(backups[i].path).delete();
      }
    }
  }

  /// 导出为 TXT
  static Future<String> exportToTxt(Novel novel) async {
    final storage = await getStoragePath();
    final fileName = '${_sanitizeFilename(novel.title)}.txt';
    final filePath = '$storage/$fileName';

    final buffer = StringBuffer();
    buffer.writeln(novel.title);
    if (novel.author.isNotEmpty) {
      buffer.writeln('作者：${novel.author}');
    }
    buffer.writeln('=' * 40);
    buffer.writeln();

    for (int i = 0; i < novel.chapters.length; i++) {
      final chapter = novel.chapters[i];
      buffer.writeln(chapter.title);
      buffer.writeln('-' * 20);
      buffer.writeln(chapter.content);
      buffer.writeln();
      buffer.writeln();
    }

    await File(filePath).writeAsString(buffer.toString(), flush: true);
    return filePath;
  }

  /// 清理文件名中的非法字符
  static String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}

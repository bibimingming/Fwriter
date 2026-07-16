import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/novel_provider.dart';
import '../providers/editor_provider.dart';
import '../providers/search_provider.dart';
import '../utils/word_counter.dart';
import '../widgets/word_count_badge.dart';
import 'placeholder_screen.dart';
import 'outline_screen.dart';
import 'statistics_screen.dart';

/// 编辑器主界面
/// 极简设计：顶部工具栏 + 大片空白写作区 + 二级菜单
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _textController;
  final FocusNode _editorFocus = FocusNode();
  bool _isSearchVisible = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncContentFromProvider();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncContentFromProvider();
  }

  void _syncContentFromProvider() {
    final novelProv = context.read<NovelProvider>();
    final chapter = novelProv.currentChapter;
    if (chapter != null && _textController.text != chapter.content) {
      _textController.text = chapter.content;
      // 光标移到最后
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _editorFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onContentChanged(String text) {
    final novelProv = context.read<NovelProvider>();
    novelProv.updateCurrentChapterContent(text);

    // 更新写作字数
    final editorProv = context.read<EditorProvider>();
    final wordCount = WordCounter.countChineseChars(text);
    editorProv.updateSessionWordCount(wordCount);
  }

  void _showToolsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ToolsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<NovelProvider, EditorProvider>(
      builder: (context, novelProv, editorProv, child) {
        final novel = novelProv.currentNovel;
        final chapter = novelProv.currentChapter;

        if (novel == null || chapter == null) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    '没有打开的小说',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '从主菜单创建或打开一部小说',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final wordCount = WordCounter.countChineseChars(chapter.content);
        final totalWords = novelProv.totalWordCount;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // === 顶部工具栏（极简）===
                _buildTopToolbar(
                  context, colorScheme, novel, chapter, wordCount, totalWords,
                ),

                const Divider(height: 1),

                // === 搜索栏（可选显示）===
                if (_isSearchVisible) _buildSearchBar(context, colorScheme),

                // === 主体写作区 ===
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editorFocus.requestFocus(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _editorFocus,
                        onChanged: _onContentChanged,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '开始写作...',
                          hintStyle: TextStyle(
                            fontSize: 18,
                            height: 1.8,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.8,
                          letterSpacing: 0.5,
                          color: colorScheme.onSurface,
                        ),
                        cursorColor: colorScheme.primary,
                        cursorWidth: 2,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopToolbar(
    BuildContext context,
    ColorScheme colorScheme,
    dynamic novel,
    dynamic chapter,
    int wordCount,
    int totalWords,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // 返回按钮（回到小说选择）
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(width: 4),

          // 章节名
          Expanded(
            child: GestureDetector(
              onTap: () => _showChapterSwitcher(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      chapter.title.isEmpty ? '未命名章节' : chapter.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down,
                      size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),

          // 小说名
          Text(
            novel.title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(width: 12),

          // 写作统计
          WordCountBadge(wordCount: wordCount, showGoal: false),

          const SizedBox(width: 12),

          // 总字数
          Text(
            '总 ${_formatCount(totalWords)}',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),

          const SizedBox(width: 4),

          // 二级菜单入口
          IconButton(
            icon: Icon(Icons.more_horiz, size: 20,
                color: colorScheme.onSurfaceVariant),
            onPressed: () => _showToolsMenu(context),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Consumer<SearchProvider>(
      builder: (context, searchProv, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    searchProv.setQuery(value);
                    final novelProv = context.read<NovelProvider>();
                    if (novelProv.currentNovel != null) {
                      searchProv.search(novelProv.currentNovel!);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '搜索...',
                    isDense: true,
                    prefixIcon: Icon(Icons.search,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    suffixIcon: searchProv.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchProv.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune, size: 18),
                onPressed: () => _showSearchOptions(context),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() => _isSearchVisible = false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchOptions(BuildContext context) {
    final searchProv = context.read<SearchProvider>();
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('使用正则表达式'),
                value: searchProv.useRegex,
                onChanged: (_) {
                  searchProv.toggleRegex();
                  setSheetState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('区分大小写'),
                value: searchProv.matchCase,
                onChanged: (_) {
                  searchProv.toggleMatchCase();
                  setSheetState(() {});
                },
              ),
              if (searchProv.results.isNotEmpty) ...[
                const Divider(),
                Text('找到 ${searchProv.results.length} 个结果'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showChapterSwitcher(BuildContext context) {
    final novelProv = context.read<NovelProvider>();
    final novel = novelProv.currentNovel;
    if (novel == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '章节列表',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      novelProv.addChapter();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: novel.chapters.length,
                onReorder: novelProv.reorderChapters,
                itemBuilder: (context, index) {
                  final chapter = novel.chapters[index];
                  return Card(
                    key: ValueKey(chapter.title + index.toString()),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    color: index == novelProv.currentChapterIndex
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3)
                        : null,
                    child: ListTile(
                      leading: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: index == novelProv.currentChapterIndex
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      title: Text(
                        chapter.title.isEmpty ? '未命名' : chapter.title,
                      ),
                      subtitle: Text(
                        '${WordCounter.countChineseChars(chapter.content)} 字',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index == novelProv.currentChapterIndex)
                            Icon(Icons.edit,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Icon(Icons.drag_handle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ],
                      ),
                      onTap: () {
                        novelProv.switchChapter(index);
                        _syncContentFromProvider();
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}w';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

/// 二级工具菜单面板
class _ToolsSheet extends StatefulWidget {
  @override
  State<_ToolsSheet> createState() => _ToolsSheetState();
}

class _ToolsSheetState extends State<_ToolsSheet> {
  void _openScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // 关闭Sheet
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示条
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '写作工具',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // 工具网格
          Row(
            children: [
              _ToolItem(
                icon: Icons.search,
                label: '搜索替换',
                onTap: () {
                  // 直接在当前编辑器激活搜索栏
                  Navigator.pop(context);
                },
              ),
              _ToolItem(
                icon: Icons.view_column_outlined,
                label: '分屏编辑',
                onTap: () => _openScreen(
                    context, const PlaceholderScreen('分屏编辑')),
              ),
              _ToolItem(
                icon: Icons.list_alt_outlined,
                label: '大纲视图',
                onTap: () => _openScreen(
                    context, const OutlineScreen()),
              ),
              _ToolItem(
                icon: Icons.timer_outlined,
                label: '番茄钟',
                onTap: () => _openScreen(
                    context, const PlaceholderScreen('番茄钟')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ToolItem(
                icon: Icons.bar_chart_outlined,
                label: '写作统计',
                onTap: () => _openScreen(
                    context, const PlaceholderScreen('写作统计')),
              ),
              _ToolItem(
                icon: Icons.analytics_outlined,
                label: '统计看板',
                onTap: () => _openScreen(
                    context, const StatisticsScreen()),
              ),
              _ToolItem(
                icon: Icons.language,
                label: '高频词',
                onTap: () => _openScreen(
                    context, const PlaceholderScreen('高频词分析')),
              ),
              _ToolItem(
                icon: Icons.abc,
                label: '的得地检查',
                onTap: () => _openScreen(
                    context, const PlaceholderScreen('的得地检查')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ToolItem(
                icon: Icons.backup_outlined,
                label: '备份/导出',
                onTap: () => _openScreen(
                    context, const PlaceholderScreen('备份/导出')),
              ),
              _ToolItem(
                icon: Icons.edit_note,
                label: '写作目标',
                onTap: () => _openScreen(
                    context, const PlaceholderScreen('写作目标设置')),
              ),
              _ToolItem(
                icon: Icons.dark_mode_outlined,
                label: '切换主题',
                onTap: () {
                  // 切换亮暗模式
                  Navigator.pop(context);
                },
              ),
              _ToolItem(
                icon: Icons.settings_outlined,
                label: '设置',
                onTap: () => _openScreen(
                    context, const PlaceholderScreen('设置')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 工具图标项
class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
// PlaceholderScreen 已抽离到 placeholder_screen.dart


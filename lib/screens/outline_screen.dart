import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/novel_provider.dart';
import '../models/chapter.dart';
import '../utils/word_counter.dart';
import '../widgets/chapter_tile.dart';
import 'editor_screen.dart';

/// 大纲视图页面
/// 展示所有章节的提纲列表，支持拖拽排序、编辑备注、快速切换
class OutlineScreen extends StatefulWidget {
  const OutlineScreen({super.key});

  @override
  State<OutlineScreen> createState() => _OutlineScreenState();
}

class _OutlineScreenState extends State<OutlineScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<NovelProvider>(
      builder: (context, novelProv, child) {
        final novel = novelProv.currentNovel;
        if (novel == null) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(title: const Text('大纲视图')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt_outlined, size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('请先打开一部小说',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }

        final chapters = novel.chapters;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text('大纲 - ${novel.title}'),
            actions: [
              // 全部展开/折叠
              IconButton(
                icon: const Icon(Icons.unfold_more),
                tooltip: '全部展开',
                onPressed: () {
                  // 后续可以实现全部展开备注
                },
              ),
            ],
          ),
          body: chapters.isEmpty
              ? _buildEmptyOutline(context, colorScheme, novelProv)
              : _buildOutlineList(context, colorScheme, chapters, novelProv),
          floatingActionButton: FloatingActionButton(
            heroTag: 'outline_add',
            onPressed: () {
              novelProv.addChapter();
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyOutline(
    BuildContext context,
    ColorScheme colorScheme,
    NovelProvider novelProv,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            '还没有章节',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角 + 添加第一个章节',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineList(
    BuildContext context,
    ColorScheme colorScheme,
    List<Chapter> chapters,
    NovelProvider novelProv,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: chapters.length,
      onReorder: novelProv.reorderChapters,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isCurrent = index == novelProv.currentChapterIndex;
        final wordCount = WordCounter.countChineseChars(chapter.content);
        final hasOutlineNote = chapter.outlineNote.isNotEmpty;

        return Card(
          key: ValueKey('outline_${chapter.title}_$index'),
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCurrent
                  ? colorScheme.primary.withOpacity(0.5)
                  : colorScheme.outlineVariant.withOpacity(0.3),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          color: isCurrent
              ? colorScheme.primaryContainer.withOpacity(0.15)
              : colorScheme.surface,
          child: ExpansionTile(
            key: PageStorageKey('outline_$index'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrent
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isCurrent
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    chapter.title.isEmpty ? '未命名章节' : chapter.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasOutlineNote)
                  Icon(Icons.notes_rounded,
                      size: 14, color: colorScheme.primary.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  _formatCount(wordCount),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '编辑中',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.drag_handle,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
              ],
            ),
            children: [
              // 大纲备注编辑区
              _buildOutlineNote(context, colorScheme, chapter, index, novelProv),

              // 操作按钮
              const SizedBox(height: 8),
              Row(
                children: [
                  if (!isCurrent)
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('编辑此章', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        novelProv.switchChapter(index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditorScreen()),
                        );
                      },
                    ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('删除', style: TextStyle(fontSize: 12)),
                    onPressed: () => _confirmDelete(
                        context, colorScheme, novelProv, index, chapter.title),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutlineNote(
    BuildContext context,
    ColorScheme colorScheme,
    Chapter chapter,
    int index,
    NovelProvider novelProv,
  ) {
    final noteController =
        TextEditingController(text: chapter.outlineNote);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '章节备注',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: noteController,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: '写下本章的写作思路、关键情节...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(10),
          ),
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface,
          ),
          onChanged: (value) {
            novelProv.updateChapterOutlineNote(index, value);
          },
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    ColorScheme colorScheme,
    NovelProvider novelProv,
    int index,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除章节'),
        content: Text('确定要删除「${title.isEmpty ? '未命名' : title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              novelProv.deleteChapter(index);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}w';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

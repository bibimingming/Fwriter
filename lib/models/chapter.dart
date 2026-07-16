class Chapter {
  String title;
  String content;
  String outlineNote; // 大纲备注（仅在大纲视图可见）

  Chapter({
    required this.title,
    this.content = '',
    this.outlineNote = '',
  });

  int get wordCount => content.replaceAll(RegExp(r'\s+'), '').length;

  Chapter copyWith({
    String? title,
    String? content,
    String? outlineNote,
  }) {
    return Chapter(
      title: title ?? this.title,
      content: content ?? this.content,
      outlineNote: outlineNote ?? this.outlineNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'outlineNote': outlineNote,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        outlineNote: json['outlineNote'] as String? ?? '',
      );
}

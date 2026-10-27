class SnippetModel {
  final String id;
  final String title;
  final String command;
  final String category;
  final String description;
  final List<String> variables;

  SnippetModel({
    required this.id,
    required this.title,
    required this.command,
    this.category = 'General',
    this.description = '',
    this.variables = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'command': command,
      'category': category,
      'description': description,
      'variables': variables,
    };
  }

  factory SnippetModel.fromJson(Map<String, dynamic> json) {
    return SnippetModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled Snippet',
      command: json['command'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      variables: (json['variables'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  SnippetModel copyWith({
    String? id,
    String? title,
    String? command,
    String? category,
    String? description,
    List<String>? variables,
  }) {
    return SnippetModel(
      id: id ?? this.id,
      title: title ?? this.title,
      command: command ?? this.command,
      category: category ?? this.category,
      description: description ?? this.description,
      variables: variables ?? this.variables,
    );
  }
}

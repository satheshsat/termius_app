class GroupModel {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;
  final String description;

  GroupModel({
    required this.id,
    required this.name,
    this.colorHex = '#10B981',
    this.iconName = 'folder',
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'iconName': iconName,
      'description': description,
    };
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Untitled Group',
      colorHex: json['colorHex'] as String? ?? '#10B981',
      iconName: json['iconName'] as String? ?? 'folder',
      description: json['description'] as String? ?? '',
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    String? description,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      description: description ?? this.description,
    );
  }
}

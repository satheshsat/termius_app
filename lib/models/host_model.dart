class HostModel {
  final String id;
  final String alias;
  final String hostname;
  final int port;
  final String username;
  final String password;
  final String? keyId;
  final String passphrase;
  final String group;
  final String colorHex;
  final List<String> tags;
  final String notes;
  final DateTime createdAt;
  final DateTime? lastConnectedAt;
  final String status; // 'online', 'offline', 'unknown'
  final bool isFavorite;

  HostModel({
    required this.id,
    required this.alias,
    required this.hostname,
    this.port = 22,
    this.username = 'root',
    this.password = '',
    this.keyId,
    this.passphrase = '',
    this.group = 'Default',
    this.colorHex = '#00D2FF',
    this.tags = const [],
    this.notes = '',
    required this.createdAt,
    this.lastConnectedAt,
    this.status = 'unknown',
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alias': alias,
      'hostname': hostname,
      'port': port,
      'username': username,
      'password': password,
      'keyId': keyId,
      'passphrase': passphrase,
      'group': group,
      'colorHex': colorHex,
      'tags': tags,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      'status': status,
      'isFavorite': isFavorite,
    };
  }

  factory HostModel.fromJson(Map<String, dynamic> json) {
    return HostModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      alias: json['alias'] as String? ?? 'Untitled Host',
      hostname: json['hostname'] as String? ?? 'localhost',
      port: (json['port'] as num?)?.toInt() ?? 22,
      username: json['username'] as String? ?? 'root',
      password: json['password'] as String? ?? '',
      keyId: json['keyId'] as String?,
      passphrase: json['passphrase'] as String? ?? '',
      group: json['group'] as String? ?? 'Default',
      colorHex: json['colorHex'] as String? ?? '#00D2FF',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.tryParse(json['lastConnectedAt'] as String)
          : null,
      status: json['status'] as String? ?? 'unknown',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  HostModel copyWith({
    String? id,
    String? alias,
    String? hostname,
    int? port,
    String? username,
    String? password,
    String? keyId,
    String? passphrase,
    String? group,
    String? colorHex,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
    String? status,
    bool? isFavorite,
  }) {
    return HostModel(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      keyId: keyId ?? this.keyId,
      passphrase: passphrase ?? this.passphrase,
      group: group ?? this.group,
      colorHex: colorHex ?? this.colorHex,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

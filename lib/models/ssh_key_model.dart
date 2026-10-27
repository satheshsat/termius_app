class SSHKeyModel {
  final String id;
  final String name;
  final String keyType; // 'Ed25519', 'RSA', 'ECDSA'
  final String publicKey;
  final String privateKey;
  final String passphrase;
  final String fingerprint;
  final DateTime createdAt;

  SSHKeyModel({
    required this.id,
    required this.name,
    this.keyType = 'Ed25519',
    required this.publicKey,
    required this.privateKey,
    this.passphrase = '',
    this.fingerprint = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keyType': keyType,
      'publicKey': publicKey,
      'privateKey': privateKey,
      'passphrase': passphrase,
      'fingerprint': fingerprint,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SSHKeyModel.fromJson(Map<String, dynamic> json) {
    return SSHKeyModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Untitled Key',
      keyType: json['keyType'] as String? ?? 'Ed25519',
      publicKey: json['publicKey'] as String? ?? '',
      privateKey: json['privateKey'] as String? ?? '',
      passphrase: json['passphrase'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  SSHKeyModel copyWith({
    String? id,
    String? name,
    String? keyType,
    String? publicKey,
    String? privateKey,
    String? passphrase,
    String? fingerprint,
    DateTime? createdAt,
  }) {
    return SSHKeyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      keyType: keyType ?? this.keyType,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      passphrase: passphrase ?? this.passphrase,
      fingerprint: fingerprint ?? this.fingerprint,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PortForwardModel {
  final String id;
  final String name;
  final String hostId;
  final String forwardType; // 'Local', 'Remote', 'Dynamic'
  final int localPort;
  final String remoteHost;
  final int remotePort;
  final bool isActive;

  PortForwardModel({
    required this.id,
    required this.name,
    required this.hostId,
    this.forwardType = 'Local',
    required this.localPort,
    this.remoteHost = '127.0.0.1',
    required this.remotePort,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostId': hostId,
      'forwardType': forwardType,
      'localPort': localPort,
      'remoteHost': remoteHost,
      'remotePort': remotePort,
      'isActive': isActive,
    };
  }

  factory PortForwardModel.fromJson(Map<String, dynamic> json) {
    return PortForwardModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Tunnel',
      hostId: json['hostId'] as String? ?? '',
      forwardType: json['forwardType'] as String? ?? 'Local',
      localPort: (json['localPort'] as num?)?.toInt() ?? 8080,
      remoteHost: json['remoteHost'] as String? ?? '127.0.0.1',
      remotePort: (json['remotePort'] as num?)?.toInt() ?? 80,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  PortForwardModel copyWith({
    String? id,
    String? name,
    String? hostId,
    String? forwardType,
    int? localPort,
    String? remoteHost,
    int? remotePort,
    bool? isActive,
  }) {
    return PortForwardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      forwardType: forwardType ?? this.forwardType,
      localPort: localPort ?? this.localPort,
      remoteHost: remoteHost ?? this.remoteHost,
      remotePort: remotePort ?? this.remotePort,
      isActive: isActive ?? this.isActive,
    );
  }
}

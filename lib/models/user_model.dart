class UserModel {
  final String username;
  final String tier;
  final int expiresAt;
  final List<ServerInfo> servers;

  UserModel({
    required this.username,
    required this.tier,
    required this.expiresAt,
    required this.servers,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var serversList = (json['servers'] as List? ?? [])
        .map((e) => ServerInfo.fromJson(e as Map<String, dynamic>))
        .toList();

    return UserModel(
      username: json['username'] ?? '',
      tier: json['tier'] ?? 'Free',
      expiresAt: json['expires_at'] ?? 0,
      servers: serversList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'tier': tier,
      'expires_at': expiresAt,
      'servers': servers.map((e) => e.toJson()).toList(),
    };
  }
}

class ServerInfo {
  final int id;
  final String name;
  final String protocol;
  final String host;
  final int port;
  final String? sni;

  ServerInfo({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    this.sni,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      protocol: json['protocol'] ?? '',
      host: json['host'] ?? '',
      port: json['port'] ?? 0,
      sni: json['sni'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'protocol': protocol,
      'host': host,
      'port': port,
      'sni': sni,
    };
  }
}

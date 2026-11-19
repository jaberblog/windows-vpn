class VpnConfigModel {
  final String id;
  final String title;
  final String server;
  final int port;
  final String protocol;
  final String rawUri;
  final String fullConfiguration;
  int? ping;
  bool isPinging;

  VpnConfigModel({
    required this.id,
    required this.title,
    required this.server,
    required this.port,
    required this.protocol,
    required this.rawUri,
    required this.fullConfiguration,
    this.ping,
    this.isPinging = false,
  });

  VpnConfigModel copyWith({
    String? title,
    String? server,
    int? port,
    String? protocol,
    String? rawUri,
    String? fullConfiguration,
    int? ping,
    bool? isPinging,
    bool clearPing = false,
  }) {
    return VpnConfigModel(
      id: id,
      title: title ?? this.title,
      server: server ?? this.server,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      rawUri: rawUri ?? this.rawUri,
      fullConfiguration: fullConfiguration ?? this.fullConfiguration,
      ping: clearPing ? null : (ping ?? this.ping),
      isPinging: isPinging ?? this.isPinging,
    );
  }
}

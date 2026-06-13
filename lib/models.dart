import 'dart:math';

class ServerEntry {
  final String id;
  String name;
  String url;
  String username;
  String password;
  int lastUsed;

  ServerEntry({
    String? id,
    required this.name,
    required this.url,
    this.username = '',
    this.password = '',
    int? lastUsed,
  })  : id = id ?? _generateId(),
        lastUsed = lastUsed ?? DateTime.now().millisecondsSinceEpoch;

  static String _generateId() {
    final rand = Random();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r = rand.nextInt(99999);
    return 'sv_${ts}_$r';
  }

  factory ServerEntry.fromJson(Map<String, dynamic> json) => ServerEntry(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        lastUsed: json['lastUsed'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'username': username,
        'password': password,
        'lastUsed': lastUsed,
      };

  ServerEntry copyWith({
    String? name,
    String? url,
    String? username,
    String? password,
  }) =>
      ServerEntry(
        id: id,
        name: name ?? this.name,
        url: url ?? this.url,
        username: username ?? this.username,
        password: password ?? this.password,
        lastUsed: lastUsed,
      );
}

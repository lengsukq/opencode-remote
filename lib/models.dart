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

// --- opencode REST API models ---

class HealthStatus {
  final bool healthy;
  final String version;

  HealthStatus({required this.healthy, required this.version});

  factory HealthStatus.fromJson(Map<String, dynamic> json) => HealthStatus(
        healthy: json['healthy'] as bool? ?? false,
        version: json['version'] as String? ?? '',
      );
}

class Project {
  final String id;
  final String name;
  final String path;

  Project({required this.id, required this.name, required this.path});

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String? ?? '',
        name: json['id'] as String? ?? '',
        path: json['worktree'] as String? ?? '',
      );
}

class VcsInfo {
  final String? branch;
  final String? commit;
  final String? repoUrl;

  VcsInfo({this.branch, this.commit, this.repoUrl});

  factory VcsInfo.fromJson(Map<String, dynamic> json) => VcsInfo(
        branch: json['branch'] as String?,
        commit: json['commit'] as String?,
        repoUrl: json['repoUrl'] as String?,
      );
}

class Session {
  final String id;
  final String title;
  final String? projectId;
  final int createdAt;
  final int updatedAt;
  final String status;

  Session({
    required this.id,
    required this.title,
    this.projectId,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'idle',
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final time = json['time'] as Map<String, dynamic>?;
    return Session(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      projectId: json['projectID'] as String?,
      createdAt: time?['created'] as int? ?? 0,
      updatedAt: time?['updated'] as int? ?? 0,
      status: json['status'] as String? ?? 'idle',
    );
  }
}

class Message {
  final String id;
  final String role;
  final String content;
  final int createdAt;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromInfo(Map<String, dynamic> info, List<Map<String, dynamic>> parts) {
    final time = info['time'] as Map<String, dynamic>?;
    final created = time?['created'] as int? ?? 0;
    final content = _extractContent(parts);
    return Message(
      id: info['id'] as String? ?? '',
      role: info['role'] as String? ?? 'user',
      content: content,
      createdAt: created,
    );
  }

  static String _extractContent(List<Map<String, dynamic>> parts) {
    final buf = StringBuffer();
    for (final p in parts) {
      if (p['type'] == 'text' && p['text'] is String) {
        buf.writeln(p['text'] as String);
      } else if (p['type'] == 'reasoning' && p['text'] is String) {
        buf.writeln(p['text'] as String);
      } else if (p['type'] == 'tool') {
        final state = p['state'] as Map<String, dynamic>?;
        if (state != null && state['output'] is String) {
          buf.writeln(state['output'] as String);
        }
      }
    }
    return buf.toString().trim();
  }
}

class FileNode {
  final String name;
  final String path;
  final String type;
  final int? size;

  FileNode({
    required this.name,
    required this.path,
    required this.type,
    this.size,
  });

  factory FileNode.fromJson(Map<String, dynamic> json) => FileNode(
        name: json['name'] as String? ?? '',
        path: json['path'] as String? ?? '',
        type: json['type'] as String? ?? 'file',
        size: json['size'] as int?,
      );
}

class FileContent {
  final String path;
  final String content;
  final String language;

  FileContent({
    required this.path,
    required this.content,
    this.language = '',
  });

  factory FileContent.fromJson(Map<String, dynamic> json) => FileContent(
        path: json['path'] as String? ?? '',
        content: json['content'] as String? ?? '',
        language: json['language'] as String? ?? '',
      );
}

class Config {
  final Map<String, dynamic> data;

  Config({required this.data});

  factory Config.fromJson(Map<String, dynamic> json) => Config(data: json);
}

class Agent {
  final String name;
  final String? description;
  final String mode;
  final bool builtIn;
  final String? color;

  Agent({
    required this.name,
    this.description,
    required this.mode,
    required this.builtIn,
    this.color,
  });

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        mode: json['mode'] as String? ?? 'subagent',
        builtIn: json['builtIn'] as bool? ?? false,
        color: json['color'] as String?,
      );
}

class ProviderModel {
  final String id;
  final String name;
  final String providerID;
  final String status;

  ProviderModel({
    required this.id,
    required this.name,
    required this.providerID,
    this.status = 'active',
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json, {required String providerID}) => ProviderModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? json['id'] as String? ?? '',
        providerID: providerID,
        status: json['status'] as String? ?? 'active',
      );

  String get fullID => '$providerID/$id';
}

class Provider {
  final String id;
  final String name;
  final List<ProviderModel> models;

  Provider({required this.id, required this.name, required this.models});

  factory Provider.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? id;
    final modelsMap = json['models'] as Map<String, dynamic>? ?? {};
    final models = modelsMap.entries.map((e) =>
      ProviderModel.fromJson(e.value as Map<String, dynamic>, providerID: id)
    ).toList();
    return Provider(id: id, name: name, models: models);
  }
}

enum AppMode { webview, native }

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

  factory Project.fromJson(Map<String, dynamic> json) {
    final path = (json['worktree'] ?? json['path']) as String? ?? '';
    return Project(
      id: json['id'] as String? ?? '',
      name: _nameFromJson(json['name'] as String?, path),
      path: path,
    );
  }

  static String _nameFromJson(String? name, String path) {
    if (name != null && name.isNotEmpty) return name;
    return path.split(RegExp(r'[/\\]')).lastWhere((s) => s.isNotEmpty, orElse: () => '');
  }
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
  final String? reasoning;
  final int createdAt;
  final String? model;

  Message({
    required this.id,
    required this.role,
    required this.content,
    this.reasoning,
    required this.createdAt,
    this.model,
  });

  bool get hasReasoning => reasoning != null && reasoning!.isNotEmpty;

  factory Message.fromInfo(Map<String, dynamic> info, List<Map<String, dynamic>> parts) {
    final time = info['time'] as Map<String, dynamic>?;
    final created = time?['created'] as int? ?? 0;
    final extracted = _extractContent(parts);
    final model = _extractModel(info);
    return Message(
      id: info['id'] as String? ?? '',
      role: info['role'] as String? ?? 'user',
      content: extracted.content,
      reasoning: extracted.reasoning,
      createdAt: created,
      model: model,
    );
  }

  static String? _extractModel(Map<String, dynamic> info) {
    final role = info['role'] as String?;
    if (role == 'user') {
      final m = info['model'] as Map<String, dynamic>?;
      if (m != null) {
        final pid = m['providerID'] as String?;
        final mid = m['modelID'] as String?;
        if (pid != null && mid != null) return '$pid/$mid';
      }
    } else {
      final pid = info['providerID'] as String?;
      final mid = info['modelID'] as String?;
      if (pid != null && mid != null) return '$pid/$mid';
    }
    return null;
  }

  static _ExtractedContent _extractContent(List<Map<String, dynamic>> parts) {
    final textBuf = StringBuffer();
    final reasoningBuf = StringBuffer();
    for (final p in parts) {
      if (p['type'] == 'text' && p['text'] is String) {
        textBuf.writeln(p['text'] as String);
      } else if (p['type'] == 'reasoning' && p['text'] is String) {
        reasoningBuf.writeln(p['text'] as String);
      } else if (p['type'] == 'tool') {
        final state = p['state'] as Map<String, dynamic>?;
        if (state != null && state['output'] is String) {
          textBuf.writeln(state['output'] as String);
        }
      }
    }
    return _ExtractedContent(
      content: textBuf.toString().trim(),
      reasoning: reasoningBuf.toString().trim(),
    );
  }
}

class _ExtractedContent {
  final String content;
  final String? reasoning;
  _ExtractedContent({required this.content, this.reasoning});
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
    final rawModels = json['models'];
    final modelsList = rawModels is List
        ? rawModels
        : rawModels is Map ? rawModels.values.toList() : <dynamic>[];
    final models = modelsList.map((e) =>
      ProviderModel.fromJson(e is Map<String, dynamic> ? e : {}, providerID: id)
    ).toList();
    return Provider(id: id, name: name, models: models);
  }
}

class Command {
  final String id;
  final String title;
  final String? description;
  final List<String>? arguments;

  Command({required this.id, required this.title, this.description, this.arguments});

  factory Command.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['arguments'];
    final arguments = rawArgs is List ? rawArgs.map((e) => e.toString()).toList() : null;
    return Command(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      arguments: arguments,
    );
  }
}

class DiffEntry {
  final String filePath;
  final String status;
  final int additions;
  final int deletions;
  final String? patch;

  DiffEntry({
    required this.filePath,
    required this.status,
    this.additions = 0,
    this.deletions = 0,
    this.patch,
  });

  factory DiffEntry.fromJson(Map<String, dynamic> json) => DiffEntry(
        filePath: json['file'] as String? ?? json['filePath'] as String? ?? json['path'] as String? ?? '',
        status: json['status'] as String? ?? 'modified',
        additions: json['additions'] as int? ?? 0,
        deletions: json['deletions'] as int? ?? 0,
        patch: json['patch'] as String?,
      );
}

class SearchMatch {
  final String path;
  final int lineNumber;
  final String lines;
  final List<SearchSubmatch> submatches;

  SearchMatch({
    required this.path,
    required this.lineNumber,
    required this.lines,
    required this.submatches,
  });

  factory SearchMatch.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['submatches'];
    final subs = rawSubs is List ? rawSubs : <dynamic>[];
    final rawPath = json['path'];
    final rawLines = json['lines'];
    return SearchMatch(
      path: rawPath is Map ? rawPath['text'] as String? ?? '' : rawPath as String? ?? '',
      lineNumber: json['line_number'] as int? ?? 0,
      lines: rawLines is Map ? rawLines['text'] as String? ?? '' : rawLines as String? ?? '',
      submatches: subs.map((e) => SearchSubmatch.fromJson(e is Map<String, dynamic> ? e : {})).toList(),
    );
  }
}

class SearchSubmatch {
  final String match;
  final int start;
  final int end;

  SearchSubmatch({required this.match, required this.start, required this.end});

  factory SearchSubmatch.fromJson(Map<String, dynamic> json) {
    final rawMatch = json['match'];
    return SearchSubmatch(
      match: rawMatch is Map ? rawMatch['text'] as String? ?? '' : rawMatch as String? ?? '',
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
    );
  }
}

class LSPStatus {
  final String name;
  final String state;
  final String? version;

  LSPStatus({required this.name, required this.state, this.version});

  factory LSPStatus.fromJson(Map<String, dynamic> json) => LSPStatus(
        name: json['name'] as String? ?? '',
        state: json['state'] as String? ?? json['status'] as String? ?? 'unknown',
        version: (json['version'] as Object?)?.toString(),
      );
}

class FormatterStatus {
  final String name;
  final bool enabled;

  FormatterStatus({required this.name, required this.enabled});

  factory FormatterStatus.fromJson(Map<String, dynamic> json) => FormatterStatus(
        name: json['name'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
      );
}

class MCPStatus {
  final String name;
  final String state;

  MCPStatus({required this.name, required this.state});

  factory MCPStatus.fromJson(Map<String, dynamic> json) => MCPStatus(
        name: json['name'] as String? ?? '',
        state: json['state'] as String? ?? json['status'] as String? ?? 'unknown',
      );
}

class ProviderAuthMethod {
  final String type;
  final String label;

  ProviderAuthMethod({required this.type, required this.label});

  factory ProviderAuthMethod.fromJson(Map<String, dynamic> json) => ProviderAuthMethod(
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class ToolEntry {
  final String id;
  final String name;
  final String? description;

  ToolEntry({required this.id, required this.name, this.description});

  factory ToolEntry.fromJson(Map<String, dynamic> json) => ToolEntry(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? json['id'] as String? ?? '',
        description: json['description'] as String?,
      );
}

class Todo {
  final String id;
  final String task;
  final String status;

  Todo({required this.id, required this.task, this.status = 'pending'});

  bool get done => status == 'completed' || status == 'resolved';

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String? ?? '',
        task: json['content'] as String? ?? json['task'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
      );
}


class PathInfo {
  final String path;
  final String? directory;

  PathInfo({required this.path, this.directory});

  factory PathInfo.fromJson(Map<String, dynamic> json) => PathInfo(
        path: json['path'] as String? ?? '',
        directory: json['directory'] as String?,
      );
}

class SessionStatus {
  final String id;
  final String status;

  SessionStatus({required this.id, required this.status});

  factory SessionStatus.fromJson(Map<String, dynamic> json) => SessionStatus(
        id: json['id'] as String? ?? '',
        status: json['status'] as String? ?? 'idle',
      );
}

class Part {
  final String type;
  final String? text;
  final Map<String, dynamic>? state;
  final Map<String, dynamic>? toolCall;

  Part({required this.type, this.text, this.state, this.toolCall});

  factory Part.fromJson(Map<String, dynamic> json) => Part(
        type: json['type'] as String? ?? '',
        text: json['text'] as String?,
        state: _asMap(json['state']),
        toolCall: _asMap(json['toolCall']),
      );

  static Map<String, dynamic>? _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }
}

class FileStatus {
  final String path;
  final String status;

  FileStatus({required this.path, required this.status});

  factory FileStatus.fromJson(Map<String, dynamic> json) => FileStatus(
        path: json['path'] as String? ?? '',
        status: json['status'] as String? ?? 'unknown',
      );
}

class Symbol {
  final String name;
  final String path;
  final String? kind;
  final String? containerName;

  Symbol({required this.name, required this.path, this.kind, this.containerName});

  factory Symbol.fromJson(Map<String, dynamic> json) => Symbol(
        name: json['name'] as String? ?? '',
        path: json['path'] as String? ?? '',
        kind: json['kind'] as String?,
        containerName: json['containerName'] as String?,
      );
}

class ProviderDefaults {
  final List<Provider> providers;
  final Map<String, String> defaultModels;

  ProviderDefaults({required this.providers, required this.defaultModels});

  factory ProviderDefaults.fromJson(Map<String, dynamic> json) {
    final rawProviders = json['providers'];
    final providersList = rawProviders is List
        ? rawProviders
        : rawProviders is Map ? rawProviders.values.toList() : <dynamic>[];
    final rawDefaults = json['default'];
    final defaults = rawDefaults is Map ? Map<String, dynamic>.from(rawDefaults) : <String, dynamic>{};
    return ProviderDefaults(
      providers: providersList.map((e) => Provider.fromJson(e is Map<String, dynamic> ? e : {})).toList(),
      defaultModels: defaults.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

class ProviderAuthAuthorization {
  final String url;
  final String method;
  final String? instructions;

  ProviderAuthAuthorization({required this.url, required this.method, this.instructions});

  factory ProviderAuthAuthorization.fromJson(Map<String, dynamic> json) => ProviderAuthAuthorization(
        url: json['url'] as String? ?? '',
        method: json['method'] as String? ?? '',
        instructions: json['instructions'] as String?,
      );
}

class ToolIDs {
  final List<String> ids;

  ToolIDs({required this.ids});

  factory ToolIDs.fromJson(Map<String, dynamic> json) {
    final rawIDs = json['ids'];
    final list = rawIDs is List ? rawIDs : <dynamic>[];
    return ToolIDs(ids: list.map((e) => e.toString()).toList());
  }
}

class SessionMessageResponse {
  final Message info;
  final List<Part> parts;

  SessionMessageResponse({required this.info, required this.parts});

  factory SessionMessageResponse.fromJson(Map<String, dynamic> json) {
    final infoMap = json['info'] as Map<String, dynamic>? ?? {};
    final rawParts = json['parts'];
    final partsList = (rawParts is List) ? rawParts : <dynamic>[];
    final maps = partsList.map((p) => p is Map<String, dynamic> ? p : <String, dynamic>{}).toList();
    final parts = maps.map((m) => Part.fromJson(m)).toList();
    return SessionMessageResponse(
      info: Message.fromInfo(infoMap, maps),
      parts: parts,
    );
  }
}

enum AppMode { webview, native }




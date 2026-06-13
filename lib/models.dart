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
    final modelsMap = json['models'] as Map<String, dynamic>? ?? {};
    final models = modelsMap.entries.map((e) =>
      ProviderModel.fromJson(e.value as Map<String, dynamic>, providerID: id)
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

  factory Command.fromJson(Map<String, dynamic> json) => Command(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        arguments: (json['arguments'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      );
}

class DiffEntry {
  final String filePath;
  final String status;
  final List<DiffHunk> hunks;

  DiffEntry({required this.filePath, required this.status, required this.hunks});

  factory DiffEntry.fromJson(Map<String, dynamic> json) {
    final hunksList = (json['hunks'] as List<dynamic>?) ?? [];
    return DiffEntry(
      filePath: json['filePath'] as String? ?? json['path'] as String? ?? '',
      status: json['status'] as String? ?? 'modified',
      hunks: hunksList.map((e) => DiffHunk.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DiffHunk {
  final int oldStart;
  final int newStart;
  final String content;

  DiffHunk({required this.oldStart, required this.newStart, required this.content});

  factory DiffHunk.fromJson(Map<String, dynamic> json) => DiffHunk(
        oldStart: json['oldStart'] as int? ?? 0,
        newStart: json['newStart'] as int? ?? 0,
        content: json['content'] as String? ?? '',
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
    final subs = (json['submatches'] as List<dynamic>?) ?? [];
    return SearchMatch(
      path: json['path'] as String? ?? '',
      lineNumber: json['line_number'] as int? ?? 0,
      lines: json['lines'] as String? ?? '',
      submatches: subs.map((e) => SearchSubmatch.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SearchSubmatch {
  final String match;
  final int start;
  final int end;

  SearchSubmatch({required this.match, required this.start, required this.end});

  factory SearchSubmatch.fromJson(Map<String, dynamic> json) => SearchSubmatch(
        match: json['match'] as String? ?? '',
        start: json['start'] as int? ?? 0,
        end: json['end'] as int? ?? 0,
      );
}

class LSPStatus {
  final String name;
  final String state;
  final String? version;

  LSPStatus({required this.name, required this.state, this.version});

  factory LSPStatus.fromJson(Map<String, dynamic> json) => LSPStatus(
        name: json['name'] as String? ?? '',
        state: json['state'] as String? ?? json['status'] as String? ?? 'unknown',
        version: json['version'] as String?,
      );
}

class FormatterStatus {
  final String name;
  final String state;

  FormatterStatus({required this.name, required this.state});

  factory FormatterStatus.fromJson(Map<String, dynamic> json) => FormatterStatus(
        name: json['name'] as String? ?? '',
        state: json['state'] as String? ?? json['status'] as String? ?? 'unknown',
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
  final String? url;

  ProviderAuthMethod({required this.type, this.url});

  factory ProviderAuthMethod.fromJson(Map<String, dynamic> json) => ProviderAuthMethod(
        type: json['type'] as String? ?? '',
        url: json['url'] as String?,
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
  final bool done;
  final bool resolved;

  Todo({required this.id, required this.task, this.done = false, this.resolved = false});

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String? ?? '',
        task: json['task'] as String? ?? '',
        done: json['done'] as bool? ?? json['completed'] as bool? ?? false,
        resolved: json['resolved'] as bool? ?? false,
      );
}

enum AppMode { webview, native }

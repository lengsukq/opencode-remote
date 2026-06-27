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
  final String slug;
  final String title;
  final String? projectId;
  final String? workspaceId;
  final String directory;
  final String? path;
  final String? parentId;
  final String? agent;
  final SessionModelRef? model;
  final String status;
  final String version;
  final Map<String, dynamic>? metadata;
  final SessionSummary? summary;
  final double? cost;
  final SessionTokens? tokens;
  final SessionShare? share;
  final int createdAt;
  final int updatedAt;
  final int? compactingAt;
  final int? archivedAt;
  final SessionRevert? revert;

  Session({
    required this.id,
    this.slug = '',
    required this.title,
    this.projectId,
    this.workspaceId,
    this.directory = '',
    this.path,
    this.parentId,
    this.agent,
    this.model,
    this.status = 'idle',
    this.version = '',
    this.metadata,
    this.summary,
    this.cost,
    this.tokens,
    this.share,
    required this.createdAt,
    required this.updatedAt,
    this.compactingAt,
    this.archivedAt,
    this.revert,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final t = json['time'] as Map<String, dynamic>?;
    final rawModel = json['model'];
    final rawSummary = json['summary'];
    final rawTokens = json['tokens'];
    final rawShare = json['share'];
    final rawRevert = json['revert'];
    return Session(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      projectId: json['projectID'] as String?,
      workspaceId: json['workspaceID'] as String?,
      directory: json['directory'] as String? ?? '',
      path: json['path'] as String?,
      parentId: json['parentID'] as String?,
      agent: json['agent'] as String?,
      model: rawModel is Map ? SessionModelRef.fromJson(Map<String, dynamic>.from(rawModel)) : null,
      status: json['status'] as String? ?? 'idle',
      version: json['version'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      summary: rawSummary is Map ? SessionSummary.fromJson(Map<String, dynamic>.from(rawSummary)) : null,
      cost: (json['cost'] as num?)?.toDouble(),
      tokens: rawTokens is Map ? SessionTokens.fromJson(Map<String, dynamic>.from(rawTokens)) : null,
      share: rawShare is Map ? SessionShare.fromJson(Map<String, dynamic>.from(rawShare)) : null,
      createdAt: t?['created'] as int? ?? 0,
      updatedAt: t?['updated'] as int? ?? 0,
      compactingAt: t?['compacting'] as int?,
      archivedAt: t?['archived'] as int?,
      revert: rawRevert is Map ? SessionRevert.fromJson(Map<String, dynamic>.from(rawRevert)) : null,
    );
  }
}

class SessionModelRef {
  final String id;
  final String providerID;
  final String? variant;

  SessionModelRef({required this.id, required this.providerID, this.variant});

  factory SessionModelRef.fromJson(Map<String, dynamic> json) => SessionModelRef(
        id: json['id'] as String? ?? '',
        providerID: json['providerID'] as String? ?? '',
        variant: json['variant'] as String?,
      );
}

class SessionSummary {
  final int additions;
  final int deletions;
  final int files;

  SessionSummary({required this.additions, required this.deletions, required this.files});

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
        additions: json['additions'] as int? ?? 0,
        deletions: json['deletions'] as int? ?? 0,
        files: json['files'] as int? ?? 0,
      );
}

class SessionTokens {
  final int input;
  final int output;
  final int reasoning;
  final int cacheRead;
  final int cacheWrite;

  SessionTokens({
    required this.input,
    required this.output,
    required this.reasoning,
    required this.cacheRead,
    required this.cacheWrite,
  });

  factory SessionTokens.fromJson(Map<String, dynamic> json) {
    final cache = json['cache'] as Map<String, dynamic>? ?? {};
    return SessionTokens(
      input: json['input'] as int? ?? 0,
      output: json['output'] as int? ?? 0,
      reasoning: json['reasoning'] as int? ?? 0,
      cacheRead: cache['read'] as int? ?? 0,
      cacheWrite: cache['write'] as int? ?? 0,
    );
  }
}

class SessionShare {
  final String url;

  SessionShare({required this.url});

  factory SessionShare.fromJson(Map<String, dynamic> json) => SessionShare(
        url: json['url'] as String? ?? '',
      );
}

class SessionRevert {
  final String messageID;
  final String? partID;
  final String? snapshot;
  final String? diff;

  SessionRevert({required this.messageID, this.partID, this.snapshot, this.diff});

  factory SessionRevert.fromJson(Map<String, dynamic> json) => SessionRevert(
        messageID: json['messageID'] as String? ?? '',
        partID: json['partID'] as String?,
        snapshot: json['snapshot'] as String?,
        diff: json['diff'] as String?,
      );
}

class Message {
  final String id;
  final String sessionID;
  final String role;
  final String content;
  final String? reasoning;
  final int createdAt;
  final int? completedAt;
  final String? model;
  final String? agent;
  final String? mode;
  final String? parentID;
  final String? system;
  final double cost;
  final bool hasTokens;
  final int tokenInput;
  final int tokenOutput;
  final int tokenReasoning;
  final String? finish;
  final Map<String, dynamic>? error;
  final Map<String, bool>? tools;
  final String? cwd;
  final String? root;
  final List<Part> parts;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    this.sessionID = '',
    required this.role,
    required this.content,
    this.reasoning,
    required this.createdAt,
    this.completedAt,
    this.model,
    this.agent,
    this.mode,
    this.parentID,
    this.system,
    this.cost = 0,
    this.hasTokens = false,
    this.tokenInput = 0,
    this.tokenOutput = 0,
    this.tokenReasoning = 0,
    this.finish,
    this.error,
    this.tools,
    this.cwd,
    this.root,
    this.parts = const [],
    this.metadata,
  });

  bool get hasReasoning => reasoning != null && reasoning!.isNotEmpty;

  factory Message.fromInfo(Map<String, dynamic> info, List<Map<String, dynamic>> parts) {
    final role = info['role'] as String? ?? 'user';
    final time = info['time'] as Map<String, dynamic>?;
    final created = time?['created'] as int? ?? 0;
    final extracted = _extractContent(parts);
    final model = _extractModelInfo(info);
    final rawTokens = info['tokens'] as Map<String, dynamic>?;
    final rawPath = info['path'] as Map<String, dynamic>?;
    final parsedParts = parts.map((p) => Part.fromJson(p)).toList();
    final rawMetadata = info['metadata'] as Map<String, dynamic>?;
    return Message(
      id: info['id'] as String? ?? '',
      sessionID: info['sessionID'] as String? ?? '',
      role: role,
      content: extracted.content,
      reasoning: extracted.reasoning,
      parts: parsedParts,
      metadata: rawMetadata,
      createdAt: created,
      completedAt: time?['completed'] as int?,
      model: model,
      agent: info['agent'] as String?,
      mode: info['mode'] as String?,
      parentID: info['parentID'] as String?,
      system: info['system'] as String?,
      cost: (info['cost'] as num?)?.toDouble() ?? 0,
      hasTokens: rawTokens != null,
      tokenInput: rawTokens?['input'] as int? ?? 0,
      tokenOutput: rawTokens?['output'] as int? ?? 0,
      tokenReasoning: rawTokens?['reasoning'] as int? ?? 0,
      finish: info['finish'] as String?,
      error: info['error'] as Map<String, dynamic>?,
      tools: info['tools'] is Map ? Map<String, bool>.from(info['tools'] as Map) : null,
      cwd: rawPath?['cwd'] as String?,
      root: rawPath?['root'] as String?,
    );
  }

  static String? _extractModelInfo(Map<String, dynamic> info) {
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
  final double? topP;
  final double? temperature;
  final String? modelID;
  final String? providerID;
  final String? prompt;
  final Map<String, dynamic>? options;
  final int? steps;
  final bool hidden;

  Agent({
    required this.name,
    this.description,
    required this.mode,
    required this.builtIn,
    this.color,
    this.topP,
    this.temperature,
    this.modelID,
    this.providerID,
    this.prompt,
    this.options,
    this.steps,
    this.hidden = false,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    final m = json['model'] as Map<String, dynamic>?;
    return Agent(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      mode: json['mode'] as String? ?? 'subagent',
      builtIn: json['builtIn'] as bool? ?? json['native'] as bool? ?? false,
      color: json['color'] as String?,
      topP: (json['topP'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      modelID: m?['modelID'] as String?,
      providerID: m?['providerID'] as String?,
      prompt: json['prompt'] as String?,
      options: json['options'] as Map<String, dynamic>?,
      steps: json['steps'] as int?,
      hidden: json['hidden'] as bool? ?? false,
    );
  }
}

class ProviderModel {
  final String id;
  final String name;
  final String providerID;
  final String status;
  final String? family;
  final Map<String, dynamic>? api;
  final Map<String, dynamic>? capabilities;
  final Map<String, dynamic>? cost;
  final Map<String, dynamic>? limit;
  final Map<String, dynamic>? options;
  final Map<String, String>? headers;
  final String? releaseDate;
  final Map<String, dynamic>? variants;

  ProviderModel({
    required this.id,
    required this.name,
    required this.providerID,
    this.status = 'active',
    this.family,
    this.api,
    this.capabilities,
    this.cost,
    this.limit,
    this.options,
    this.headers,
    this.releaseDate,
    this.variants,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json, {required String providerID}) {
    final rawHeaders = json['headers'];
    return ProviderModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['id'] as String? ?? '',
      providerID: providerID,
      status: json['status'] as String? ?? 'active',
      family: json['family'] as String?,
      api: json['api'] as Map<String, dynamic>?,
      capabilities: json['capabilities'] as Map<String, dynamic>?,
      cost: json['cost'] as Map<String, dynamic>?,
      limit: json['limit'] as Map<String, dynamic>?,
      options: json['options'] as Map<String, dynamic>?,
      headers: rawHeaders is Map ? Map<String, String>.from(rawHeaders) : null,
      releaseDate: json['release_date'] as String?,
      variants: json['variants'] as Map<String, dynamic>?,
    );
  }

  String get fullID => '$providerID/$id';
}

class Provider {
  final String id;
  final String name;
  final List<ProviderModel> models;
  final String source;
  final List<String> env;
  final String? key;
  final Map<String, dynamic>? options;

  Provider({
    required this.id,
    required this.name,
    required this.models,
    this.source = 'env',
    this.env = const [],
    this.key,
    this.options,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? id;
    final rawModels = json['models'];
    final modelsList = rawModels is List
        ? rawModels
        : rawModels is Map ? rawModels.values.toList() : <dynamic>[];
    final rawEnv = json['env'];
    return Provider(
      id: id,
      name: name,
      models: modelsList.map((e) =>
        ProviderModel.fromJson(e is Map<String, dynamic> ? e : {}, providerID: id)
      ).toList(),
      source: json['source'] as String? ?? 'env',
      env: rawEnv is List ? rawEnv.map((e) => e.toString()).toList() : <String>[],
      key: json['key'] as String?,
      options: json['options'] as Map<String, dynamic>?,
    );
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
  final String status;
  final String? error;

  MCPStatus({required this.name, required this.status, this.error});

  bool get isConnected => status == 'connected';
  bool get isDisabled => status == 'disabled';
  bool get isFailed => status == 'failed';
  bool get needsAuth => status == 'needs_auth';

  factory MCPStatus.fromJson(Map<String, dynamic> json) => MCPStatus(
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? json['state'] as String? ?? 'unknown',
        error: json['error'] as String?,
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
  final String type;
  final int? attempt;
  final String? message;
  final int? next;

  SessionStatus({
    required this.id,
    required this.type,
    this.attempt,
    this.message,
    this.next,
  });

  bool get isIdle => type == 'idle';
  bool get isBusy => type == 'busy';
  bool get isRetry => type == 'retry';

  factory SessionStatus.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as Map<String, dynamic>? ?? {};
    return SessionStatus(
      id: json['id'] as String? ?? '',
      type: status['type'] as String? ?? 'idle',
      attempt: status['attempt'] as int?,
      message: status['message'] as String?,
      next: status['next'] as int?,
    );
  }
}

class Part {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String? text;
  final String? reasoningText;
  final ToolPartData? tool;
  final FilePartData? file;
  final SubtaskPartData? subtask;
  final StepStartPartData? stepStart;
  final StepFinishPartData? stepFinish;
  final String? snapshot;
  final PatchPartData? patch;
  final AgentPartData? agent;
  final RetryPartData? retry;
  final CompactionPartData? compaction;
  final Map<String, dynamic>? metadata;

  Part({
    required this.id,
    this.sessionID = '',
    this.messageID = '',
    required this.type,
    this.text,
    this.reasoningText,
    this.tool,
    this.file,
    this.subtask,
    this.stepStart,
    this.stepFinish,
    this.snapshot,
    this.patch,
    this.agent,
    this.retry,
    this.compaction,
    this.metadata,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return Part(
      id: json['id'] as String? ?? '',
      sessionID: json['sessionID'] as String? ?? '',
      messageID: json['messageID'] as String? ?? '',
      type: type,
      text: type == 'text' ? json['text'] as String? : null,
      reasoningText: type == 'reasoning' ? json['text'] as String? : null,
      tool: type == 'tool' ? ToolPartData.fromJson(json) : null,
      file: type == 'file' ? FilePartData.fromJson(json) : null,
      subtask: type == 'subtask' ? SubtaskPartData.fromJson(json) : null,
      stepStart: type == 'step-start' ? StepStartPartData.fromJson(json) : null,
      stepFinish: type == 'step-finish' ? StepFinishPartData.fromJson(json) : null,
      snapshot: type == 'snapshot' ? json['snapshot'] as String? : null,
      patch: type == 'patch' ? PatchPartData.fromJson(json) : null,
      agent: type == 'agent' ? AgentPartData.fromJson(json) : null,
      retry: type == 'retry' ? RetryPartData.fromJson(json) : null,
      compaction: type == 'compaction' ? CompactionPartData.fromJson(json) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class ToolPartData {
  final String callID;
  final String tool;
  final String stateStatus;
  final Map<String, dynamic>? input;
  final String? output;
  final String? error;
  final String? title;
  final int? timeStart;
  final int? timeEnd;

  ToolPartData({
    required this.callID,
    required this.tool,
    required this.stateStatus,
    this.input,
    this.output,
    this.error,
    this.title,
    this.timeStart,
    this.timeEnd,
  });

  bool get isCompleted => stateStatus == 'completed';
  bool get isRunning => stateStatus == 'running';
  bool get isPending => stateStatus == 'pending';
  bool get isError => stateStatus == 'error';

  factory ToolPartData.fromJson(Map<String, dynamic> json) {
    final state = json['state'] as Map<String, dynamic>? ?? {};
    final t = state['time'] as Map<String, dynamic>?;
    return ToolPartData(
      callID: json['callID'] as String? ?? '',
      tool: json['tool'] as String? ?? '',
      stateStatus: state['status'] as String? ?? 'pending',
      input: state['input'] as Map<String, dynamic>?,
      output: state['output'] as String?,
      error: state['error'] as String?,
      title: state['title'] as String?,
      timeStart: t?['start'] as int?,
      timeEnd: t?['end'] as int?,
    );
  }
}

class FilePartData {
  final String mime;
  final String? filename;
  final String url;

  FilePartData({required this.mime, this.filename, required this.url});

  factory FilePartData.fromJson(Map<String, dynamic> json) => FilePartData(
        mime: json['mime'] as String? ?? '',
        filename: json['filename'] as String?,
        url: json['url'] as String? ?? '',
      );
}

class SubtaskPartData {
  final String prompt;
  final String description;
  final String agent;

  SubtaskPartData({required this.prompt, required this.description, required this.agent});

  factory SubtaskPartData.fromJson(Map<String, dynamic> json) => SubtaskPartData(
        prompt: json['prompt'] as String? ?? '',
        description: json['description'] as String? ?? '',
        agent: json['agent'] as String? ?? '',
      );
}

class StepStartPartData {
  final String? snapshot;

  StepStartPartData({this.snapshot});

  factory StepStartPartData.fromJson(Map<String, dynamic> json) => StepStartPartData(
        snapshot: json['snapshot'] as String?,
      );
}

class StepFinishPartData {
  final String reason;
  final String? snapshot;
  final double cost;
  final int tokensInput;
  final int tokensOutput;
  final int tokensReasoning;

  StepFinishPartData({
    required this.reason,
    this.snapshot,
    this.cost = 0,
    this.tokensInput = 0,
    this.tokensOutput = 0,
    this.tokensReasoning = 0,
  });

  factory StepFinishPartData.fromJson(Map<String, dynamic> json) {
    final toks = json['tokens'] as Map<String, dynamic>? ?? {};
    return StepFinishPartData(
      reason: json['reason'] as String? ?? '',
      snapshot: json['snapshot'] as String?,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      tokensInput: toks['input'] as int? ?? 0,
      tokensOutput: toks['output'] as int? ?? 0,
      tokensReasoning: toks['reasoning'] as int? ?? 0,
    );
  }
}

class PatchPartData {
  final String hash;
  final List<String> files;

  PatchPartData({required this.hash, required this.files});

  factory PatchPartData.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    final files = rawFiles is List ? rawFiles.map((e) => e.toString()).toList() : <String>[];
    return PatchPartData(
      hash: json['hash'] as String? ?? '',
      files: files,
    );
  }
}

class AgentPartData {
  final String name;

  AgentPartData({required this.name});

  factory AgentPartData.fromJson(Map<String, dynamic> json) => AgentPartData(
        name: json['name'] as String? ?? '',
      );
}

class RetryPartData {
  final int attempt;
  final Map<String, dynamic>? error;

  RetryPartData({required this.attempt, this.error});

  factory RetryPartData.fromJson(Map<String, dynamic> json) => RetryPartData(
        attempt: json['attempt'] as int? ?? 0,
        error: json['error'] as Map<String, dynamic>?,
      );
}

class CompactionPartData {
  final bool auto;
  final bool? overflow;
  final String? tailStartID;

  CompactionPartData({required this.auto, this.overflow, this.tailStartID});

  factory CompactionPartData.fromJson(Map<String, dynamic> json) => CompactionPartData(
        auto: json['auto'] as bool? ?? false,
        overflow: json['overflow'] as bool?,
        tailStartID: json['tail_start_id'] as String?,
      );
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




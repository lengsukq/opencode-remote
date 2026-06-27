import 'message.dart';
import 'part.dart';

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
      model: rawModel is Map
          ? SessionModelRef.fromJson(Map<String, dynamic>.from(rawModel))
          : null,
      status: json['status'] as String? ?? 'idle',
      version: json['version'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      summary: rawSummary is Map
          ? SessionSummary.fromJson(Map<String, dynamic>.from(rawSummary))
          : null,
      cost: (json['cost'] as num?)?.toDouble(),
      tokens: rawTokens is Map
          ? SessionTokens.fromJson(Map<String, dynamic>.from(rawTokens))
          : null,
      share: rawShare is Map
          ? SessionShare.fromJson(Map<String, dynamic>.from(rawShare))
          : null,
      createdAt: t?['created'] as int? ?? 0,
      updatedAt: t?['updated'] as int? ?? 0,
      compactingAt: t?['compacting'] as int?,
      archivedAt: t?['archived'] as int?,
      revert: rawRevert is Map
          ? SessionRevert.fromJson(Map<String, dynamic>.from(rawRevert))
          : null,
    );
  }
}

class SessionModelRef {
  final String id;
  final String providerID;
  final String? variant;

  SessionModelRef({required this.id, required this.providerID, this.variant});

  factory SessionModelRef.fromJson(Map<String, dynamic> json) =>
      SessionModelRef(
        id: json['id'] as String? ?? '',
        providerID: json['providerID'] as String? ?? '',
        variant: json['variant'] as String?,
      );
}

class SessionSummary {
  final int additions;
  final int deletions;
  final int files;

  SessionSummary({
    required this.additions,
    required this.deletions,
    required this.files,
  });

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

  factory SessionShare.fromJson(Map<String, dynamic> json) =>
      SessionShare(url: json['url'] as String? ?? '');
}

class SessionRevert {
  final String messageID;
  final String? partID;
  final String? snapshot;
  final String? diff;

  SessionRevert({
    required this.messageID,
    this.partID,
    this.snapshot,
    this.diff,
  });

  factory SessionRevert.fromJson(Map<String, dynamic> json) => SessionRevert(
    messageID: json['messageID'] as String? ?? '',
    partID: json['partID'] as String?,
    snapshot: json['snapshot'] as String?,
    diff: json['diff'] as String?,
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

class SessionMessageResponse {
  final Message info;
  final List<Part> parts;

  SessionMessageResponse({required this.info, required this.parts});

  factory SessionMessageResponse.fromJson(Map<String, dynamic> json) {
    final infoMap = json['info'] as Map<String, dynamic>? ?? {};
    final rawParts = json['parts'];
    final partsList = (rawParts is List) ? rawParts : <dynamic>[];
    final maps = partsList
        .map((p) => p is Map<String, dynamic> ? p : <String, dynamic>{})
        .toList();
    final parts = maps.map((m) => Part.fromJson(m)).toList();
    return SessionMessageResponse(
      info: Message.fromInfo(infoMap, maps),
      parts: parts,
    );
  }
}

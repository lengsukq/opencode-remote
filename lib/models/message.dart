import 'part.dart';

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

  factory Message.fromInfo(
    Map<String, dynamic> info,
    List<Map<String, dynamic>> parts,
  ) {
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
      tools: info['tools'] is Map
          ? Map<String, bool>.from(info['tools'] as Map)
          : null,
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

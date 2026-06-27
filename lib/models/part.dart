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
      stepFinish: type == 'step-finish'
          ? StepFinishPartData.fromJson(json)
          : null,
      snapshot: type == 'snapshot' ? json['snapshot'] as String? : null,
      patch: type == 'patch' ? PatchPartData.fromJson(json) : null,
      agent: type == 'agent' ? AgentPartData.fromJson(json) : null,
      retry: type == 'retry' ? RetryPartData.fromJson(json) : null,
      compaction: type == 'compaction'
          ? CompactionPartData.fromJson(json)
          : null,
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

  SubtaskPartData({
    required this.prompt,
    required this.description,
    required this.agent,
  });

  factory SubtaskPartData.fromJson(Map<String, dynamic> json) =>
      SubtaskPartData(
        prompt: json['prompt'] as String? ?? '',
        description: json['description'] as String? ?? '',
        agent: json['agent'] as String? ?? '',
      );
}

class StepStartPartData {
  final String? snapshot;

  StepStartPartData({this.snapshot});

  factory StepStartPartData.fromJson(Map<String, dynamic> json) =>
      StepStartPartData(snapshot: json['snapshot'] as String?);
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
    final files = rawFiles is List
        ? rawFiles.map((e) => e.toString()).toList()
        : <String>[];
    return PatchPartData(hash: json['hash'] as String? ?? '', files: files);
  }
}

class AgentPartData {
  final String name;

  AgentPartData({required this.name});

  factory AgentPartData.fromJson(Map<String, dynamic> json) =>
      AgentPartData(name: json['name'] as String? ?? '');
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

  factory CompactionPartData.fromJson(Map<String, dynamic> json) =>
      CompactionPartData(
        auto: json['auto'] as bool? ?? false,
        overflow: json['overflow'] as bool?,
        tailStartID: json['tail_start_id'] as String?,
      );
}

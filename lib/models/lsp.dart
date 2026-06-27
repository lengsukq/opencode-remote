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

  factory FormatterStatus.fromJson(Map<String, dynamic> json) =>
      FormatterStatus(
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

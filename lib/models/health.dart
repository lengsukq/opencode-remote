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
    return path
        .split(RegExp(r'[/\\]'))
        .lastWhere((s) => s.isNotEmpty, orElse: () => '');
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

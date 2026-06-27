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

  FileContent({required this.path, required this.content, this.language = ''});

  factory FileContent.fromJson(Map<String, dynamic> json) => FileContent(
    path: json['path'] as String? ?? '',
    content: json['content'] as String? ?? '',
    language: json['language'] as String? ?? '',
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

class PathInfo {
  final String path;
  final String? directory;

  PathInfo({required this.path, this.directory});

  factory PathInfo.fromJson(Map<String, dynamic> json) => PathInfo(
    path: json['path'] as String? ?? '',
    directory: json['directory'] as String?,
  );
}

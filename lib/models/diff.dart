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
    filePath:
        json['file'] as String? ??
        json['filePath'] as String? ??
        json['path'] as String? ??
        '',
    status: json['status'] as String? ?? 'modified',
    additions: json['additions'] as int? ?? 0,
    deletions: json['deletions'] as int? ?? 0,
    patch: json['patch'] as String?,
  );
}

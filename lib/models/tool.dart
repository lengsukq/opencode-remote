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

class ToolIDs {
  final List<String> ids;

  ToolIDs({required this.ids});

  factory ToolIDs.fromJson(Map<String, dynamic> json) {
    final rawIDs = json['ids'];
    final list = rawIDs is List ? rawIDs : <dynamic>[];
    return ToolIDs(ids: list.map((e) => e.toString()).toList());
  }
}

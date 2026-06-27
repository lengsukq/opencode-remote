class Command {
  final String id;
  final String title;
  final String? description;
  final List<String>? arguments;

  Command({
    required this.id,
    required this.title,
    this.description,
    this.arguments,
  });

  factory Command.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['arguments'];
    final arguments = rawArgs is List
        ? rawArgs.map((e) => e.toString()).toList()
        : null;
    return Command(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      arguments: arguments,
    );
  }
}

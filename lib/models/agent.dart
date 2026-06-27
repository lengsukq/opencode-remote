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

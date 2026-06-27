class Config {
  final Map<String, dynamic> data;

  Config({required this.data});

  factory Config.fromJson(Map<String, dynamic> json) => Config(data: json);
}

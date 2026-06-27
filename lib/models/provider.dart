class ProviderModel {
  final String id;
  final String name;
  final String providerID;
  final String status;
  final String? family;
  final Map<String, dynamic>? api;
  final Map<String, dynamic>? capabilities;
  final Map<String, dynamic>? cost;
  final Map<String, dynamic>? limit;
  final Map<String, dynamic>? options;
  final Map<String, String>? headers;
  final String? releaseDate;
  final Map<String, dynamic>? variants;

  ProviderModel({
    required this.id,
    required this.name,
    required this.providerID,
    this.status = 'active',
    this.family,
    this.api,
    this.capabilities,
    this.cost,
    this.limit,
    this.options,
    this.headers,
    this.releaseDate,
    this.variants,
  });

  factory ProviderModel.fromJson(
    Map<String, dynamic> json, {
    required String providerID,
  }) {
    final rawHeaders = json['headers'];
    return ProviderModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['id'] as String? ?? '',
      providerID: providerID,
      status: json['status'] as String? ?? 'active',
      family: json['family'] as String?,
      api: json['api'] as Map<String, dynamic>?,
      capabilities: json['capabilities'] as Map<String, dynamic>?,
      cost: json['cost'] as Map<String, dynamic>?,
      limit: json['limit'] as Map<String, dynamic>?,
      options: json['options'] as Map<String, dynamic>?,
      headers: rawHeaders is Map ? Map<String, String>.from(rawHeaders) : null,
      releaseDate: json['release_date'] as String?,
      variants: json['variants'] as Map<String, dynamic>?,
    );
  }

  String get fullID => '$providerID/$id';
}

class Provider {
  final String id;
  final String name;
  final List<ProviderModel> models;
  final String source;
  final List<String> env;
  final String? key;
  final Map<String, dynamic>? options;

  Provider({
    required this.id,
    required this.name,
    required this.models,
    this.source = 'env',
    this.env = const [],
    this.key,
    this.options,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? id;
    final rawModels = json['models'];
    final modelsList = rawModels is List
        ? rawModels
        : rawModels is Map
        ? rawModels.values.toList()
        : <dynamic>[];
    final rawEnv = json['env'];
    return Provider(
      id: id,
      name: name,
      models: modelsList
          .map(
            (e) => ProviderModel.fromJson(
              e is Map<String, dynamic> ? e : {},
              providerID: id,
            ),
          )
          .toList(),
      source: json['source'] as String? ?? 'env',
      env: rawEnv is List
          ? rawEnv.map((e) => e.toString()).toList()
          : <String>[],
      key: json['key'] as String?,
      options: json['options'] as Map<String, dynamic>?,
    );
  }
}

class ProviderAuthMethod {
  final String type;
  final String label;

  ProviderAuthMethod({required this.type, required this.label});

  factory ProviderAuthMethod.fromJson(Map<String, dynamic> json) =>
      ProviderAuthMethod(
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class ProviderAuthAuthorization {
  final String url;
  final String method;
  final String? instructions;

  ProviderAuthAuthorization({
    required this.url,
    required this.method,
    this.instructions,
  });

  factory ProviderAuthAuthorization.fromJson(Map<String, dynamic> json) =>
      ProviderAuthAuthorization(
        url: json['url'] as String? ?? '',
        method: json['method'] as String? ?? '',
        instructions: json['instructions'] as String?,
      );
}

class ProviderDefaults {
  final List<Provider> providers;
  final Map<String, String> defaultModels;

  ProviderDefaults({required this.providers, required this.defaultModels});

  factory ProviderDefaults.fromJson(Map<String, dynamic> json) {
    final rawProviders = json['providers'];
    final providersList = rawProviders is List
        ? rawProviders
        : rawProviders is Map
        ? rawProviders.values.toList()
        : <dynamic>[];
    final rawDefaults = json['default'];
    final defaults = rawDefaults is Map
        ? Map<String, dynamic>.from(rawDefaults)
        : <String, dynamic>{};
    return ProviderDefaults(
      providers: providersList
          .map((e) => Provider.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList(),
      defaultModels: defaults.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

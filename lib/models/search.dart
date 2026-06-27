class SearchMatch {
  final String path;
  final int lineNumber;
  final String lines;
  final List<SearchSubmatch> submatches;

  SearchMatch({
    required this.path,
    required this.lineNumber,
    required this.lines,
    required this.submatches,
  });

  factory SearchMatch.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['submatches'];
    final subs = rawSubs is List ? rawSubs : <dynamic>[];
    final rawPath = json['path'];
    final rawLines = json['lines'];
    return SearchMatch(
      path: rawPath is Map
          ? rawPath['text'] as String? ?? ''
          : rawPath as String? ?? '',
      lineNumber: json['line_number'] as int? ?? 0,
      lines: rawLines is Map
          ? rawLines['text'] as String? ?? ''
          : rawLines as String? ?? '',
      submatches: subs
          .map(
            (e) => SearchSubmatch.fromJson(e is Map<String, dynamic> ? e : {}),
          )
          .toList(),
    );
  }
}

class SearchSubmatch {
  final String match;
  final int start;
  final int end;

  SearchSubmatch({required this.match, required this.start, required this.end});

  factory SearchSubmatch.fromJson(Map<String, dynamic> json) {
    final rawMatch = json['match'];
    return SearchSubmatch(
      match: rawMatch is Map
          ? rawMatch['text'] as String? ?? ''
          : rawMatch as String? ?? '',
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
    );
  }
}

class Symbol {
  final String name;
  final String path;
  final String? kind;
  final String? containerName;

  Symbol({
    required this.name,
    required this.path,
    this.kind,
    this.containerName,
  });

  factory Symbol.fromJson(Map<String, dynamic> json) => Symbol(
    name: json['name'] as String? ?? '',
    path: json['path'] as String? ?? '',
    kind: json['kind'] as String?,
    containerName: json['containerName'] as String?,
  );
}

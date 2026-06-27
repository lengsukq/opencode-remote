import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models.dart';

class OpenCodeApi {
  final String baseUrl;
  final String username;
  final String password;
  String? directory;
  late String _authHeader;

  OpenCodeApi({
    required this.baseUrl,
    this.username = 'opencode',
    this.password = '',
    this.directory,
  }) {
    final bytes = utf8.encode('$username:$password');
    _authHeader = 'Basic ${base64.encode(bytes)}';
  }

  static List<T> _safeList<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) {
    if (json is! List) return [];
    return json.map((e) {
      if (e is! Map<String, dynamic>) return null;
      try { return fromJson(e); } catch (err) { debugPrint('OpenCodeApi._safeList: $err'); return null; }
    }).whereType<T>().toList();
  }

  static Map<String, dynamic> _safeMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    debugPrint('OpenCodeApi._safeMap: expected Map<String,dynamic>, got ${json.runtimeType}: $json');
    return {};
  }

  Map<String, String> get _headers => {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      };

  Uri _buildUri(String path) {
    final uri = Uri.parse('$baseUrl$path');
    if (directory == null) return uri;
    final queryParams = uri.queryParameters;
    final allParams = Map<String, String>.from(queryParams);
    allParams['directory'] = directory!;
    return uri.replace(queryParameters: allParams);
  }

  static const _timeoutSeconds = 30;

  Future<http.Response> _get(String path) async {
    return http.get(_buildUri(path), headers: _headers)
        .timeout(const Duration(seconds: _timeoutSeconds));
  }

  Future<http.Response> _post(String path, {Map<String, dynamic>? body}) async {
    return http.post(_buildUri(path), headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(const Duration(seconds: _timeoutSeconds));
  }

  Future<http.Response> _patch(String path, {Map<String, dynamic>? body}) async {
    return http.patch(_buildUri(path), headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(const Duration(seconds: _timeoutSeconds));
  }

  Future<http.Response> _put(String path, {Map<String, dynamic>? body}) async {
    return http.put(_buildUri(path), headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(const Duration(seconds: _timeoutSeconds));
  }

  Future<http.Response> _delete(String path) async {
    return http.delete(_buildUri(path), headers: _headers)
        .timeout(const Duration(seconds: _timeoutSeconds));
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw OpenCodeApiException(res.statusCode, res.body);
    }
  }

  /// Adds [value] to [body] at [key] only if [value] is not null.
  void _addIfNotNull(Map<String, dynamic> body, String key, dynamic value) {
    if (value != null) body[key] = value;
  }

  // --- Global ---
  Future<HealthStatus> getHealth() async {
    final res = await _get('/global/health');
    _check(res);
    return HealthStatus.fromJson(_safeMap(jsonDecode(res.body)));
  }

  // --- Project ---
  Future<Project> getCurrentProject() async {
    final res = await _get('/project/current');
    _check(res);
    return Project.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<List<Project>> getProjects() async {
    final res = await _get('/project');
    _check(res);
    return _safeList(jsonDecode(res.body), Project.fromJson);
  }

  // --- Path & VCS ---
  Future<VcsInfo?> getVcs() async {
    final res = await _get('/vcs');
    _check(res);
    return VcsInfo.fromJson(_safeMap(jsonDecode(res.body)));
  }

  // --- Path ---
  Future<PathInfo> getPath() async {
    final res = await _get('/path');
    _check(res);
    return PathInfo.fromJson(_safeMap(jsonDecode(res.body)));
  }

  // --- Instance ---
  Future<void> disposeInstance() async {
    final res = await _post('/instance/dispose');
    _check(res);
  }

  // --- Session ---
  Future<List<Session>> getSessions() async {
    final res = await _get('/session');
    _check(res);
    return _safeList(jsonDecode(res.body), Session.fromJson);
  }

  Future<Session> createSession({String? parentID, String? title}) async {
    final body = <String, dynamic>{};
    _addIfNotNull(body, 'parentID', parentID);
    _addIfNotNull(body, 'title', title);
    final res = await _post('/session', body: body);
    _check(res);
    return Session.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<Session> getSession(String id) async {
    final res = await _get('/session/$id');
    _check(res);
    return Session.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<void> deleteSession(String id) async {
    final res = await _delete('/session/$id');
    _check(res);
  }

  Future<void> abortSession(String id) async {
    final res = await _post('/session/$id/abort');
    _check(res);
  }

  Future<Session> updateSession(String id, {String? title}) async {
    final body = <String, dynamic>{};
    _addIfNotNull(body, 'title', title);
    final res = await _patch('/session/$id', body: body);
    _check(res);
    return Session.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<List<Session>> getChildSessions(String id) async {
    final res = await _get('/session/$id/children');
    _check(res);
    return _safeList(jsonDecode(res.body), Session.fromJson);
  }

  Future<Session> forkSession(String id, {String? messageID}) async {
    final body = <String, dynamic>{};
    _addIfNotNull(body, 'messageID', messageID);
    final res = await _post('/session/$id/fork', body: body);
    _check(res);
    return Session.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<Session> shareSession(String id) async {
    final res = await _post('/session/$id/share');
    _check(res);
    return Session.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<Session> unshareSession(String id) async {
    final res = await _delete('/session/$id/share');
    _check(res);
    return Session.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<List<DiffEntry>> getSessionDiff(String id, {String? messageID}) async {
    var path = '/session/$id/diff';
    if (messageID != null) path += '?messageID=$messageID';
    final res = await _get(path);
    _check(res);
    return _safeList(jsonDecode(res.body), DiffEntry.fromJson);
  }

  Future<void> summarizeSession(String id, {String? providerID, String? modelID}) async {
    final body = <String, dynamic>{};
    _addIfNotNull(body, 'providerID', providerID);
    _addIfNotNull(body, 'modelID', modelID);
    final res = await _post('/session/$id/summarize', body: body);
    _check(res);
  }

  Future<void> revertMessage(String id, String messageID, {String? partID}) async {
    final body = <String, dynamic>{'messageID': messageID};
    _addIfNotNull(body, 'partID', partID);
    final res = await _post('/session/$id/revert', body: body);
    _check(res);
  }

  Future<void> unrevertMessages(String id) async {
    final res = await _post('/session/$id/unrevert');
    _check(res);
  }

  Future<List<Todo>> getSessionTodo(String id) async {
    final res = await _get('/session/$id/todo');
    _check(res);
    return _safeList(jsonDecode(res.body), Todo.fromJson);
  }

  // --- Messages ---
  Future<List<Message>> getMessages(String sessionId, {int? limit}) async {
    final query = limit != null ? '?limit=$limit' : '';
    final res = await _get('/session/$sessionId/message$query');
    _check(res);
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) {
        final info = e['info'] as Map<String, dynamic>? ?? {};
        final rawParts = e['parts'];
        final parts = (rawParts is List)
            ? rawParts.map((p) => (p is Map<String, dynamic>) ? p : <String, dynamic>{}).toList()
            : <Map<String, dynamic>>[];
        return Message.fromInfo(info, parts);
      }).toList();
    }
    return [];
  }

  Future<SessionMessageResponse> getMessageDetail(String sessionId, String messageId) async {
    final res = await _get('/session/$sessionId/message/$messageId');
    _check(res);
    return SessionMessageResponse.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<SessionMessageResponse> sendMessage(
    String sessionId, {
    String? content,
    List<Map<String, dynamic>>? parts,
    String? model,
    String? agent,
    String? messageID,
    bool? noReply,
    String? system,
    List<Map<String, dynamic>>? tools,
  }) async {
    final bodyParts = parts ?? [
      {'type': 'text', 'text': content ?? ''}
    ];
    final body = <String, dynamic>{'parts': bodyParts};
    if (model != null) body['model'] = _modelRef(model);
    _addIfNotNull(body, 'agent', agent);
    _addIfNotNull(body, 'messageID', messageID);
    _addIfNotNull(body, 'noReply', noReply);
    _addIfNotNull(body, 'system', system);
    _addIfNotNull(body, 'tools', tools);
    final res = await _post('/session/$sessionId/message', body: body);
    _check(res);
    return SessionMessageResponse.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<void> sendMessageAsync(String sessionId, {
    String? content,
    List<Map<String, dynamic>>? parts,
    String? model,
    String? agent,
    String? messageID,
    bool? noReply,
    String? system,
    List<Map<String, dynamic>>? tools,
  }) async {
    final bodyParts = parts ?? [
      {'type': 'text', 'text': content ?? ''}
    ];
    final body = <String, dynamic>{'parts': bodyParts};
    if (model != null) body['model'] = _modelRef(model);
    _addIfNotNull(body, 'agent', agent);
    _addIfNotNull(body, 'messageID', messageID);
    _addIfNotNull(body, 'noReply', noReply);
    _addIfNotNull(body, 'system', system);
    _addIfNotNull(body, 'tools', tools);
    final res = await _post('/session/$sessionId/prompt_async', body: body);
    _check(res);
  }

  static Map<String, String>? _modelRef(String model) {
    final parts = model.split('/');
    if (parts.length == 2) return {'providerID': parts[0], 'modelID': parts[1]};
    return null;
  }

  Future<SessionMessageResponse> executeCommand(
    String sessionId, {
    required String command,
    required List<String> arguments,
    String? agent,
    String? model,
    String? messageID,
  }) async {
    final body = <String, dynamic>{
      'command': command,
      'arguments': arguments,
    };
    _addIfNotNull(body, 'agent', agent);
    _addIfNotNull(body, 'model', model);
    _addIfNotNull(body, 'messageID', messageID);
    final res = await _post('/session/$sessionId/command', body: body);
    _check(res);
    return SessionMessageResponse.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<SessionMessageResponse> runShell(
    String sessionId, {
    required String command,
    String? agent,
    String? model,
  }) async {
    final body = <String, dynamic>{'command': command};
    _addIfNotNull(body, 'agent', agent);
    _addIfNotNull(body, 'model', model);
    final res = await _post('/session/$sessionId/shell', body: body);
    _check(res);
    return SessionMessageResponse.fromJson(_safeMap(jsonDecode(res.body)));
  }

  // --- Commands ---
  Future<List<Command>> getCommands() async {
    final res = await _get('/command');
    _check(res);
    return _safeList(jsonDecode(res.body), Command.fromJson);
  }

  // --- Files ---
  Future<List<FileNode>> listFiles(String path) async {
    final res = await _get('/file?path=${Uri.encodeComponent(path)}');
    _check(res);
    return _safeList(jsonDecode(res.body), FileNode.fromJson);
  }

  Future<FileContent> readFile(String path) async {
    final res = await _get('/file/content?path=${Uri.encodeComponent(path)}');
    _check(res);
    return FileContent.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<List<SearchMatch>> searchFiles(String pattern) async {
    final res = await _get('/find?pattern=${Uri.encodeComponent(pattern)}');
    _check(res);
    return _safeList(jsonDecode(res.body), SearchMatch.fromJson);
  }

  Future<List<String>> findFiles(String query, {
    String? type,
    int? limit,
    String? directory,
    bool? dirs,
  }) async {
    var path = '/find/file?query=${Uri.encodeComponent(query)}';
    if (type != null) path += '&type=$type';
    if (limit != null) path += '&limit=$limit';
    if (directory != null) path += '&directory=${Uri.encodeComponent(directory)}';
    if (dirs != null) path += '&dirs=$dirs';
    final res = await _get(path);
    _check(res);
    final data = jsonDecode(res.body);
    final list = data is List ? data : [];
    return list.map((e) => e.toString()).toList();
  }

  Future<List<Symbol>> findSymbols(String query) async {
    final res = await _get('/find/symbol?query=${Uri.encodeComponent(query)}');
    _check(res);
    return _safeList(jsonDecode(res.body), Symbol.fromJson);
  }

  // --- Config ---
  Future<Config> getConfig() async {
    final res = await _get('/config');
    _check(res);
    return Config.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<Config> patchConfig(Map<String, dynamic> updates) async {
    final res = await _patch('/config', body: updates);
    _check(res);
    return Config.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<Map<String, dynamic>> getConfigProviders() async {
    final res = await _get('/config/providers');
    _check(res);
    return _safeMap(jsonDecode(res.body));
  }

  Future<ProviderDefaults> getProviderDefaults() async {
    final res = await _get('/config/providers');
    _check(res);
    return ProviderDefaults.fromJson(_safeMap(jsonDecode(res.body)));
  }

  // --- Provider ---
  Future<List<Provider>> getProviders() async {
    final res = await _get('/provider');
    _check(res);
    final data = jsonDecode(res.body);
    final rawAll = data is Map ? data['all'] : null;
    final all = (rawAll is List) ? rawAll : <dynamic>[];
    return all.map((e) => e is Map<String, dynamic> ? Provider.fromJson(e) : null).whereType<Provider>().toList();
  }

  Future<Map<String, dynamic>> getAllProviderData() async {
    final res = await _get('/provider');
    _check(res);
    final data = jsonDecode(res.body);
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<Map<String, List<ProviderAuthMethod>>> getProviderAuth() async {
    final res = await _get('/provider/auth');
    _check(res);
    final data = _safeMap(jsonDecode(res.body));
    return data.map((k, v) {
      final list = _safeList(v, ProviderAuthMethod.fromJson);
      return MapEntry(k, list);
    });
  }

  Future<void> setAuth(String id, Map<String, dynamic> body) async {
    final res = await _put('/auth/$id', body: body);
    _check(res);
  }

  // --- Agent ---
  Future<List<Agent>> getAgents() async {
    final res = await _get('/agent');
    _check(res);
    return _safeList(jsonDecode(res.body), Agent.fromJson);
  }

  // --- LSP, Formatter, MCP ---
  Future<List<LSPStatus>> getLspStatus() async {
    final res = await _get('/lsp');
    _check(res);
    return _safeList(jsonDecode(res.body), LSPStatus.fromJson);
  }

  Future<List<FormatterStatus>> getFormatterStatus() async {
    final res = await _get('/formatter');
    _check(res);
    return _safeList(jsonDecode(res.body), FormatterStatus.fromJson);
  }

  Future<Map<String, MCPStatus>> getMcpStatus() async {
    final res = await _get('/mcp');
    _check(res);
    final data = _safeMap(jsonDecode(res.body));
    return data.map((k, v) => MapEntry(k, MCPStatus.fromJson(_safeMap(v))));
  }

  // --- Log ---
  Future<void> writeLog(String service, String level, String message, {Map<String, dynamic>? extra}) async {
    final body = <String, dynamic>{
      'service': service,
      'level': level,
      'message': message,
    };
    if (extra != null) body['extra'] = extra;
    final res = await _post('/log', body: body);
    _check(res);
  }

  // --- Session Status ---
  Future<Map<String, SessionStatus>> getSessionStatuses() async {
    final res = await _get('/session/status');
    _check(res);
    final data = _safeMap(jsonDecode(res.body));
    return data.map((k, v) => MapEntry(k, SessionStatus.fromJson(_safeMap(v))));
  }

  // --- Session Init ---
  Future<void> initSession(String id, {required String messageID, String? providerID, String? modelID}) async {
    final body = <String, dynamic>{'messageID': messageID};
    _addIfNotNull(body, 'providerID', providerID);
    _addIfNotNull(body, 'modelID', modelID);
    final res = await _post('/session/$id/init', body: body);
    _check(res);
  }

  // --- Session Permissions ---
  Future<void> respondPermission(String sessionId, String permissionID, {required String response, bool? remember}) async {
    final body = <String, dynamic>{'response': response};
    if (remember != null) body['remember'] = remember;
    final res = await _post('/session/$sessionId/permissions/$permissionID', body: body);
    _check(res);
  }

  // --- Provider OAuth ---
  Future<ProviderAuthAuthorization> oauthAuthorize(String id, {required int method}) async {
    final res = await _post('/provider/$id/oauth/authorize', body: {'method': method});
    _check(res);
    return ProviderAuthAuthorization.fromJson(_safeMap(jsonDecode(res.body)));
  }

  Future<void> oauthCallback(String id, Map<String, dynamic> body) async {
    final res = await _post('/provider/$id/oauth/callback', body: body);
    _check(res);
  }

  // --- File Status ---
  Future<List<FileStatus>> getFileStatus() async {
    final res = await _get('/file/status');
    _check(res);
    return _safeList(jsonDecode(res.body), FileStatus.fromJson);
  }

  // --- MCP ---
  Future<MCPStatus> addMcpServer(String name, Map<String, dynamic> config) async {
    final body = <String, dynamic>{'name': name, 'config': config};
    final res = await _post('/mcp', body: body);
    _check(res);
    return MCPStatus.fromJson(_safeMap(jsonDecode(res.body)));
  }

  // --- Experimental Tool ---
  Future<Map<String, dynamic>> getToolList(String provider, String model) async {
    final res = await _get('/experimental/tool?provider=${Uri.encodeComponent(provider)}&model=${Uri.encodeComponent(model)}');
    _check(res);
    return _safeMap(jsonDecode(res.body));
  }

  Future<ToolIDs> getToolIds() async {
    final res = await _get('/experimental/tool/ids');
    _check(res);
    return ToolIDs.fromJson(_safeMap(jsonDecode(res.body)));
  }
}

class OpenCodeApiException implements Exception {
  final int statusCode;
  final String body;

  OpenCodeApiException(this.statusCode, this.body);

  @override
  String toString() => 'OpenCode API Error ($statusCode): $body';
}

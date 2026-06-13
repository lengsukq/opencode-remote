import 'dart:convert';
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

  Future<http.Response> _get(String path) async {
    return http.get(_buildUri(path), headers: _headers);
  }

  Future<http.Response> _post(String path, {Map<String, dynamic>? body}) async {
    return http.post(_buildUri(path), headers: _headers, body: body != null ? jsonEncode(body) : null);
  }

  Future<http.Response> _patch(String path, {Map<String, dynamic>? body}) async {
    return http.patch(_buildUri(path), headers: _headers, body: body != null ? jsonEncode(body) : null);
  }

  Future<http.Response> _put(String path, {Map<String, dynamic>? body}) async {
    return http.put(_buildUri(path), headers: _headers, body: body != null ? jsonEncode(body) : null);
  }

  Future<http.Response> _delete(String path) async {
    return http.delete(_buildUri(path), headers: _headers);
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw OpenCodeApiException(res.statusCode, res.body);
    }
  }

  // --- Global ---
  Future<HealthStatus> getHealth() async {
    final res = await _get('/global/health');
    _check(res);
    return HealthStatus.fromJson(jsonDecode(res.body));
  }

  // --- Project ---
  Future<Project> getCurrentProject() async {
    final res = await _get('/project/current');
    _check(res);
    return Project.fromJson(jsonDecode(res.body));
  }

  Future<List<Project>> getProjects() async {
    final res = await _get('/project');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Path & VCS ---
  Future<VcsInfo?> getVcs() async {
    final res = await _get('/vcs');
    if (res.statusCode != 200) return null;
    return VcsInfo.fromJson(jsonDecode(res.body));
  }

  // --- Path ---
  Future<PathInfo> getPath() async {
    final res = await _get('/path');
    _check(res);
    return PathInfo.fromJson(jsonDecode(res.body));
  }

  // --- Instance ---
  Future<bool> disposeInstance() async {
    final res = await _post('/instance/dispose');
    return res.statusCode == 200;
  }

  // --- Session ---
  Future<List<Session>> getSessions() async {
    final res = await _get('/session');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Session.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Session> createSession({String? parentID, String? title}) async {
    final body = <String, dynamic>{};
    if (parentID != null) body['parentID'] = parentID;
    if (title != null) body['title'] = title;
    final res = await _post('/session', body: body);
    _check(res);
    return Session.fromJson(jsonDecode(res.body));
  }

  Future<Session> getSession(String id) async {
    final res = await _get('/session/$id');
    _check(res);
    return Session.fromJson(jsonDecode(res.body));
  }

  Future<bool> deleteSession(String id) async {
    final res = await _delete('/session/$id');
    return res.statusCode == 200;
  }

  Future<bool> abortSession(String id) async {
    final res = await _post('/session/$id/abort');
    return res.statusCode == 200;
  }

  Future<Session> updateSession(String id, {String? title}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    final res = await _patch('/session/$id', body: body);
    _check(res);
    return Session.fromJson(jsonDecode(res.body));
  }

  Future<List<Session>> getChildSessions(String id) async {
    final res = await _get('/session/$id/children');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Session.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Session> forkSession(String id, {String? messageID}) async {
    final body = <String, dynamic>{};
    if (messageID != null) body['messageID'] = messageID;
    final res = await _post('/session/$id/fork', body: body);
    _check(res);
    return Session.fromJson(jsonDecode(res.body));
  }

  Future<Session> shareSession(String id) async {
    final res = await _post('/session/$id/share');
    _check(res);
    return Session.fromJson(jsonDecode(res.body));
  }

  Future<Session> unshareSession(String id) async {
    final res = await _delete('/session/$id/share');
    _check(res);
    return Session.fromJson(jsonDecode(res.body));
  }

  Future<List<DiffEntry>> getSessionDiff(String id, {String? messageID}) async {
    var path = '/session/$id/diff';
    if (messageID != null) path += '?messageID=$messageID';
    final res = await _get(path);
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => DiffEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> summarizeSession(String id, {String? providerID, String? modelID}) async {
    final body = <String, dynamic>{};
    if (providerID != null) body['providerID'] = providerID;
    if (modelID != null) body['modelID'] = modelID;
    final res = await _post('/session/$id/summarize', body: body);
    return res.statusCode == 200;
  }

  Future<bool> revertMessage(String id, String messageID, {String? partID}) async {
    final body = <String, dynamic>{'messageID': messageID};
    if (partID != null) body['partID'] = partID;
    final res = await _post('/session/$id/revert', body: body);
    return res.statusCode == 200;
  }

  Future<bool> unrevertMessages(String id) async {
    final res = await _post('/session/$id/unrevert');
    return res.statusCode == 200;
  }

  Future<List<Todo>> getSessionTodo(String id) async {
    final res = await _get('/session/$id/todo');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
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
        final parts = (e['parts'] as List<dynamic>?)
                ?.map((p) => p as Map<String, dynamic>)
                .toList() ??
            [];
        return Message.fromInfo(info, parts);
      }).toList();
    }
    return [];
  }

  Future<SessionMessageResponse> getMessageDetail(String sessionId, String messageId) async {
    final res = await _get('/session/$sessionId/message/$messageId');
    _check(res);
    return SessionMessageResponse.fromJson(jsonDecode(res.body));
  }

  Future<SessionMessageResponse> sendMessage(
    String sessionId, {
    required String content,
    String? model,
    String? agent,
    String? messageID,
    bool? noReply,
    String? system,
    List<Map<String, dynamic>>? tools,
  }) async {
    final bodyParts = [
      {'type': 'text', 'text': content}
    ];
    final body = <String, dynamic>{'parts': bodyParts};
    if (model != null) body['model'] = model;
    if (agent != null) body['agent'] = agent;
    if (messageID != null) body['messageID'] = messageID;
    if (noReply != null) body['noReply'] = noReply;
    if (system != null) body['system'] = system;
    if (tools != null) body['tools'] = tools;
    final res = await _post('/session/$sessionId/message', body: body);
    _check(res);
    return SessionMessageResponse.fromJson(jsonDecode(res.body));
  }

  Future<void> sendMessageAsync(String sessionId, String content, {
    String? model,
    String? agent,
    String? messageID,
    bool? noReply,
    String? system,
    List<Map<String, dynamic>>? tools,
  }) async {
    final bodyParts = [
      {'type': 'text', 'text': content}
    ];
    final body = <String, dynamic>{'parts': bodyParts};
    if (model != null) body['model'] = model;
    if (agent != null) body['agent'] = agent;
    if (messageID != null) body['messageID'] = messageID;
    if (noReply != null) body['noReply'] = noReply;
    if (system != null) body['system'] = system;
    if (tools != null) body['tools'] = tools;
    final res = await _post('/session/$sessionId/prompt_async', body: body);
    if (res.statusCode != 204) {
      throw OpenCodeApiException(res.statusCode, res.body);
    }
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
    if (agent != null) body['agent'] = agent;
    if (model != null) body['model'] = model;
    if (messageID != null) body['messageID'] = messageID;
    final res = await _post('/session/$sessionId/command', body: body);
    _check(res);
    return SessionMessageResponse.fromJson(jsonDecode(res.body));
  }

  Future<SessionMessageResponse> runShell(
    String sessionId, {
    required String command,
    String? agent,
    String? model,
  }) async {
    final body = <String, dynamic>{'command': command};
    if (agent != null) body['agent'] = agent;
    if (model != null) body['model'] = model;
    final res = await _post('/session/$sessionId/shell', body: body);
    _check(res);
    return SessionMessageResponse.fromJson(jsonDecode(res.body));
  }

  // --- Commands ---
  Future<List<Command>> getCommands() async {
    final res = await _get('/command');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Command.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Files ---
  Future<List<FileNode>> listFiles(String path) async {
    final res = await _get('/file?path=${Uri.encodeComponent(path)}');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => FileNode.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FileContent> readFile(String path) async {
    final res = await _get('/file/content?path=${Uri.encodeComponent(path)}');
    _check(res);
    return FileContent.fromJson(jsonDecode(res.body));
  }

  Future<List<SearchMatch>> searchFiles(String pattern) async {
    final res = await _get('/find?pattern=${Uri.encodeComponent(pattern)}');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => SearchMatch.fromJson(e as Map<String, dynamic>)).toList();
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
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  Future<List<Symbol>> findSymbols(String query) async {
    final res = await _get('/find/symbol?query=${Uri.encodeComponent(query)}');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Symbol.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Config ---
  Future<Config> getConfig() async {
    final res = await _get('/config');
    _check(res);
    return Config.fromJson(jsonDecode(res.body));
  }

  Future<Config> patchConfig(Map<String, dynamic> updates) async {
    final res = await _patch('/config', body: updates);
    _check(res);
    return Config.fromJson(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> getConfigProviders() async {
    final res = await _get('/config/providers');
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<ProviderDefaults> getProviderDefaults() async {
    final res = await _get('/config/providers');
    _check(res);
    return ProviderDefaults.fromJson(jsonDecode(res.body));
  }

  // --- Provider ---
  Future<List<Provider>> getProviders() async {
    final res = await _get('/provider');
    _check(res);
    final data = jsonDecode(res.body);
    final all = data['all'] as List<dynamic>? ?? [];
    return all.map((e) => Provider.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Set<String>> getConnectedProviders() async {
    final res = await _get('/provider');
    _check(res);
    final data = jsonDecode(res.body);
    final connected = (data['connected'] as List<dynamic>?)?.map((e) => e as String).toSet() ?? {};
    return connected;
  }

  Future<Map<String, String>> getProviderDefaultModels() async {
    final res = await _get('/provider');
    _check(res);
    final data = jsonDecode(res.body);
    final defaults = data['default'] as Map<String, dynamic>? ?? {};
    return defaults.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<Map<String, List<ProviderAuthMethod>>> getProviderAuth() async {
    final res = await _get('/provider/auth');
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data.map((k, v) {
      final list = (v as List<dynamic>?)?.map((e) => ProviderAuthMethod.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      return MapEntry(k, list);
    });
  }

  Future<bool> setAuth(String id, Map<String, dynamic> body) async {
    final res = await _put('/auth/$id', body: body);
    return res.statusCode == 200;
  }

  // --- Agent ---
  Future<List<Agent>> getAgents() async {
    final res = await _get('/agent');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Agent.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- LSP, Formatter, MCP ---
  Future<List<LSPStatus>> getLspStatus() async {
    final res = await _get('/lsp');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => LSPStatus.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FormatterStatus>> getFormatterStatus() async {
    final res = await _get('/formatter');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => FormatterStatus.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, MCPStatus>> getMcpStatus() async {
    final res = await _get('/mcp');
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, MCPStatus.fromJson(v as Map<String, dynamic>)));
  }

  // --- Log ---
  Future<bool> writeLog(String service, String level, String message, {Map<String, dynamic>? extra}) async {
    final body = <String, dynamic>{
      'service': service,
      'level': level,
      'message': message,
    };
    if (extra != null) body['extra'] = extra;
    final res = await _post('/log', body: body);
    return res.statusCode == 200;
  }

  // --- Session Status ---
  Future<Map<String, SessionStatus>> getSessionStatuses() async {
    final res = await _get('/session/status');
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, SessionStatus.fromJson(v as Map<String, dynamic>)));
  }

  // --- Session Init ---
  Future<bool> initSession(String id, {required String messageID, String? providerID, String? modelID}) async {
    final body = <String, dynamic>{'messageID': messageID};
    if (providerID != null) body['providerID'] = providerID;
    if (modelID != null) body['modelID'] = modelID;
    final res = await _post('/session/$id/init', body: body);
    return res.statusCode == 200;
  }

  // --- Session Permissions ---
  Future<bool> respondPermission(String sessionId, String permissionID, {required String response, bool? remember}) async {
    final body = <String, dynamic>{'response': response};
    if (remember != null) body['remember'] = remember;
    final res = await _post('/session/$sessionId/permissions/$permissionID', body: body);
    return res.statusCode == 200;
  }

  // --- Provider OAuth ---
  Future<ProviderAuthAuthorization> oauthAuthorize(String id) async {
    final res = await _post('/provider/$id/oauth/authorize');
    _check(res);
    return ProviderAuthAuthorization.fromJson(jsonDecode(res.body));
  }

  Future<bool> oauthCallback(String id, Map<String, dynamic> body) async {
    final res = await _post('/provider/$id/oauth/callback', body: body);
    return res.statusCode == 200;
  }

  // --- File Status ---
  Future<List<FileStatus>> getFileStatus() async {
    final res = await _get('/file/status');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => FileStatus.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- MCP ---
  Future<MCPStatus> addMcpServer(String name, Map<String, dynamic> config) async {
    final body = <String, dynamic>{'name': name, 'config': config};
    final res = await _post('/mcp', body: body);
    _check(res);
    return MCPStatus.fromJson(jsonDecode(res.body));
  }

  // --- Experimental Tool ---
  Future<Map<String, dynamic>> getToolList(String provider, String model) async {
    final res = await _get('/experimental/tool?provider=${Uri.encodeComponent(provider)}&model=${Uri.encodeComponent(model)}');
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<ToolIDs> getToolIds() async {
    final res = await _get('/experimental/tool/ids');
    _check(res);
    return ToolIDs.fromJson(jsonDecode(res.body));
  }
}

class OpenCodeApiException implements Exception {
  final int statusCode;
  final String body;

  OpenCodeApiException(this.statusCode, this.body);

  @override
  String toString() => 'OpenCode API Error ($statusCode): $body';
}

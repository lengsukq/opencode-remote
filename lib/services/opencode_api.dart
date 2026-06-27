import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import '../strings.dart';

class OpenCodeApiException implements Exception {
  final int statusCode;
  final String body;
  OpenCodeApiException(this.statusCode, this.body);

  String get friendlyMessage {
    if (statusCode == 401) return S.errorAuthFailed;
    if (statusCode == 403) return S.errorPermissionDenied;
    if (statusCode == 404) return S.errorNotFound;
    if (statusCode >= 500) return S.errorServerError;
    return S.errorUnknown;
  }

  @override
  String toString() => 'OpenCodeApiException($statusCode): $body';
}

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

  // -- HTTP Helpers --
  static List<T> safeList<T>(
    dynamic json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json is! List) return [];
    return json
        .map((e) {
          if (e is! Map<String, dynamic>) return null;
          try {
            return fromJson(e);
          } catch (err) {
            _log('safeList: $err');
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }

  static Map<String, dynamic> safeMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    _log('safeMap: expected Map, got ${json.runtimeType}: $json');
    return {};
  }

  static void _log(String m) {
    if (kDebugMode) debugPrint(m);
  }

  Map<String, String> get headers => {
    'Authorization': _authHeader,
    'Content-Type': 'application/json',
  };

  Uri buildUri(String path) {
    final uri = Uri.parse('$baseUrl$path');
    if (directory == null) return uri;
    final params = Map<String, String>.from(uri.queryParameters);
    params['directory'] = directory!;
    return uri.replace(queryParameters: params);
  }

  static const _timeout = Duration(seconds: 30);
  static const _maxRetries = 3;
  static const _retryDelays = [1, 2, 4];

  Future<http.Response> _retryable(
    Future<http.Response> Function() request,
  ) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await request().timeout(_timeout);
        if (response.statusCode < 400 || response.statusCode == 408) {
          return response;
        }
        if (attempt == _maxRetries - 1) return response;
      } on TimeoutException {
        if (attempt == _maxRetries - 1) rethrow;
      } catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
      }
      if (attempt < _maxRetries - 1) {
        await Future.delayed(Duration(seconds: _retryDelays[attempt]));
      }
    }
    throw TimeoutException('Request failed after $_maxRetries attempts');
  }

  Future<http.Response> httpGet(String p) =>
      _retryable(() => http.get(buildUri(p), headers: headers));
  Future<http.Response> httpPost(String p, {Map<String, dynamic>? body}) =>
      _retryable(
        () => http.post(
          buildUri(p),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
      );
  Future<http.Response> httpPatch(String p, {Map<String, dynamic>? body}) =>
      _retryable(
        () => http.patch(
          buildUri(p),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
      );
  Future<http.Response> httpPut(String p, {Map<String, dynamic>? body}) =>
      _retryable(
        () => http.put(
          buildUri(p),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
      );
  Future<http.Response> httpDelete(String p) =>
      _retryable(() => http.delete(buildUri(p), headers: headers));

  void check(http.Response r) {
    if (r.statusCode >= 400) throw OpenCodeApiException(r.statusCode, r.body);
  }

  void addIfNotNull(Map<String, dynamic> b, String k, dynamic v) {
    if (v != null) b[k] = v;
  }

  static Map<String, String>? modelRef(String model) {
    final parts = model.split('/');
    return parts.length == 2
        ? {'providerID': parts[0], 'modelID': parts[1]}
        : null;
  }

  // -- Global / Health --
  Future<HealthStatus> getHealth() async {
    final r = await httpGet('/global/health');
    check(r);
    return HealthStatus.fromJson(safeMap(jsonDecode(r.body)));
  }

  // -- Project --
  Future<Project> getCurrentProject() async {
    final r = await httpGet('/project/current');
    check(r);
    return Project.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<List<Project>> getProjects() async {
    final r = await httpGet('/project');
    check(r);
    return safeList(jsonDecode(r.body), Project.fromJson);
  }

  Future<Project> addProject(String worktree) async {
    final r = await httpPost('/project', body: {'worktree': worktree});
    check(r);
    return Project.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<void> removeProject(String id) async {
    final r = await httpDelete('/project/$id');
    check(r);
  }

  Future<VcsInfo?> getVcs() async {
    final r = await httpGet('/vcs');
    check(r);
    return VcsInfo.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<PathInfo> getPath() async {
    final r = await httpGet('/path');
    check(r);
    return PathInfo.fromJson(safeMap(jsonDecode(r.body)));
  }

  // -- Instance --
  Future<void> disposeInstance() async {
    final r = await httpPost('/instance/dispose');
    check(r);
  }

  // -- Session CRUD --
  Future<List<Session>> getSessions() async {
    final r = await httpGet('/session');
    check(r);
    return safeList(jsonDecode(r.body), Session.fromJson);
  }

  Future<Session> createSession({String? parentID, String? title}) async {
    final b = <String, dynamic>{};
    addIfNotNull(b, 'parentID', parentID);
    addIfNotNull(b, 'title', title);
    final r = await httpPost('/session', body: b);
    check(r);
    return Session.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<Session> getSession(String id) async {
    final r = await httpGet('/session/$id');
    check(r);
    return Session.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<void> deleteSession(String id) async {
    final r = await httpDelete('/session/$id');
    check(r);
  }

  Future<void> abortSession(String id) async {
    final r = await httpPost('/session/$id/abort');
    check(r);
  }

  Future<Session> updateSession(String id, {String? title}) async {
    final b = <String, dynamic>{};
    addIfNotNull(b, 'title', title);
    final r = await httpPatch('/session/$id', body: b);
    check(r);
    return Session.fromJson(safeMap(jsonDecode(r.body)));
  }

  // -- Session Actions --
  Future<List<Session>> getChildSessions(String id) async {
    final r = await httpGet('/session/$id/children');
    check(r);
    return safeList(jsonDecode(r.body), Session.fromJson);
  }

  Future<Session> forkSession(String id, {String? messageID}) async {
    final b = <String, dynamic>{};
    addIfNotNull(b, 'messageID', messageID);
    final r = await httpPost('/session/$id/fork', body: b);
    check(r);
    return Session.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<Session> shareSession(String id) async {
    final r = await httpPost('/session/$id/share');
    check(r);
    return Session.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<Session> unshareSession(String id) async {
    final r = await httpDelete('/session/$id/share');
    check(r);
    return Session.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<List<DiffEntry>> getSessionDiff(String id, {String? messageID}) async {
    var p = '/session/$id/diff';
    if (messageID != null) p += '?messageID=$messageID';
    final r = await httpGet(p);
    check(r);
    return safeList(jsonDecode(r.body), DiffEntry.fromJson);
  }

  Future<void> summarizeSession(
    String id, {
    String? providerID,
    String? modelID,
  }) async {
    final b = <String, dynamic>{};
    addIfNotNull(b, 'providerID', providerID);
    addIfNotNull(b, 'modelID', modelID);
    final r = await httpPost('/session/$id/summarize', body: b);
    check(r);
  }

  Future<void> revertMessage(
    String id,
    String messageID, {
    String? partID,
  }) async {
    final b = <String, dynamic>{'messageID': messageID};
    addIfNotNull(b, 'partID', partID);
    final r = await httpPost('/session/$id/revert', body: b);
    check(r);
  }

  Future<void> unrevertMessages(String id) async {
    final r = await httpPost('/session/$id/unrevert');
    check(r);
  }

  Future<List<Todo>> getSessionTodo(String id) async {
    final r = await httpGet('/session/$id/todo');
    check(r);
    return safeList(jsonDecode(r.body), Todo.fromJson);
  }

  // -- Messages --
  Future<List<Message>> getMessages(String sessionId, {int? limit}) async {
    final q = limit != null ? '?limit=$limit' : '';
    final r = await httpGet('/session/$sessionId/message$q');
    check(r);
    final data = jsonDecode(r.body);
    if (data is List) {
      return data.map((e) {
        final info = e['info'] as Map<String, dynamic>? ?? {};
        final rawParts = e['parts'];
        final parts = (rawParts is List)
            ? rawParts
                  .map(
                    (p) =>
                        (p is Map<String, dynamic>) ? p : <String, dynamic>{},
                  )
                  .toList()
            : <Map<String, dynamic>>[];
        return Message.fromInfo(info, parts);
      }).toList();
    }
    return [];
  }

  Future<SessionMessageResponse> getMessageDetail(
    String sessionId,
    String messageId,
  ) async {
    final r = await httpGet('/session/$sessionId/message/$messageId');
    check(r);
    return SessionMessageResponse.fromJson(safeMap(jsonDecode(r.body)));
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
    final bodyParts =
        parts ??
        [
          {'type': 'text', 'text': content ?? ''},
        ];
    final b = <String, dynamic>{'parts': bodyParts};
    if (model != null) b['model'] = modelRef(model);
    addIfNotNull(b, 'agent', agent);
    addIfNotNull(b, 'messageID', messageID);
    addIfNotNull(b, 'noReply', noReply);
    addIfNotNull(b, 'system', system);
    addIfNotNull(b, 'tools', tools);
    final r = await httpPost('/session/$sessionId/message', body: b);
    check(r);
    return SessionMessageResponse.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<void> sendMessageAsync(
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
    final bodyParts =
        parts ??
        [
          {'type': 'text', 'text': content ?? ''},
        ];
    final b = <String, dynamic>{'parts': bodyParts};
    if (model != null) b['model'] = modelRef(model);
    addIfNotNull(b, 'agent', agent);
    addIfNotNull(b, 'messageID', messageID);
    addIfNotNull(b, 'noReply', noReply);
    addIfNotNull(b, 'system', system);
    addIfNotNull(b, 'tools', tools);
    final r = await httpPost('/session/$sessionId/prompt_async', body: b);
    check(r);
  }

  // -- Terminal / Shell --
  Future<SessionMessageResponse> executeCommand(
    String sessionId, {
    required String command,
    required List<String> arguments,
    String? agent,
    String? model,
    String? messageID,
  }) async {
    final b = <String, dynamic>{'command': command, 'arguments': arguments};
    addIfNotNull(b, 'agent', agent);
    addIfNotNull(b, 'model', model);
    addIfNotNull(b, 'messageID', messageID);
    final r = await httpPost('/session/$sessionId/command', body: b);
    check(r);
    return SessionMessageResponse.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<SessionMessageResponse> runShell(
    String sessionId, {
    required String command,
    String? agent,
    String? model,
  }) async {
    final b = <String, dynamic>{'command': command};
    addIfNotNull(b, 'agent', agent);
    addIfNotNull(b, 'model', model);
    final r = await httpPost('/session/$sessionId/shell', body: b);
    check(r);
    return SessionMessageResponse.fromJson(safeMap(jsonDecode(r.body)));
  }

  // -- Commands --
  Future<List<Command>> getCommands() async {
    final r = await httpGet('/command');
    check(r);
    return safeList(jsonDecode(r.body), Command.fromJson);
  }

  // -- Session Status / Init / Permissions --
  Future<Map<String, SessionStatus>> getSessionStatuses() async {
    final r = await httpGet('/session/status');
    check(r);
    return safeMap(
      jsonDecode(r.body),
    ).map((k, v) => MapEntry(k, SessionStatus.fromJson(safeMap(v))));
  }

  Future<void> initSession(
    String id, {
    required String messageID,
    String? providerID,
    String? modelID,
  }) async {
    final b = <String, dynamic>{'messageID': messageID};
    addIfNotNull(b, 'providerID', providerID);
    addIfNotNull(b, 'modelID', modelID);
    final r = await httpPost('/session/$id/init', body: b);
    check(r);
  }

  Future<void> respondPermission(
    String sessionId,
    String permissionID, {
    required String response,
    bool? remember,
  }) async {
    final b = <String, dynamic>{'response': response};
    if (remember != null) b['remember'] = remember;
    final r = await httpPost(
      '/session/$sessionId/permissions/$permissionID',
      body: b,
    );
    check(r);
  }

  // -- Files --
  Future<List<FileNode>> listFiles(String path) async {
    final r = await httpGet('/file/browse?path=$path');
    check(r);
    return safeList(jsonDecode(r.body), FileNode.fromJson);
  }

  Future<FileContent> readFile(String path) async {
    final r = await httpGet('/file/read?path=$path');
    check(r);
    return FileContent.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<List<String>> findFiles(String query) async {
    final r = await httpGet('/file/find?pattern=$query');
    check(r);
    final data = jsonDecode(r.body);
    return data is List ? data.whereType<String>().toList() : [];
  }

  Future<List<SearchMatch>> searchFiles(String query) async {
    final r = await httpGet('/file/search?query=$query');
    check(r);
    return safeList(jsonDecode(r.body), SearchMatch.fromJson);
  }

  Future<List<Symbol>> findSymbols(String query) async {
    final r = await httpGet('/file/symbol?query=$query');
    check(r);
    return safeList(jsonDecode(r.body), Symbol.fromJson);
  }

  Future<List<FileStatus>> getFileStatus() async {
    final r = await httpGet('/file/status');
    check(r);
    return safeList(jsonDecode(r.body), FileStatus.fromJson);
  }

  // -- Config --
  Future<Config> getConfig() async {
    final r = await httpGet('/config');
    check(r);
    return Config.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<Config> patchConfig(Map<String, dynamic> updates) async {
    final r = await httpPatch('/config', body: updates);
    check(r);
    return Config.fromJson(safeMap(jsonDecode(r.body)));
  }

  Future<Map<String, dynamic>> getConfigProviders() async {
    final r = await httpGet('/config/providers');
    check(r);
    return safeMap(jsonDecode(r.body));
  }

  Future<ProviderDefaults> getProviderDefaults() async {
    final r = await httpGet('/config/providers');
    check(r);
    return ProviderDefaults.fromJson(safeMap(jsonDecode(r.body)));
  }

  // -- Providers & Auth --
  Future<List<Provider>> getProviders() async {
    final r = await httpGet('/provider');
    check(r);
    final data = jsonDecode(r.body);
    final rawAll = data is Map ? data['all'] : null;
    final all = (rawAll is List) ? rawAll : <dynamic>[];
    return all
        .map((e) => e is Map<String, dynamic> ? Provider.fromJson(e) : null)
        .whereType<Provider>()
        .toList();
  }

  Future<Map<String, dynamic>> getAllProviderData() async {
    final r = await httpGet('/provider');
    check(r);
    final data = jsonDecode(r.body);
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<Map<String, List<ProviderAuthMethod>>> getProviderAuth() async {
    final r = await httpGet('/provider/auth');
    check(r);
    return safeMap(
      jsonDecode(r.body),
    ).map((k, v) => MapEntry(k, safeList(v, ProviderAuthMethod.fromJson)));
  }

  Future<void> setAuth(String id, Map<String, dynamic> body) async {
    final r = await httpPut('/auth/$id', body: body);
    check(r);
  }

  // -- Agents --
  Future<List<Agent>> getAgents() async {
    final r = await httpGet('/agent');
    check(r);
    return safeList(jsonDecode(r.body), Agent.fromJson);
  }

  // -- Extensions (LSP / Formatter / MCP) --
  Future<List<LSPStatus>> getLspStatus() async {
    final r = await httpGet('/lsp');
    check(r);
    return safeList(jsonDecode(r.body), LSPStatus.fromJson);
  }

  Future<List<FormatterStatus>> getFormatterStatus() async {
    final r = await httpGet('/formatter');
    check(r);
    return safeList(jsonDecode(r.body), FormatterStatus.fromJson);
  }

  Future<Map<String, MCPStatus>> getMcpStatus() async {
    final r = await httpGet('/mcp');
    check(r);
    return safeMap(
      jsonDecode(r.body),
    ).map((k, v) => MapEntry(k, MCPStatus.fromJson(safeMap(v))));
  }

  // -- Log --
  Future<void> writeLog(
    String service,
    String level,
    String message, {
    Map<String, dynamic>? extra,
  }) async {
    final b = <String, dynamic>{
      'service': service,
      'level': level,
      'message': message,
    };
    if (extra != null) b['extra'] = extra;
    final r = await httpPost('/log', body: b);
    check(r);
  }

  // -- Provider OAuth --
  Future<ProviderAuthAuthorization> oauthAuthorize(
    String id, {
    required int method,
  }) async {
    final r = await httpPost(
      '/provider/$id/oauth/authorize',
      body: {'method': method},
    );
    check(r);
    return ProviderAuthAuthorization.fromJson(safeMap(jsonDecode(r.body)));
  }

  // -- Experimental --
  Future<bool> getCurrentModelConfigured({
    String? providerID,
    String? modelID,
  }) async {
    final b = <String, dynamic>{};
    addIfNotNull(b, 'providerID', providerID);
    addIfNotNull(b, 'modelID', modelID);
    final r = await httpPost('/model/current/configured', body: b);
    check(r);
    return r.body.toLowerCase() == 'true';
  }
}

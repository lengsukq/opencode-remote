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

  Future<http.Response> _delete(String path) async {
    return http.delete(_buildUri(path), headers: _headers);
  }

  Future<HealthStatus> getHealth() async {
    final res = await _get('/global/health');
    _check(res);
    return HealthStatus.fromJson(jsonDecode(res.body));
  }

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

  Future<VcsInfo?> getVcs() async {
    final res = await _get('/vcs');
    if (res.statusCode != 200) return null;
    return VcsInfo.fromJson(jsonDecode(res.body));
  }

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

  Future<void> abortSession(String id) async {
    await _post('/session/$id/abort');
  }

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

  Future<void> sendMessageAsync(String sessionId, String content, {String? model, String? agent}) async {
    final bodyParts = [
      {'type': 'text', 'text': content}
    ];
    final body = <String, dynamic>{'parts': bodyParts};
    if (model != null) {
      final parts = model.split('/');
      body['model'] = {'providerID': parts[0], 'modelID': parts.sublist(1).join('/')};
    }
    if (agent != null) body['agent'] = agent;
    final res = await _post('/session/$sessionId/prompt_async', body: body);
    if (res.statusCode != 204) {
      throw OpenCodeApiException(res.statusCode, res.body);
    }
  }

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

  Future<Config> getConfig() async {
    final res = await _get('/config');
    _check(res);
    return Config.fromJson(jsonDecode(res.body));
  }

  Future<List<Agent>> getAgents() async {
    final res = await _get('/agent');
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Agent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Provider>> getProviders() async {
    final res = await _get('/provider');
    _check(res);
    final data = jsonDecode(res.body);
    final all = data['all'] as List<dynamic>? ?? [];
    return all.map((e) => Provider.fromJson(e as Map<String, dynamic>)).toList();
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw OpenCodeApiException(res.statusCode, res.body);
    }
  }
}

class OpenCodeApiException implements Exception {
  final int statusCode;
  final String body;

  OpenCodeApiException(this.statusCode, this.body);

  @override
  String toString() => 'OpenCode API Error ($statusCode): $body';
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum EventType {
  messageNew,
  sessionUpdated,
  sessionStatus,
  unknown,
}

class ServerEvent {
  final EventType type;
  final Map<String, dynamic> data;
  final String rawType;

  ServerEvent({required this.type, required this.data, required this.rawType});
}

class EventService {
  final String baseUrl;
  final String username;
  final String password;
  http.Client? _client;
  StreamSubscription<String>? _subscription;
  bool _cancelled = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  final _controller = StreamController<ServerEvent>.broadcast();
  Stream<ServerEvent> get events => _controller.stream;

  EventService({
    required this.baseUrl,
    this.username = 'opencode',
    this.password = '',
  });

  String get _authHeader {
    final bytes = utf8.encode('$username:$password');
    return 'Basic ${base64.encode(bytes)}';
  }

  Future<void> connect() async {
    _cancelled = false;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_cancelled) return;
    try {
      final uri = Uri.parse('$baseUrl/event');
      final request = http.Request('GET', uri);
      request.headers['Authorization'] = _authHeader;
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      _client = http.Client();
      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        _scheduleReconnect();
        return;
      }

      _reconnectAttempts = 0;

      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        _onLine,
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('EventService._doConnect: $e');
      _scheduleReconnect();
    }
  }

  String? _currentEvent;
  final _dataBuffer = StringBuffer();

  void _onLine(String line) {
    if (line.startsWith('event: ')) {
      _currentEvent = line.substring(7).trim();
    } else if (line.startsWith('data: ')) {
      _dataBuffer.write(line.substring(6));
    } else if (line.isEmpty && _currentEvent != null) {
      _emitEvent();
    }
  }

  void _emitEvent() {
    final eventType = _currentEvent ?? '';
    final rawData = _dataBuffer.toString().trim();
    _dataBuffer.clear();
    _currentEvent = null;

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(rawData);
      data = decoded is Map<String, dynamic> ? decoded : {'raw': rawData, 'decoded': decoded};
    } catch (e) {
      debugPrint('EventService._emitEvent json parse: $e');
      data = {'raw': rawData};
    }

    EventType type;
    if (eventType == 'message.new') {
      type = EventType.messageNew;
    } else if (eventType == 'session.updated') {
      type = EventType.sessionUpdated;
    } else if (eventType == 'session.status') {
      type = EventType.sessionStatus;
    } else {
      type = EventType.unknown;
    }

    if (!_cancelled) {
      _controller.add(ServerEvent(type: type, data: data, rawType: eventType));
    }
  }

  void _scheduleReconnect() {
    if (_cancelled) return;
    _reconnectAttempts++;
    final delay = Duration(
      seconds: (_reconnectAttempts * 2).clamp(1, 30),
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _doConnect);
  }

  Future<void> disconnect() async {
    _cancelled = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _client?.close();
    _subscription = null;
    _client = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}

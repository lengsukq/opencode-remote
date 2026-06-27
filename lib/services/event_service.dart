import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum EventType {
  messageNew,
  sessionUpdated,
  sessionStatus,
  messagePartDelta,
  permissionAsked,
  questionAsked,
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
  Timer? _heartbeatTimer;
  DateTime _lastEventTime = DateTime.now();
  static const _heartbeatInterval = Duration(seconds: 30);
  static const _heartbeatTimeout = Duration(seconds: 60);

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
      final uri = Uri.parse('$baseUrl/global/event');
      final request = http.Request('GET', uri);
      request.headers['Authorization'] = _authHeader;
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      _client = http.Client();
      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        _client?.close();
        _client = null;
        _scheduleReconnect();
        return;
      }

      _reconnectAttempts = 0;
      _startHeartbeat();

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
      _log('EventService._doConnect: $e');
      _scheduleReconnect();
    }
  }

  final _dataBuffer = StringBuffer();

  void _onLine(String line) {
    _lastEventTime = DateTime.now();
    if (line.startsWith('data: ')) {
      _dataBuffer.write(line.substring(6));
    } else if (line.isEmpty && _dataBuffer.isNotEmpty) {
      _emitEvent();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _lastEventTime = DateTime.now();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      final elapsed = DateTime.now().difference(_lastEventTime);
      if (elapsed > _heartbeatTimeout) {
        _log(
          'EventService heartbeat timeout (${elapsed.inSeconds}s), reconnecting',
        );
        _heartbeatTimer?.cancel();
        _scheduleReconnect();
      }
    });
  }

  void _emitEvent() {
    final rawData = _dataBuffer.toString().trim();
    _dataBuffer.clear();

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(rawData);
      data = decoded is Map<String, dynamic>
          ? decoded
          : {'raw': rawData, 'decoded': decoded};
    } catch (e) {
      _log('EventService._emitEvent json parse: $e');
      return;
    }

    final payload = data['payload'];
    final payloadType = payload is Map ? payload['type'] as String? : null;
    final eventType = payloadType ?? data['type'] as String? ?? '';

    final type = _eventTypeFromString(eventType);
    if (!_cancelled) {
      _controller.add(ServerEvent(type: type, data: data, rawType: eventType));
    }
  }

  EventType _eventTypeFromString(String type) {
    switch (type) {
      case 'message.updated':
      case 'message.new':
        return EventType.messageNew;
      case 'session.updated':
        return EventType.sessionUpdated;
      case 'session.status':
        return EventType.sessionStatus;
      case 'message.part.delta':
        return EventType.messagePartDelta;
      case 'permission.asked':
        return EventType.permissionAsked;
      case 'question.asked':
        return EventType.questionAsked;
      default:
        return EventType.unknown;
    }
  }

  void _scheduleReconnect() {
    if (_cancelled) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: (_reconnectAttempts * 2).clamp(1, 30));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _doConnect);
  }

  Future<void> disconnect() async {
    _cancelled = true;
    _heartbeatTimer?.cancel();
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

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}

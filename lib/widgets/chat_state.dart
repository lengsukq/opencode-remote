import '../models.dart';

/// Extracted state classes for ChatScreen to reduce State member count.
///
/// These classes manage streaming deltas and command suggestions state,
/// keeping ChatScreen's State class within the <= 20 member limit.

/// Manages streaming text deltas and tool states from SSE events.
class StreamState {
  final Map<String, String> deltas = {};
  final Map<String, Map<String, dynamic>> toolStates = {};

  void clear() {
    deltas.clear();
    toolStates.clear();
  }

  void applyDelta(Map<String, dynamic> props) {
    final partID = props['partID'] as String?;
    final field = props['field'] as String?;
    final delta = props['delta'] as String?;
    if (partID == null || delta == null) return;

    if (field == 'text') {
      deltas[partID] = (deltas[partID] ?? '') + delta;
    } else if (field == 'state.status') {
      toolStates[partID] = {...?toolStates[partID], 'status': delta};
    } else if (field == 'state.output') {
      final existing = (toolStates[partID]?['output'] as String? ?? '') + delta;
      toolStates[partID] = {...?toolStates[partID], 'output': existing};
    } else if (field == 'state.error') {
      toolStates[partID] = {...?toolStates[partID], 'error': delta};
    } else if (field == 'state.title') {
      toolStates[partID] = {...?toolStates[partID], 'title': delta};
    }
  }
}

/// Manages command suggestion filtering state.
class CommandState {
  bool show = false;
  List<Command> filtered = [];
}

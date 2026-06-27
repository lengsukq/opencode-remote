import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../strings.dart';
import '../../services/opencode_api.dart';

import '../../utils/responsive_values.dart';

class TerminalScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;
  final Project? activeProject;

  const TerminalScreen({super.key, required this.entry, required this.api, this.activeProject});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalLine {
  final String text;
  final bool isInput;
  final bool isError;

  _TerminalLine({required this.text, this.isInput = false, this.isError = false});
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _lines = <_TerminalLine>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _history = <String>[];
  bool _running = false;
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _addLine(_TerminalLine(text: 'OpenCode Remote Terminal', isInput: false));
    _addLine(_TerminalLine(text: 'Initializing...', isInput: false));
    try {
      final session = await widget.api.createSession(title: '__terminal__');
      _sessionId = session.id;
      _addLine(_TerminalLine(text: 'Ready. Type a command.', isInput: false));
    } catch (e) {
      _addLine(_TerminalLine(text: 'Init error: $e (fallback mode)', isError: true));
    }
    _addLine(_TerminalLine(text: '---', isInput: false));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addLine(_TerminalLine line) {
    setState(() => _lines.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runCommand(String command) async {
    if (command.trim().isEmpty) return;
    _addLine(_TerminalLine(text: '\$ $command', isInput: true));
    _history.add(command);

    setState(() => _running = true);
    try {
      final sid = _sessionId.isNotEmpty ? _sessionId : widget.entry.id;
      final response = await widget.api.runShell(sid, command: command);
      final message = response.info;
      final content = message.content;
      if (content.isNotEmpty) {
        _addLine(_TerminalLine(text: content));
      }
    } catch (e) {
      _addLine(_TerminalLine(text: 'Error: $e', isError: true));
    }
    setState(() => _running = false);
  }

  void _onKeyEvent(String command) {
    _inputCtrl.clear();
    _runCommand(command);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final bgColor = isDark ? AppColors.terminalBg : AppColors.terminalBgLight;
    final textColor = isDark ? AppColors.terminalText : AppColors.terminalTextLight;
    final inputColor = AppColors.terminalInput;
    final errorColor = AppColors.terminalError;
    const promptColor = AppColors.terminalPrompt;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(S.terminal, style: TextStyle(fontFamily: 'monospace', fontSize: R.bodyFontSize(context))),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.terminalIcon, size: R.iconSize(context)),
            tooltip: S.clear,
            onPressed: () => setState(() => _lines.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: R.screenPadding(context),
              itemCount: _lines.length,
              itemBuilder: (ctx, i) {
                final line = _lines[i];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: R.smallSpacing(context) / 10),
                  child: Text(
                    line.text,
                    style: TextStyle(
                      color: line.isInput ? inputColor : line.isError ? errorColor : textColor,
                      fontSize: R.terminalFontSize(context),
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: AppColors.terminalInputBg,
            padding: EdgeInsets.fromLTRB(
              R.spacing(context),
              R.smallSpacing(context),
              R.spacing(context),
              R.smallSpacing(context),
            ),
            child: Row(
              children: [
                Text('\$ ', style: TextStyle(color: promptColor, fontSize: R.bodyFontSize(context), fontFamily: 'monospace')),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    enabled: !_running,
                    style: TextStyle(color: inputColor, fontSize: R.bodyFontSize(context), fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _onKeyEvent,
                  ),
                ),
                if (_running)
                  SizedBox(
                    width: R.smallIconSize(context), height: R.smallIconSize(context),
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.terminalPrompt),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models.dart';
import '../strings.dart';
import '../theme.dart';
import 'app_input_decoration.dart';

/// A shared dialog for adding or editing a server entry.
///
/// Shows name, host, port, username, password and an HTTPS toggle.
/// Returns a [ServerEntry] on save, or `null` on cancel.
///
/// Usage:
/// ```dart
/// // Add mode
/// final entry = await showDialog<ServerEntry>(
///   context: context,
///   builder: (_) => const AppServerEditDialog(),
/// );
///
/// // Edit mode
/// final entry = await showDialog<ServerEntry>(
///   context: context,
///   builder: (_) => AppServerEditDialog(existing: existingEntry),
/// );
/// ```
class AppServerEditDialog extends StatefulWidget {
  final ServerEntry? existing;

  const AppServerEditDialog({super.key, this.existing});

  @override
  State<AppServerEditDialog> createState() => _AppServerEditDialogState();
}

class _AppServerEditDialogState extends State<AppServerEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  bool _useHttps = false;

  @override
  void initState() {
    super.initState();
    final uri = widget.existing != null ? Uri.tryParse(widget.existing!.url) : null;
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _hostCtrl = TextEditingController(
      text: uri?.host.isNotEmpty == true ? uri!.host : '',
    );
    _portCtrl = TextEditingController(
      text: uri != null && uri.port > 0 ? uri.port.toString() : '4096',
    );
    _userCtrl = TextEditingController(text: widget.existing?.username ?? 'opencode');
    _passCtrl = TextEditingController(text: widget.existing?.password ?? '');
    _useHttps = uri?.scheme == 'https';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.existing == null ? S.addServer : S.editServer,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppInputDecoration.standard(
                labelText: S.name,
                hintText: S.nameHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppInputDecoration.standard(
                labelText: S.address,
                hintText: S.addressHint,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppInputDecoration.standard(
                labelText: S.port,
                hintText: S.portHint,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppInputDecoration.standard(
                labelText: S.username,
                hintText: S.usernameHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppInputDecoration.standard(
                labelText: S.password,
                hintText: S.passwordHint,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'HTTPS',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                const Spacer(),
                Switch(
                  value: _useHttps,
                  onChanged: (v) => setState(() => _useHttps = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text(S.cancel, style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final host = _hostCtrl.text.trim();
            final port = _portCtrl.text.trim();
            if (name.isEmpty || host.isEmpty) return;
            final scheme = _useHttps ? 'https' : 'http';
            final url = '$scheme://$host${port.isNotEmpty ? ':$port' : ''}';
            Navigator.pop(
              context,
              (widget.existing ?? ServerEntry(name: name, url: url)).copyWith(
                name: name,
                url: url,
                username: _userCtrl.text.trim(),
                password: _passCtrl.text,
              ),
            );
          },
          child: const Text(S.save),
        ),
      ],
    );
  }
}

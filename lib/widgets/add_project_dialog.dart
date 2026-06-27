import 'package:flutter/material.dart';
import '../models.dart';
import '../services/opencode_api.dart';
import '../strings.dart';
import '../theme.dart';
import 'app_input_decoration.dart';

/// A full-screen style dialog for adding a project.
///
/// Prompts the user to enter a project directory path, calls
/// [OpenCodeApi.addProject], and returns the created [Project]
/// on success, or `null` if cancelled.
///
/// Usage:
/// ```dart
/// final project = await showDialog<Project>(
///   context: context,
///   builder: (_) => AddProjectDialog(api: _api),
/// );
/// ```
class AddProjectDialog extends StatefulWidget {
  final OpenCodeApi api;

  const AddProjectDialog({super.key, required this.api});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _pathCtrl = TextEditingController();
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final path = _pathCtrl.text.trim();
    if (path.isEmpty) {
      setState(() => _errorText = S.pathNotEmpty);
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final project = await widget.api.addProject(path);
      if (!mounted) return;
      Navigator.pop(context, project);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = '${S.addFailed}: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        S.addProject,
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pathCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppInputDecoration.standard(
                hintText: S.projectPathHint,
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text(
            S.cancel,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(S.add),
        ),
      ],
    );
  }
}

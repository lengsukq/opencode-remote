import 'package:flutter/material.dart';

import '../models.dart';
import '../strings.dart';
import '../theme.dart';
import '../services/opencode_api.dart';
import '../widgets/diff_view.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';

class SessionActions {
  SessionActions._();

  static Future<void> abort(
    BuildContext context,
    OpenCodeApi api,
    Session session,
    VoidCallback onReload,
  ) async {
    try {
      await api.abortSession(session.id);
      if (context.mounted) {
        AppSnackBar.show(context, S.sessionAborted);
        onReload();
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, S.abortFailed(e));
    }
  }

  static Future<void> unshare(
    BuildContext context,
    OpenCodeApi api,
    Session session,
    VoidCallback onReload,
  ) async {
    try {
      await api.unshareSession(session.id);
      if (context.mounted) {
        AppSnackBar.show(context, S.unshared);
        onReload();
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, S.unshareFailed(e));
    }
  }

  static Future<void> showChildSessions(
    BuildContext context,
    OpenCodeApi api,
    Session session,
  ) async {
    try {
      final children = await api.getChildSessions(session.id);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text(S.childSessions, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(S.noChildSessions, style: TextStyle(color: AppColors.textTertiary)),
                )
              else
                ...children.map((c) => ListTile(
                  title: Text(c.title.isNotEmpty ? c.title : S.unnamed, style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  subtitle: Text(c.status, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                )),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, S.childSessionsFailed(e));
    }
  }

  static Future<void> showTodoList(
    BuildContext context,
    OpenCodeApi api,
    Session session,
  ) async {
    try {
      final todos = await api.getSessionTodo(session.id);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text(S.todoList, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              if (todos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(S.noTodos, style: TextStyle(color: AppColors.textTertiary)),
                )
              else
                Expanded(
                  child: ListView(
                    children: todos.map((t) => ListTile(
                      dense: true,
                      leading: Icon(
                        t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: t.done ? AppColors.success : AppColors.textSecondary,
                        size: 18,
                      ),
                      title: Text(
                        t.task,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          decoration: t.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, S.todoFailed(e));
    }
  }

  static Future<void> rename(
    BuildContext context,
    OpenCodeApi api,
    Session session,
    VoidCallback onReload,
  ) async {
    final result = await AppDialog.showTextInput(
      context,
      title: S.rename,
      initialValue: session.title,
      hintText: S.newTitle,
    );
    if (result == null || result.trim().isEmpty) return;
    try {
      await api.updateSession(session.id, title: result.trim());
      if (context.mounted) {
        onReload();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, S.renameFailed(e));
      }
    }
  }

  static Future<void> share(
    BuildContext context,
    OpenCodeApi api,
    Session session,
  ) async {
    try {
      await api.shareSession(session.id);
      if (context.mounted) {
        AppSnackBar.success(context, S.shared);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, S.shareFailed(e));
      }
    }
  }

  static Future<void> showDiff(
    BuildContext context,
    OpenCodeApi api,
    Session session,
  ) async {
    try {
      final diffs = await api.getSessionDiff(session.id);
      if (!context.mounted) return;
      if (diffs.isEmpty) {
        AppSnackBar.show(context, S.noDiffs);
        return;
      }
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.background,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              AppBar(
                title: Text(S.diffTitle(session.title), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: diffs.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DiffView(
                      filePath: d.filePath,
                      status: d.status,
                      hunks: [DiffHunkView.fromContent(0, 0, d.patch ?? '+${d.additions} -${d.deletions}')],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, S.diffFailed(e));
      }
    }
  }

  static Future<void> summarize(
    BuildContext context,
    OpenCodeApi api,
    Session session,
    VoidCallback onReload,
  ) async {
    try {
      await api.summarizeSession(session.id);
      if (context.mounted) {
        AppSnackBar.success(context, S.summarizeDone);
        onReload();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, S.summarizeFailed(e));
      }
    }
  }

  static Future<void> fork(
    BuildContext context,
    OpenCodeApi api,
    Session session,
    VoidCallback onReload,
  ) async {
    final messageID = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(S.forkSession, style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(S.forkSessionConfirm, style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel, style: const TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.fork),
          ),
        ],
      ),
    );
    if (messageID == null) return;
    try {
      await api.forkSession(session.id);
      if (context.mounted) {
        AppSnackBar.success(context, S.forkedAsNew);
        onReload();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, S.forkFailed(e));
      }
    }
  }

  static Future<void> delete(
    BuildContext context,
    OpenCodeApi api,
    Session session,
    VoidCallback onReload,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.deleteSession, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(S.confirmDeleteSession(session.title), style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel, style: const TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await api.deleteSession(session.id);
      if (context.mounted) {
        onReload();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, S.deleteFailed(e));
      }
    }
  }
}

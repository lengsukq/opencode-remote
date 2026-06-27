import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health.dart';

/// Helper for persisting project lists and their display order
/// per server via SharedPreferences.
///
/// Each server's projects are stored under `projects:<serverId>`.
/// The display order (list of project IDs) is stored under
/// `project_order:<serverId>`.
class ProjectHelpers {
  ProjectHelpers._();

  static String _key(String serverId) => 'projects:$serverId';
  static String _orderKey(String serverId) => 'project_order:$serverId';

  /// Persists [projects] for the given [serverId].
  static Future<void> saveProjects(String serverId, List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final data = projects
        .map((p) => {
              'id': p.id,
              'name': p.name,
              'path': p.path,
            })
        .toList();
    await prefs.setString(_key(serverId), jsonEncode(data));
  }

  /// Loads the project list previously saved for [serverId].
  /// Returns an empty list when nothing has been stored.
  static Future<List<Project>> loadProjects(String serverId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(serverId));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return Project(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        path: m['path'] as String? ?? '',
      );
    }).toList();
  }

  /// Persists a custom display order (list of project IDs) for [serverId].
  static Future<void> saveOrder(String serverId, List<String> projectIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey(serverId), jsonEncode(projectIds));
  }

  /// Loads the previously saved display order for [serverId].
  /// Returns an empty list when nothing has been stored.
  static Future<List<String>> loadOrder(String serverId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_orderKey(serverId));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => e.toString()).toList();
  }
}

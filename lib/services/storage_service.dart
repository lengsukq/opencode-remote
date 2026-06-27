import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

const _kSecurePlaceholder = '__SECURE__';

class StorageService {
  static const _keyServers = 'servers';
  static const _keyLastId = 'lastSelectedId';
  static const _keyAppMode = 'app_mode';
  static const _keyHasLaunched = 'hasLaunched';
  static const _keyMigratedSecure = 'migrated_to_secure_v1';

  static const _secure = FlutterSecureStorage();

  static String _secKey(String serverId) => 'opencode_pw_$serverId';

  static Future<String?> _secureRead(String serverId) async {
    try {
      return await _secure.read(key: _secKey(serverId));
    } catch (e) {
      _log('StorageService._secureRead: $e');
      return null;
    }
  }

  static Future<void> _secureWrite(String serverId, String password) async {
    try {
      await _secure.write(key: _secKey(serverId), value: password);
    } catch (e) {
      _log('StorageService._secureWrite: $e');
    }
  }

  static Future<void> _secureDelete(String serverId) async {
    try {
      await _secure.delete(key: _secKey(serverId));
    } catch (e) {
      _log('StorageService._secureDelete: $e');
    }
  }

  static Future<List<ServerEntry>> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyServers);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is List<dynamic> ? decoded : <dynamic>[];
      final servers = <ServerEntry>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final entry = ServerEntry.fromJson(e);
        if (entry.password == _kSecurePlaceholder) {
          final realPw = await _secureRead(entry.id);
          entry.password = realPw ?? '';
        }
        servers.add(entry);
      }
      servers.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return servers;
    } catch (e) {
      _log('StorageService.loadServers: $e — raw: ${raw.substring(0, raw.length.clamp(0, 500))}');
      return [];
    }
  }

  static Future<void> saveServers(List<ServerEntry> servers) async {
    final prefs = await SharedPreferences.getInstance();
    for (final s in servers) {
      await _secureWrite(s.id, s.password);
    }
    final sanitized = servers.map((s) {
      final json = s.toJson();
      json['password'] = _kSecurePlaceholder;
      return json;
    }).toList();
    final raw = jsonEncode(sanitized);
    await prefs.setString(_keyServers, raw);
  }

  static Future<void> migrateToSecureStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyMigratedSecure) == true) return;
    final raw = prefs.getString(_keyServers);
    if (raw == null) {
      await prefs.setBool(_keyMigratedSecure, true);
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is List<dynamic> ? decoded : <dynamic>[];
      final servers = <ServerEntry>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final entry = ServerEntry.fromJson(e);
        if (entry.password.isNotEmpty && entry.password != _kSecurePlaceholder) {
          await _secureWrite(entry.id, entry.password);
        }
        servers.add(entry);
      }
      await saveServers(servers);
      await prefs.setBool(_keyMigratedSecure, true);
    } catch (e) {
      _log('StorageService.migrateToSecureStorage: $e');
    }
  }

  static Future<void> addOrUpdate(ServerEntry entry) async {
    final servers = await loadServers();
    final idx = servers.indexWhere((s) => s.id == entry.id);
    if (idx >= 0) {
      servers[idx] = entry;
    } else {
      servers.add(entry);
    }
    await saveServers(servers);
  }

  static Future<void> delete(String id) async {
    final servers = await loadServers();
    servers.removeWhere((s) => s.id == id);
    await _secureDelete(id);
    await saveServers(servers);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyLastId) == id) {
      await prefs.remove(_keyLastId);
    }
  }

  static Future<String?> getLastSelectedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastId);
  }

  static Future<void> setLastSelectedId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_keyLastId, id);
    } else {
      await prefs.remove(_keyLastId);
    }
  }

  static Future<ServerEntry?> getLastSelected() async {
    final id = await getLastSelectedId();
    if (id == null) return null;
    final servers = await loadServers();
    try {
      return servers.firstWhere((s) => s.id == id);
    } catch (e) {
      _log('StorageService.getLastSelected: $e (lastId: $id)');
      return null;
    }
  }

  static Future<AppMode> getAppMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAppMode);
    if (raw == 'native') return AppMode.native;
    return AppMode.webview;
  }

  static Future<void> setAppMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppMode, mode == AppMode.native ? 'native' : 'webview');
  }

  static Future<bool> hasLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasLaunched) ?? false;
  }

  static Future<void> setHasLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasLaunched, true);
  }

  static const _keyThemeMode = 'theme_mode';

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyThemeMode);
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String raw;
    switch (mode) {
      case ThemeMode.dark:
        raw = 'dark';
      case ThemeMode.light:
        raw = 'light';
      default:
        raw = 'system';
    }
    await prefs.setString(_keyThemeMode, raw);
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}

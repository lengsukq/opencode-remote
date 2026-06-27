import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class StorageService {
  static const _keyServers = 'servers';
  static const _keyLastId = 'lastSelectedId';
  static const _keyAppMode = 'app_mode';
  static const _keyHasLaunched = 'hasLaunched';

  static Future<List<ServerEntry>> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyServers);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is List<dynamic> ? decoded : <dynamic>[];
      return list
          .map((e) => e is Map<String, dynamic> ? ServerEntry.fromJson(e) : ServerEntry(name: '', url: ''))
          .toList()
        ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    } catch (e) {
      debugPrint('StorageService.loadServers: $e — raw: ${raw.substring(0, raw.length.clamp(0, 500))}');
      return [];
    }
  }

  static Future<void> saveServers(List<ServerEntry> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(servers.map((e) => e.toJson()).toList());
    await prefs.setString(_keyServers, raw);
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
      debugPrint('StorageService.getLastSelected: $e (lastId: $id)');
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
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController()..load();
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system);

  static const _key = 'settings.themeMode';
  static const _switchDelay = Duration(milliseconds: 280);
  Timer? _switchTimer;
  int _revision = 0;
  bool _disposed = false;

  Future<void> load() async {
    final revision = _revision;
    final value = (await SharedPreferences.getInstance()).getString(_key);
    if (_disposed || revision != _revision) return;
    state = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (_disposed || mode == state && _switchTimer == null) return;
    _revision++;
    _switchTimer?.cancel();
    _switchTimer = Timer(_switchDelay, () async {
      _switchTimer = null;
      if (_disposed) return;
      state = mode;
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _switchTimer?.cancel();
    super.dispose();
  }
}

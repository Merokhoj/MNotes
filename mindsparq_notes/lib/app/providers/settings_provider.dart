import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider not initialized');
});

class AppSettings {
  final ThemeMode themeMode;
  final bool autoSaveEnabled;
  final String editorFont;
  final double editorFontSize;
  final String geminiApiKey;
  final double sidebarWidth;
  final double notesListWidth;
  final double lineHeight;
  final double paragraphSpacing;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.autoSaveEnabled = true,
    this.editorFont = 'Inter',
    this.editorFontSize = 16.5,
    this.geminiApiKey = '',
    this.sidebarWidth = 240.0,
    this.notesListWidth = 300.0,
    this.lineHeight = 1.0,
    this.paragraphSpacing = 4.0,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? autoSaveEnabled,
    String? editorFont,
    double? editorFontSize,
    String? geminiApiKey,
    double? sidebarWidth,
    double? notesListWidth,
    double? lineHeight,
    double? paragraphSpacing,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      editorFont: editorFont ?? this.editorFont,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      notesListWidth: notesListWidth ?? this.notesListWidth,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'app_theme_mode';
  static const _autoSaveKey = 'app_auto_save';
  static const _editorFontKey = 'app_editor_font';
  static const _editorFontSizeKey = 'app_editor_font_size';
  static const _geminiApiKey = 'app_gemini_api_key';
  static const _sidebarWidthKey = 'app_sidebar_width';
  static const _notesListWidthKey = 'app_notes_list_width';
  static const _lineHeightKey = 'app_line_height';
  static const _paragraphSpacingKey = 'app_paragraph_spacing';
  // Bump this integer whenever typography defaults change — forces a one-time reset
  static const _settingsVersionKey = 'app_settings_version';
  static const _currentSettingsVersion = 2;

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    // One-time migration: reset typography defaults when version is older
    final storedVersion = prefs.getInt(_settingsVersionKey) ?? 0;
    double lineHeight;
    double paragraphSpacing;
    if (storedVersion < _currentSettingsVersion) {
      lineHeight = 1.0;
      paragraphSpacing = 4.0; // Must match minimum dropdown option in settings_dialog.dart
      prefs.setInt(_settingsVersionKey, _currentSettingsVersion);
      prefs.setDouble(_lineHeightKey, lineHeight);
      prefs.setDouble(_paragraphSpacingKey, paragraphSpacing);
    } else {
      lineHeight = (prefs.getDouble(_lineHeightKey) ?? 1.0).clamp(0.8, 2.0);
      paragraphSpacing = (prefs.getDouble(_paragraphSpacingKey) ?? 4.0).clamp(0.0, 12.0);
    }

    return AppSettings(
      themeMode: _loadThemeMode(prefs),
      autoSaveEnabled: prefs.getBool(_autoSaveKey) ?? true,
      editorFont: prefs.getString(_editorFontKey) ?? 'Inter',
      editorFontSize: prefs.getDouble(_editorFontSizeKey) ?? 16.5,
      geminiApiKey: prefs.getString(_geminiApiKey) ?? '',
      sidebarWidth:
          (prefs.getDouble(_sidebarWidthKey) ?? 240.0).clamp(180.0, 360.0),
      notesListWidth:
          (prefs.getDouble(_notesListWidthKey) ?? 300.0).clamp(220.0, 440.0),
      lineHeight: lineHeight,
      paragraphSpacing: paragraphSpacing,
    );
  }

  ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final val = prefs.getString(_themeKey);
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';

    await prefs.setString(_themeKey, val);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updateAutoSave(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_autoSaveKey, enabled);
    state = state.copyWith(autoSaveEnabled: enabled);
  }

  Future<void> updateEditorFont(String font) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_editorFontKey, font);
    state = state.copyWith(editorFont: font);
  }

  Future<void> updateEditorFontSize(double size) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_editorFontSizeKey, size);
    state = state.copyWith(editorFontSize: size);
  }

  Future<void> updateGeminiApiKey(String key) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_geminiApiKey, key.trim());
    state = state.copyWith(geminiApiKey: key.trim());
  }

  Future<void> updateSidebarWidth(double width) async {
    final clamped = width.clamp(180.0, 360.0);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_sidebarWidthKey, clamped);
    state = state.copyWith(sidebarWidth: clamped);
  }

  Future<void> updateNotesListWidth(double width) async {
    final clamped = width.clamp(220.0, 440.0);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_notesListWidthKey, clamped);
    state = state.copyWith(notesListWidth: clamped);
  }

  Future<void> updateLineHeight(double height) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_lineHeightKey, height);
    state = state.copyWith(lineHeight: height);
  }

  Future<void> updateParagraphSpacing(double spacing) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_paragraphSpacingKey, spacing);
    state = state.copyWith(paragraphSpacing: spacing);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

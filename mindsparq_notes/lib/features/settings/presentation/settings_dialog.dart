import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/settings_provider.dart';
import '../../ai/data/services/ai_writing_service.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late final TextEditingController _apiKeyCtrl;
  bool _isTestingApiKey = false;
  bool _obscureKey = true;
  String? _validationStatusMessage;
  bool? _isKeyValid;
  String? _validatedModel;

  @override
  void initState() {
    super.initState();
    final initialKey = ref.read(settingsProvider).geminiApiKey;
    _apiKeyCtrl = TextEditingController(text: initialKey);
    if (initialKey.trim().isNotEmpty) {
      _isKeyValid = true;
      _validatedModel = 'Gemini 2.0 Flash';
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSaveApiKey() async {
    final rawKey = _apiKeyCtrl.text;
    final cleanKey = AiWritingService.sanitizeApiKey(rawKey);
    _apiKeyCtrl.text = cleanKey;

    if (cleanKey.isEmpty) {
      await ref.read(settingsProvider.notifier).updateGeminiApiKey('');
      if (mounted) {
        setState(() {
          _isKeyValid = null;
          _validationStatusMessage = null;
          _validatedModel = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key cleared. Local Smart AI Engine is now active.'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
      return;
    }

    setState(() {
      _isTestingApiKey = true;
      _validationStatusMessage = null;
    });

    final result = await AiWritingService.validateApiKey(cleanKey);
    await ref.read(settingsProvider.notifier).updateGeminiApiKey(cleanKey);
    
    if (!mounted) return;
    setState(() {
      _isTestingApiKey = false;
      _isKeyValid = result.isValid;
      _validationStatusMessage = result.message;
      _validatedModel = result.activeModel;
    });

    if (result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Google ${result.activeModel} connected & validated successfully! ⚡'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key saved, but validation failed (${result.statusCode ?? "Network"}):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(result.message, style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border.withOpacity(0.5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.gearSix(PhosphorIconsStyle.fill), size: 24, color: colors.textPrimary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(color: colors.border.withOpacity(0.5)),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView(
                  children: [
                    const _SettingsSectionTitle('Appearance'),
                    const SizedBox(height: AppSpacing.md),

                    // Theme Selector
                    Container(
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: colors.border.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          _ThemeOption(
                            title: 'System Default',
                            icon: PhosphorIcons.desktop(),
                            isSelected: settings.themeMode == ThemeMode.system,
                            onTap: () => settingsNotifier.updateThemeMode(ThemeMode.system),
                          ),
                          Divider(height: 1, color: colors.border.withOpacity(0.5)),
                          _ThemeOption(
                            title: 'Light Mode',
                            icon: PhosphorIcons.sun(),
                            isSelected: settings.themeMode == ThemeMode.light,
                            onTap: () => settingsNotifier.updateThemeMode(ThemeMode.light),
                          ),
                          Divider(height: 1, color: colors.border.withOpacity(0.5)),
                          _ThemeOption(
                            title: 'Dark Mode',
                            icon: PhosphorIcons.moon(),
                            isSelected: settings.themeMode == ThemeMode.dark,
                            onTap: () => settingsNotifier.updateThemeMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    const _SettingsSectionTitle('Editor & Typography'),
                    const SizedBox(height: AppSpacing.md),

                    // Auto Save
                    Container(
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: colors.border.withOpacity(0.5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.floppyDisk(), color: colors.textSecondary, size: 20),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Auto-Save Notes', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500)),
                                Text('Automatically save changes while typing.', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: settings.autoSaveEnabled,
                            onChanged: (val) => settingsNotifier.updateAutoSave(val),
                            activeColor: AppColors.accent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Editor Font Family & Size
                    Container(
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: colors.border.withOpacity(0.5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(PhosphorIcons.textT(), color: colors.textSecondary, size: 20),
                              const SizedBox(width: AppSpacing.md),
                              Text('Font Family', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              DropdownButton<String>(
                                value: settings.editorFont,
                                underline: const SizedBox.shrink(),
                                dropdownColor: colors.surface,
                                style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                items: const [
                                  DropdownMenuItem(value: 'Inter', child: Text('Inter (Default)')),
                                  DropdownMenuItem(value: 'Outfit', child: Text('Outfit (Modern)')),
                                  DropdownMenuItem(value: 'JetBrains Mono', child: Text('JetBrains Mono')),
                                  DropdownMenuItem(value: 'Playfair Display', child: Text('Playfair (Editorial)')),
                                  DropdownMenuItem(value: 'Merriweather', child: Text('Merriweather (Serif)')),
                                ],
                                onChanged: (newFont) {
                                  if (newFont != null) {
                                    settingsNotifier.updateEditorFont(newFont);
                                  }
                                },
                              ),
                            ],
                          ),
                          Divider(height: 16, color: colors.border.withOpacity(0.3)),
                          Row(
                            children: [
                              Icon(PhosphorIcons.textAa(), color: colors.textSecondary, size: 20),
                              const SizedBox(width: AppSpacing.md),
                              Text('Font Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, size: 16),
                                onPressed: settings.editorFontSize > 12.0
                                    ? () => settingsNotifier.updateEditorFontSize(settings.editorFontSize - 1.0)
                                    : null,
                              ),
                              Text(
                                '${settings.editorFontSize.toInt()} pt',
                                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 16),
                                onPressed: settings.editorFontSize < 28.0
                                    ? () => settingsNotifier.updateEditorFontSize(settings.editorFontSize + 1.0)
                                    : null,
                              ),
                            ],
                          ),
                          Divider(height: 16, color: colors.border.withOpacity(0.3)),
                          Row(
                            children: [
                              Icon(Icons.format_line_spacing_rounded, color: colors.textSecondary, size: 20),
                              const SizedBox(width: AppSpacing.md),
                              Text('Line Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              DropdownButton<double>(
                                value: settings.lineHeight,
                                underline: const SizedBox.shrink(),
                                dropdownColor: colors.surface,
                                style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                items: const [
                                  DropdownMenuItem(value: 1.0, child: Text('1.0 (Tight)')),
                                  DropdownMenuItem(value: 1.08, child: Text('1.08 (Compact)')),
                                  DropdownMenuItem(value: 1.15, child: Text('1.15 (Professional)')),
                                  DropdownMenuItem(value: 1.35, child: Text('1.35 (Relaxed)')),
                                  DropdownMenuItem(value: 1.5, child: Text('1.5 (Loose)')),
                                  DropdownMenuItem(value: 2.0, child: Text('2.0 (Double)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) settingsNotifier.updateLineHeight(val);
                                },
                              ),
                            ],
                          ),
                          Divider(height: 16, color: colors.border.withOpacity(0.3)),
                          Row(
                            children: [
                              Icon(Icons.height_rounded, color: colors.textSecondary, size: 20),
                              const SizedBox(width: AppSpacing.md),
                              Text('Paragraph Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              DropdownButton<double>(
                                value: settings.paragraphSpacing,
                                underline: const SizedBox.shrink(),
                                dropdownColor: colors.surface,
                                style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('0 pt (None)')),
                                  DropdownMenuItem(value: 4.0, child: Text('4 pt')),
                                  DropdownMenuItem(value: 6.0, child: Text('6 pt (Professional)')),
                                  DropdownMenuItem(value: 8.0, child: Text('8 pt')),
                                  DropdownMenuItem(value: 12.0, child: Text('12 pt')),
                                ],
                                onChanged: (val) {
                                  if (val != null) settingsNotifier.updateParagraphSpacing(val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    const _SettingsSectionTitle('AI & Writing Intelligence'),
                    const SizedBox(height: AppSpacing.md),

                    // Gemini API Key
                    Container(
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: colors.border.withOpacity(0.5)),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), color: AppColors.accent, size: 20),
                              const SizedBox(width: AppSpacing.md),
                              Text('Google Gemini AI Integration', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.accent.withOpacity(0.18),
                                      AppColors.accent.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  border: Border.all(color: AppColors.accent.withOpacity(0.35)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 13, color: AppColors.accent),
                                    SizedBox(width: 3),
                                    Text(
                                      'Gemini 2.0 Flash',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Powered by Google\'s latest, ultra-fast Gemini 2.0 Flash model. When blank or offline, MindSparQ automatically uses the built-in local smart AI heuristics.',
                            style: TextStyle(color: colors.textTertiary, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _apiKeyCtrl,
                                  obscureText: _obscureKey,
                                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Paste AIzaSy... key (or leave empty for offline AI)',
                                    hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.5), fontSize: 12),
                                    filled: true,
                                    fillColor: colors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      borderSide: BorderSide(color: colors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      borderSide: BorderSide(color: colors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      borderSide: const BorderSide(color: AppColors.accent),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    isDense: true,
                                    prefixIcon: IconButton(
                                      icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16),
                                      tooltip: _obscureKey ? 'Show Key' : 'Hide Key',
                                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isTestingApiKey ? null : _handleSaveApiKey,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  minimumSize: const Size(0, 40),
                                ),
                                child: _isTestingApiKey
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Save & Test', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // ── Active Engine & Live Validation Status Box ──────
                          if (_isTestingApiKey)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: colors.border.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pinging Google Gemini 2.0 Flash...',
                                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          else if (_isKeyValid == true)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: AppColors.success.withOpacity(0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Active: ${_validatedModel ?? "Google Gemini 2.0 Flash"} • Key verified & ready',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_isKeyValid == false)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: AppColors.warning.withOpacity(0.35)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                                      SizedBox(width: 6),
                                      Text(
                                        'Key Validation Ping Failed',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.warning),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _validationStatusMessage ?? 'Could not verify key with Google AI servers. Check internet or key validity.',
                                    style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.3),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '⚡ Offline Smart AI Engine will be used seamlessly as fallback.',
                                    style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.accent),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: colors.border.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  Icon(PhosphorIcons.cpu(), size: 14, color: colors.textTertiary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Active Engine: Local Smart AI (100% Offline & Private)',
                                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 12, color: colors.textTertiary),
                              const SizedBox(width: 5),
                              Text(
                                'Need an API key? Get one free at aistudio.google.com',
                                style: TextStyle(fontSize: 11, color: colors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;
  const _SettingsSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.textTertiaryColor,
        letterSpacing: 0.5,
        textBaseline: TextBaseline.alphabetic,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.accent : colors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.accent : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18),
          ],
        ),
      ),
    );
  }
}

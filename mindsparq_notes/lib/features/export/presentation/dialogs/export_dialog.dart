import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/note.dart';
import '../../../research/data/services/research_storage_service.dart';
import '../../services/document_export_service.dart';

enum ExportFormat {
  markdown('Markdown (.md)', PhosphorIconsStyle.bold),
  html('Web Page (.html)', PhosphorIconsStyle.bold),
  text('Plain Text (.txt)', PhosphorIconsStyle.bold);

  final String label;
  final PhosphorIconsStyle style;
  const ExportFormat(this.label, this.style);
}

class ExportDialog extends ConsumerStatefulWidget {
  final Note note;
  final EditorState editorState;

  const ExportDialog({
    super.key,
    required this.note,
    required this.editorState,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.markdown;
  bool _includeCitations = true;
  bool _isExporting = false;
  String? _exportedFilePath;

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _exportedFilePath = null;
    });

    try {
      final meta = await ref.read(researchServiceProvider).getMetadata(widget.note.id);
      final researchData = _includeCitations ? meta : null;
      File resultFile;

      switch (_selectedFormat) {
        case ExportFormat.markdown:
          resultFile = await DocumentExportService.exportToMarkdownFile(
            widget.note,
            widget.editorState,
            researchMetadata: researchData,
          );
          break;
        case ExportFormat.html:
          resultFile = await DocumentExportService.exportToHtmlFile(
            widget.note,
            widget.editorState,
            researchMetadata: researchData,
          );
          break;
        case ExportFormat.text:
          resultFile = await DocumentExportService.exportToPlainTextFile(
            widget.note,
            widget.editorState,
          );
          break;
      }

      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportedFilePath = resultFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCopy() async {
    final meta = await ref.read(researchServiceProvider).getMetadata(widget.note.id);
    final researchData = _includeCitations ? meta : null;

    String content = '';
    switch (_selectedFormat) {
      case ExportFormat.markdown:
        content = DocumentExportService.documentToMarkdown(
          widget.note,
          widget.editorState,
          researchMetadata: researchData,
        );
        break;
      case ExportFormat.html:
        content = DocumentExportService.documentToHtml(
          widget.note,
          widget.editorState,
          researchMetadata: researchData,
        );
        break;
      case ExportFormat.text:
        final b = StringBuffer();
        for (final node in widget.editorState.document.root.children) {
          b.writeln(node.delta?.toPlainText() ?? '');
        }
        content = b.toString();
        break;
    }

    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content copied to clipboard!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _openExportFolder() {
    if (_exportedFilePath != null && Platform.isWindows) {
      Process.run('explorer.exe', ['/select,', _exportedFilePath!]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border.withOpacity(0.5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(PhosphorIcons.export(), color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Export Document',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: colors.textTertiary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Format selector
              Text(
                'Choose Export Format',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),

              ...ExportFormat.values.map((fmt) {
                final isSelected = _selectedFormat == fmt;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFormat = fmt),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withOpacity(0.08) : colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : colors.border.withOpacity(0.5),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.accent : colors.textTertiary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            fmt.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.md),

              // Include citations switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: colors.border.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.bookBookmark(), size: 18, color: colors.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Include Research Citations & References',
                        style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      ),
                    ),
                    Switch(
                      value: _includeCitations,
                      onChanged: (val) => setState(() => _includeCitations = val),
                      activeColor: AppColors.accent,
                    ),
                  ],
                ),
              ),

              if (_exportedFilePath != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Exported to: $_exportedFilePath',
                          style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _openExportFolder,
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        child: const Text('Show File', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Bottom buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _handleCopy,
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy Text'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export to File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

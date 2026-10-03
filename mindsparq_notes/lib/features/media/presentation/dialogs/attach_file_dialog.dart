import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/services/attachment_storage_service.dart';
import '../../domain/models/note_attachment.dart';

class AttachFileDialog extends ConsumerStatefulWidget {
  final String noteId;
  final bool imagesOnly;

  const AttachFileDialog({
    super.key,
    required this.noteId,
    this.imagesOnly = false,
  });

  @override
  ConsumerState<AttachFileDialog> createState() => _AttachFileDialogState();
}

class _AttachFileDialogState extends ConsumerState<AttachFileDialog> {
  final _pathController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _handleBrowse() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = ref.read(attachmentServiceProvider);
    final chosen = await service.pickNativeFilePath(imagesOnly: widget.imagesOnly);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (chosen != null) {
          _pathController.text = chosen;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      setState(() => _errorMessage = 'Please enter or select a file path');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      setState(() => _errorMessage = 'File does not exist at this path');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(attachmentServiceProvider);
      final attachment = await service.addAttachment(
        noteId: widget.noteId,
        sourcePath: path,
      );

      // Invalidate attachments provider to refresh lists
      ref.invalidate(noteAttachmentsProvider(widget.noteId));

      if (mounted) {
        Navigator.of(context).pop(attachment);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error attaching file: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final path = _pathController.text.trim();
    final isImage = path.isNotEmpty &&
        AttachmentType.fromExtension(path) == AttachmentType.image &&
        File(path).existsSync();

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border.withOpacity(0.5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                    child: Icon(
                      widget.imagesOnly ? PhosphorIcons.image() : PhosphorIcons.paperclip(),
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    widget.imagesOnly ? 'Insert Image' : 'Attach File to Note',
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

              // File path row
              Text(
                'File Location',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: colors.border),
                      ),
                      child: TextField(
                        controller: _pathController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: widget.imagesOnly
                              ? 'C:\\path\\to\\image.png or paste path...'
                              : 'C:\\path\\to\\file.pdf or paste path...',
                          hintStyle: TextStyle(fontSize: 12, color: colors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleBrowse,
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Browse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.surface2,
                      foregroundColor: colors.textPrimary,
                      elevation: 0,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.error),
                ),
              ],

              // Live Image Preview if available
              if (isImage) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: colors.border.withOpacity(0.5)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Unable to preview image', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.imagesOnly ? 'Insert Image' : 'Attach File'),
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

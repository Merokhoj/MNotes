import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/providers/data_providers.dart';
import '../../../../domain/models/folder.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';

const _uuid = Uuid();

class CreateFolderDialog extends ConsumerStatefulWidget {
  final Folder? folderToEdit;
  const CreateFolderDialog({super.key, this.folderToEdit});

  @override
  ConsumerState<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends ConsumerState<CreateFolderDialog> {
  final _controller = TextEditingController();
  int _selectedColorIndex = 0;

  static const List<Color> _folderColors = [
    AppColors.accent,
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    if (widget.folderToEdit != null) {
      _controller.text = widget.folderToEdit!.name;
      final idx = _folderColors.indexWhere((c) => c.value == widget.folderToEdit!.colorValue);
      if (idx != -1) _selectedColorIndex = idx;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(noteRepositoryProvider);
    if (widget.folderToEdit != null) {
      final updated = widget.folderToEdit!.copyWith(
        name: name,
        colorValue: _folderColors[_selectedColorIndex].value,
        updatedAt: DateTime.now(),
      );
      await repo.saveFolder(updated);
      if (mounted) Navigator.of(context).pop(updated);
    } else {
      final folder = Folder(
        id: _uuid.v4(),
        name: name,
        colorValue: _folderColors[_selectedColorIndex].value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.saveFolder(folder);
      if (mounted) Navigator.of(context).pop(folder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.folderToEdit != null ? Icons.edit_rounded : Icons.create_new_folder_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.folderToEdit != null ? 'Edit Folder' : 'New Folder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Folder Name (e.g. Work, Ideas)',
                hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
                filled: true,
                fillColor: colors.surface2,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
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
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Color Tag',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              children: List.generate(_folderColors.length, (i) {
                final isSelected = _selectedColorIndex == i;
                return InkWell(
                  onTap: () => setState(() => _selectedColorIndex = i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _folderColors[i],
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                      boxShadow: isSelected ? [
                        BoxShadow(color: _folderColors[i].withOpacity(0.5), blurRadius: 6, spreadRadius: 1)
                      ] : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                  ),
                  child: Text(
                    widget.folderToEdit != null ? 'Save Changes' : 'Create Folder',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

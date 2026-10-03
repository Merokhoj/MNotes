import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/providers/data_providers.dart';
import '../../../../domain/models/tag.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';

const _uuid = Uuid();

class AddTagDialog extends ConsumerStatefulWidget {
  final List<Tag> currentTags;
  final ValueChanged<Tag> onTagSelected;

  const AddTagDialog({
    super.key,
    required this.currentTags,
    required this.onTagSelected,
  });

  @override
  ConsumerState<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends ConsumerState<AddTagDialog> {
  final _controller = TextEditingController();

  static const List<Color> _tagColors = [
    AppColors.accent,
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createNewTag() async {
    final name = _controller.text.trim().replaceAll('#', '');
    if (name.isEmpty) return;

    final repo = ref.read(noteRepositoryProvider);
    // Hash name to pick a stable color from the list
    final color = _tagColors[name.hashCode.abs() % _tagColors.length];
    
    final newTag = Tag(
      id: _uuid.v4(),
      name: name,
      colorValue: color.value,
    );

    await repo.saveTag(newTag);
    widget.onTagSelected(newTag);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final allTagsAsync = ref.watch(allTagsProvider);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tag_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Add Tag',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'New tag name...',
                hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
                filled: true,
                fillColor: colors.surface2,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: BorderSide(color: colors.border),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
                  onPressed: _createNewTag,
                ),
              ),
              onSubmitted: (_) => _createNewTag(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Existing Tags',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: allTagsAsync.when(
                data: (allTags) {
                  final currentIds = widget.currentTags.map((t) => t.id).toSet();
                  final availableTags = allTags.where((t) => !currentIds.contains(t.id)).toList();

                  if (availableTags.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        'No other tags found. Type above to create one.',
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableTags.map((t) {
                        final tagColor = t.colorValue != null ? Color(t.colorValue!) : AppColors.accent;
                        return InkWell(
                          onTap: () {
                            widget.onTagSelected(t);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(color: tagColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tag, size: 12, color: tagColor),
                                const SizedBox(width: 4),
                                Text(
                                  t.name,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tagColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Text('Error loading tags: $e', style: const TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

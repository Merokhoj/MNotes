import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/providers/data_providers.dart';
import '../../../../domain/models/note.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../dialogs/add_tag_dialog.dart';

const _uuid = Uuid();

class NoteCard extends ConsumerStatefulWidget {
  final Note note;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onActionCompleted;

  const NoteCard({
    super.key,
    required this.note,
    required this.selected,
    required this.onTap,
    this.onActionCompleted,
  });

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {
  bool _isHovered = false;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat.jm().format(dt);
    }
    if (dt.year == now.year) {
      return DateFormat('MMM d').format(dt);
    }
    return DateFormat('MM/dd/yy').format(dt);
  }

  void _handleRename(BuildContext context, dynamic repo, AppColorScheme colors) async {
    final controller = TextEditingController(text: widget.note.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colors.border.withOpacity(0.5)),
        ),
        title: Text(
          'Rename Note',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(fontSize: 13, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new note title...',
            hintStyle: TextStyle(fontSize: 13, color: colors.textTertiary),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.trim().isNotEmpty) {
      await repo.saveNote(widget.note.copyWith(
        title: newTitle.trim(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  void _handleDuplicate(dynamic repo) async {
    final newId = _uuid.v4();
    final copyNote = widget.note.copyWith(
      id: newId,
      title: widget.note.title.isEmpty ? 'Untitled Copy' : '${widget.note.title} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repo.saveNote(copyNote);
    for (final tag in widget.note.tags) {
      await repo.addTagToNote(newId, tag.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDark;
    final repo = ref.read(noteRepositoryProvider);

    final cardWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.selected
                ? colors.noteCardSelected
                : (_isHovered
                    ? (isDark ? colors.surface2.withOpacity(0.5) : colors.surface2.withOpacity(0.7))
                    : Colors.transparent),
            gradient: widget.selected ? colors.prismGradient : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: widget.selected
                  ? colors.primary.withOpacity(0.4)
                  : (_isHovered
                      ? colors.border.withOpacity(0.7)
                      : Colors.transparent),
              width: 1.0,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Action Row
                  Row(
                    children: [
                      // Active indicator bar
                      if (widget.selected)
                        Container(
                          width: 3.5,
                          height: 14,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          widget.note.title.trim().isEmpty ? 'Untitled Document' : widget.note.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                            color: widget.note.title.trim().isEmpty
                                ? colors.textTertiary
                                : (widget.selected ? colors.primary : colors.textPrimary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Favorite icon
                      if (widget.note.isFavorite && !widget.note.isTrashed)
                        const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        ),
                      // Options popup menu
                      _buildCardMenu(context, repo, colors),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Content Preview Text
                  Text(
                    widget.note.preview.trim().isEmpty ? 'No text preview...' : widget.note.preview,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),

                  // Bottom Meta Row: Date & Tags
                  Row(
                    children: [
                      Text(
                        _formatDate(widget.note.updatedAt),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: widget.note.tags.map((t) {
                              final tagColor = t.colorValue != null ? Color(t.colorValue!) : colors.primary;
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: tagColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                    border: Border.all(color: tagColor.withOpacity(0.25), width: 0.7),
                                  ),
                                  child: Text(
                                    '#${t.name}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: tagColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Draggable<Note>(
      data: widget.note,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: colors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.note.title.trim().isEmpty ? 'Untitled Document' : widget.note.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: cardWidget,
      ),
      child: cardWidget,
    );
  }

  Widget _buildCardMenu(BuildContext context, dynamic repo, AppColorScheme colors) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, size: 16, color: colors.textTertiary),
      tooltip: 'Note actions',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(color: colors.border.withOpacity(0.5)),
      ),
      onSelected: (action) async {
        switch (action) {
          case 'rename':
            _handleRename(context, repo, colors);
            break;
          case 'duplicate':
            _handleDuplicate(repo);
            break;
          case 'favorite':
            await repo.toggleFavorite(widget.note.id);
            break;
          case 'add_tag':
            showDialog(
              context: context,
              builder: (ctx) => AddTagDialog(
                currentTags: widget.note.tags,
                onTagSelected: (tag) async {
                  await repo.addTagToNote(widget.note.id, tag.id);
                },
              ),
            );
            break;
          case 'move_folder':
            final folders = await ref.read(noteRepositoryProvider).watchAllFolders().first;
            if (!context.mounted) return;
            final chosen = await showDialog<String?>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: colors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                title: Text('Move to Folder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                content: SizedBox(
                  width: 280,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.inbox_rounded, size: 20),
                        title: const Text('Inbox (No Folder)', style: TextStyle(fontSize: 13)),
                        onTap: () => Navigator.pop(ctx, ''),
                      ),
                      const Divider(),
                      ...folders.map((f) => ListTile(
                            leading: Icon(
                              Icons.folder_rounded,
                              size: 20,
                              color: f.colorValue != null ? Color(f.colorValue!) : colors.primary,
                            ),
                            title: Text(f.name, style: const TextStyle(fontSize: 13)),
                            onTap: () => Navigator.pop(ctx, f.id),
                          )),
                    ],
                  ),
                ),
              ),
            );
            if (chosen != null) {
              await repo.moveNoteToFolder(widget.note.id, chosen.isEmpty ? null : chosen);
            }
            break;
          case 'trash':
            await repo.moveToTrash(widget.note.id);
            widget.onActionCompleted?.call();
            break;
          case 'restore':
            await repo.restoreFromTrash(widget.note.id);
            break;
          case 'delete_permanent':
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: colors.surface,
                title: const Text('Delete permanently?'),
                content: const Text('This will permanently delete this note and cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await repo.deletePermanently(widget.note.id);
              widget.onActionCompleted?.call();
            }
            break;
        }
      },
      itemBuilder: (context) {
        if (widget.note.isTrashed) {
          return [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore_rounded, size: 16, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Restore Note', style: TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete_permanent',
              child: Row(
                children: [
                  Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete Permanently', style: TextStyle(fontSize: 12.5, color: AppColors.error)),
                ],
              ),
            ),
          ];
        }

        return [
          PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                const Text('Rename Note', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_rounded, size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                const Text('Duplicate', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'favorite',
            child: Row(
              children: [
                Icon(
                  widget.note.isFavorite ? Icons.star_border_rounded : Icons.star_rounded,
                  size: 16,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Text(widget.note.isFavorite ? 'Unfavorite' : 'Add to Favorites', style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'move_folder',
            child: Row(
              children: [
                Icon(Icons.drive_file_move_outlined, size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                const Text('Move to Folder...', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'add_tag',
            child: Row(
              children: [
                Icon(Icons.tag_rounded, size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                const Text('Manage Tags...', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'trash',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text('Move to Trash', style: TextStyle(fontSize: 12.5, color: AppColors.error)),
              ],
            ),
          ),
        ];
      },
    );
  }
}

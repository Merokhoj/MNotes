import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/data_providers.dart';
import '../../../../domain/models/note.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/neo_glass.dart';
import 'note_card.dart';
import 'sidebar.dart';

enum NoteSortOption {
  updatedDesc('Recent'),
  titleAsc('A-Z'),
  createdDesc('Created');

  final String label;
  const NoteSortOption(this.label);
}

class NotesListWidget extends ConsumerStatefulWidget {
  final SidebarSelection selection;
  final String searchQuery;
  final String? selectedNoteId;
  final ValueChanged<String> onNoteSelected;
  final VoidCallback? onNoteActionCompleted;

  const NotesListWidget({
    super.key,
    required this.selection,
    required this.searchQuery,
    required this.selectedNoteId,
    required this.onNoteSelected,
    this.onNoteActionCompleted,
  });

  @override
  ConsumerState<NotesListWidget> createState() => _NotesListWidgetState();
}

class _NotesListWidgetState extends ConsumerState<NotesListWidget> {
  NoteSortOption _sortOption = NoteSortOption.updatedDesc;
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  @override
  void didUpdateWidget(NotesListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection || oldWidget.searchQuery != widget.searchQuery) {
      _selectedNoteIds.clear();
      _isSelectionMode = false;
    }
  }

  AsyncValue<List<Note>> _getNotes(WidgetRef ref) {
    if (widget.searchQuery.trim().isNotEmpty) {
      return ref.watch(searchNotesProvider(widget.searchQuery.trim()));
    }

    switch (widget.selection.type) {
      case SidebarFilterType.allNotes:
        return ref.watch(allNotesProvider);
      case SidebarFilterType.inbox:
        return ref.watch(inboxNotesProvider);
      case SidebarFilterType.favorites:
        return ref.watch(favoriteNotesProvider);
      case SidebarFilterType.trash:
        return ref.watch(trashedNotesProvider);
      case SidebarFilterType.folder:
        return ref.watch(folderNotesProvider(widget.selection.id ?? ''));
      case SidebarFilterType.tag:
        return ref.watch(tagNotesProvider(widget.selection.id ?? ''));
    }
  }

  List<Note> _applySorting(List<Note> notes) {
    final list = List<Note>.from(notes);
    switch (_sortOption) {
      case NoteSortOption.updatedDesc:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSortOption.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSortOption.createdDesc:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  Future<void> _handleBulkDelete(BuildContext context, bool isTrash, List<Note> currentNotes) async {
    if (_selectedNoteIds.isEmpty) return;

    final count = _selectedNoteIds.length;
    final colors = context.appColors;
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colors.border.withOpacity(0.5)),
        ),
        title: Row(
          children: [
            Icon(
              isTrash ? Icons.delete_forever_rounded : Icons.delete_sweep_rounded,
              color: AppColors.error,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isTrash ? 'Permanently Delete?' : 'Move to Trash?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          isTrash
              ? 'Permanently delete $count selected note${count > 1 ? 's' : ''}? This action cannot be undone.'
              : 'Move $count selected note${count > 1 ? 's' : ''} to the trash? You can restore them anytime from Trash.',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(isTrash ? 'Delete Permanently' : 'Move to Trash'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(noteRepositoryProvider);
      final ids = _selectedNoteIds.toList();

      if (isTrash) {
        await repo.batchDeletePermanently(ids);
      } else {
        await repo.batchMoveToTrash(ids);
      }

      if (widget.selectedNoteId != null && ids.contains(widget.selectedNoteId)) {
        widget.onNoteActionCompleted?.call();
      }

      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(
            content: Text(
              isTrash
                  ? 'Permanently deleted $count note${count > 1 ? 's' : ''}'
                  : 'Moved $count note${count > 1 ? 's' : ''} to Trash',
              style: const TextStyle(fontSize: 13),
            ),
            duration: const Duration(seconds: 3),
            action: !isTrash
                ? SnackBarAction(
                    label: 'Undo',
                    onPressed: () async {
                      await repo.batchRestoreFromTrash(ids);
                    },
                  )
                : null,
          ),
        );

        setState(() {
          _selectedNoteIds.clear();
          _isSelectionMode = false;
        });
    }
  }

  Future<void> _handleBulkMoveToFolder(BuildContext context) async {
    if (_selectedNoteIds.isEmpty) return;

    final foldersAsync = ref.read(allFoldersProvider);
    final folders = foldersAsync.value ?? [];
    final colors = context.appColors;

    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colors.border.withOpacity(0.5)),
        ),
        title: Text(
          'Move ${_selectedNoteIds.length} Notes to Folder',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
        ),
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
              ...folders.map(
                (f) => ListTile(
                  leading: Icon(
                    Icons.folder_rounded,
                    size: 20,
                    color: f.colorValue != null ? Color(f.colorValue!) : colors.primary,
                  ),
                  title: Text(f.name, style: const TextStyle(fontSize: 13)),
                  onTap: () => Navigator.pop(ctx, f.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (chosen != null) {
      final repo = ref.read(noteRepositoryProvider);
      await repo.batchMoveNoteToFolder(
        _selectedNoteIds.toList(),
        chosen.isEmpty ? null : chosen,
      );
      if (mounted) {
        setState(() {
          _selectedNoteIds.clear();
          _isSelectionMode = false;
        });
      }
    }
  }

  Future<void> _handleBulkRestore(BuildContext context) async {
    if (_selectedNoteIds.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(noteRepositoryProvider);
    final count = _selectedNoteIds.length;
    await repo.batchRestoreFromTrash(_selectedNoteIds.toList());
    if (!mounted) return;
    messenger.showSnackBar(
        SnackBar(
          content: Text('Restored $count note${count > 1 ? 's' : ''}'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
  }

  Widget _buildBulkActionBar(BuildContext context, AppColorScheme colors, bool isTrash, List<Note> notes) {
    final count = _selectedNoteIds.length;
    final allSelected = count == notes.length && notes.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface2.withOpacity(0.96),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 265;

          final selectAllBtn = TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              setState(() {
                if (allSelected) {
                  _selectedNoteIds.clear();
                } else {
                  _selectedNoteIds.addAll(notes.map((n) => n.id));
                }
              });
            },
            child: Text(
              allSelected ? 'Deselect All' : 'Select All',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          );

          final countBadge = NeoGlassBadge(
            label: '$count selected',
            color: colors.primary,
          );

          final restoreBtn = Tooltip(
            message: 'Restore selected ($count)',
            child: IconButton(
              icon: const Icon(Icons.restore_from_trash_rounded, size: 18),
              color: AppColors.success,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              splashRadius: 16,
              onPressed: count > 0 ? () => _handleBulkRestore(context) : null,
            ),
          );

          final moveToFolderBtn = Tooltip(
            message: 'Move selected to folder ($count)',
            child: IconButton(
              icon: const Icon(Icons.drive_file_move_outlined, size: 18),
              color: colors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              splashRadius: 16,
              onPressed: count > 0 ? () => _handleBulkMoveToFolder(context) : null,
            ),
          );

          final deleteBtn = Tooltip(
            message: isTrash
                ? 'Delete permanently ($count)'
                : 'Move to trash ($count)',
            child: InkWell(
              onTap: count > 0
                  ? () => _handleBulkDelete(context, isTrash, notes)
                  : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: count > 0
                      ? AppColors.error.withOpacity(0.12)
                      : colors.surface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: count > 0
                        ? AppColors.error.withOpacity(0.5)
                        : colors.border.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTrash ? Icons.delete_forever_rounded : Icons.delete_outline_rounded,
                      size: 14,
                      color: count > 0 ? AppColors.error : colors.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isTrash ? 'Delete' : 'Remove',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: count > 0 ? AppColors.error : colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    countBadge,
                    const Spacer(),
                    selectAllBtn,
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isTrash) restoreBtn,
                    if (!isTrash) moveToFolderBtn,
                    const SizedBox(width: 6),
                    deleteBtn,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              countBadge,
              const SizedBox(width: 8),
              selectAllBtn,
              const Spacer(),
              if (isTrash) restoreBtn,
              if (!isTrash) moveToFolderBtn,
              const SizedBox(width: 4),
              deleteBtn,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final notesAsync = _getNotes(ref);
    final isTrash = widget.selection.type == SidebarFilterType.trash;

    final title = widget.searchQuery.isNotEmpty
        ? 'Search "${widget.searchQuery.trim()}"'
        : widget.selection.title;

    return Container(
      color: colors.surface,
      child: Column(
        children: [
          // Section Header (Frosted bar with counts, multi-select, and sort)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.5))),
            ),
            child: notesAsync.when(
              data: (rawNotes) {
                final notes = _applySorting(rawNotes);

                if (_isSelectionMode) {
                  final allSelected = notes.isNotEmpty && _selectedNoteIds.length == notes.length;
                  return Row(
                    children: [
                      // Tristate Checkbox for Select All
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          tristate: true,
                          value: notes.isEmpty
                              ? false
                              : (allSelected
                                  ? true
                                  : (_selectedNoteIds.isNotEmpty ? null : false)),
                          activeColor: colors.primary,
                          checkColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: colors.primary.withOpacity(0.7),
                            width: 1.5,
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (allSelected) {
                                _selectedNoteIds.clear();
                              } else {
                                _selectedNoteIds.addAll(notes.map((n) => n.id));
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          '${_selectedNoteIds.length} of ${notes.length} selected',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Select All / Deselect All button
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            if (allSelected) {
                              _selectedNoteIds.clear();
                            } else {
                              _selectedNoteIds.addAll(notes.map((n) => n.id));
                            }
                          });
                        },
                        child: Text(
                          allSelected ? 'Deselect All' : 'Select All',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Exit selection mode (X)
                      Tooltip(
                        message: 'Exit selection',
                        child: IconButton(
                          icon: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          splashRadius: 16,
                          onPressed: () {
                            setState(() {
                              _isSelectionMode = false;
                              _selectedNoteIds.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }

                // Normal header
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Note count badge
                    NeoGlassBadge(
                      label: '${notes.length}',
                      color: colors.primary,
                    ),

                    const SizedBox(width: 6),

                    // Multi-select / Select All toggle button
                    if (notes.isNotEmpty)
                      Tooltip(
                        message: 'Select / Select All',
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isSelectionMode = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surface2.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: colors.border.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.checklist_rounded, size: 15, color: colors.textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  'Select',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(width: 6),

                    // Sorting dropdown menu
                    PopupMenuButton<NoteSortOption>(
                      tooltip: 'Sort Notes',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: Icon(Icons.sort_rounded, size: 16, color: colors.textSecondary),
                      color: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        side: BorderSide(color: colors.border.withOpacity(0.5)),
                      ),
                      onSelected: (opt) => setState(() => _sortOption = opt),
                      itemBuilder: (ctx) => NoteSortOption.values.map((opt) {
                        final isSel = _sortOption == opt;
                        return PopupMenuItem(
                          value: opt,
                          child: Row(
                            children: [
                              Icon(
                                isSel ? Icons.check_rounded : Icons.radio_button_unchecked,
                                size: 14,
                                color: isSel ? colors.primary : colors.textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Text('Sort: ${opt.label}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
              loading: () => Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notes List Content
          Expanded(
            child: notesAsync.when(
              data: (rawNotes) {
                final notes = _applySorting(rawNotes);

                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTrash
                                  ? Icons.delete_outline_rounded
                                  : Icons.note_alt_outlined,
                              size: 32,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            isTrash
                                ? 'Trash is empty'
                                : (widget.searchQuery.isNotEmpty ? 'No matching notes' : 'No notes here yet'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isTrash
                                ? 'Items moved to trash will appear here.'
                                : 'Start writing by creating a new note.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    final isChecked = _selectedNoteIds.contains(note.id);
                    return NoteCard(
                      key: ValueKey(note.id),
                      note: note,
                      selected: widget.selectedNoteId == note.id,
                      isSelectionMode: _isSelectionMode,
                      isChecked: isChecked,
                      onCheckedChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedNoteIds.add(note.id);
                          } else {
                            _selectedNoteIds.remove(note.id);
                          }
                        });
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedNoteIds.add(note.id);
                          });
                        }
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (isChecked) {
                              _selectedNoteIds.remove(note.id);
                            } else {
                              _selectedNoteIds.add(note.id);
                            }
                          });
                        } else {
                          widget.onNoteSelected(note.id);
                        }
                      },
                      onActionCompleted: widget.onNoteActionCompleted,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, _) => Center(
                child: Text('Error loading notes: $err', style: const TextStyle(fontSize: 12, color: AppColors.error)),
              ),
            ),
          ),

          // Floating / Docked Neo-Glass Bulk Action Bar (when in selection mode)
          if (_isSelectionMode)
            notesAsync.maybeWhen(
              data: (rawNotes) {
                final notes = _applySorting(rawNotes);
                return _buildBulkActionBar(context, colors, isTrash, notes);
              },
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

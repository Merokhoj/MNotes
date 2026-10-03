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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final notesAsync = _getNotes(ref);

    final title = widget.searchQuery.isNotEmpty
        ? 'Search "${widget.searchQuery.trim()}"'
        : widget.selection.title;

    return Container(
      color: colors.surface,
      child: Column(
        children: [
          // Section Header (Frosted bar with counts and sort)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.5))),
            ),
            child: Row(
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
                notesAsync.when(
                  data: (notes) => NeoGlassBadge(
                    label: '${notes.length}',
                    color: colors.primary,
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
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
                              widget.selection.type == SidebarFilterType.trash
                                  ? Icons.delete_outline_rounded
                                  : Icons.note_alt_outlined,
                              size: 32,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            widget.selection.type == SidebarFilterType.trash
                                ? 'Trash is empty'
                                : (widget.searchQuery.isNotEmpty ? 'No matching notes' : 'No notes here yet'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.selection.type == SidebarFilterType.trash
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
                    return NoteCard(
                      key: ValueKey(note.id),
                      note: note,
                      selected: widget.selectedNoteId == note.id,
                      onTap: () => widget.onNoteSelected(note.id),
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
        ],
      ),
    );
  }
}

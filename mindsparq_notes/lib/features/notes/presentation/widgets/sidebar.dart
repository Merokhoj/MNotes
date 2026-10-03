import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/data_providers.dart';
import '../../../../domain/models/folder.dart';
import '../../../../domain/models/note.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import 'package:mindsparq_notes/features/settings/presentation/settings_dialog.dart';
import '../dialogs/create_folder_dialog.dart';

enum SidebarFilterType {
  allNotes,
  inbox,
  favorites,
  trash,
  folder,
  tag,
}

class SidebarSelection {
  final SidebarFilterType type;
  final String? id;
  final String title;

  const SidebarSelection({
    required this.type,
    this.id,
    required this.title,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SidebarSelection &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => type.hashCode ^ id.hashCode;
}

class SidebarWidget extends ConsumerWidget {
  final bool isCollapsed;
  final SidebarSelection selection;
  final ValueChanged<SidebarSelection> onSelectionChanged;
  final ValueChanged<String> onSearchChanged;
  final String searchQuery;

  const SidebarWidget({
    super.key,
    required this.isCollapsed,
    required this.selection,
    required this.onSelectionChanged,
    required this.onSearchChanged,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final foldersAsync = ref.watch(allFoldersProvider);
    final tagsAsync = ref.watch(allTagsProvider);

    return Container(
      color: colors.sidebarBackground,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(isCollapsed ? AppSpacing.sm : AppSpacing.md),
            child: isCollapsed
                ? Tooltip(
                    message: 'Search notes',
                    child: IconButton(
                      icon: Icon(Icons.search_rounded, size: 20, color: colors.textSecondary),
                      onPressed: () {},
                    ),
                  )
                : _SearchBar(query: searchQuery, onChanged: onSearchChanged),
          ),

          // Main Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              children: [
                _SidebarItem(
                  icon: Icons.notes_rounded,
                  label: 'All Notes',
                  selected: selection.type == SidebarFilterType.allNotes,
                  isCollapsed: isCollapsed,
                  onTap: () => onSelectionChanged(const SidebarSelection(
                    type: SidebarFilterType.allNotes,
                    title: 'All Notes',
                  )),
                ),
                DragTarget<Note>(
                  onWillAcceptWithDetails: (details) => details.data.folderId != null,
                  onAcceptWithDetails: (details) async {
                    final note = details.data;
                    await ref.read(noteRepositoryProvider).saveNote(note.copyWith(folderId: null));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Moved "${note.title.trim().isEmpty ? 'Untitled Document' : note.title}" to Inbox'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isDropTarget = candidateData.isNotEmpty;
                    return Container(
                      decoration: isDropTarget
                          ? BoxDecoration(
                              color: colors.primary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: colors.primary, width: 1.5),
                            )
                          : null,
                      child: _SidebarItem(
                        icon: isDropTarget ? Icons.move_to_inbox_rounded : Icons.inbox_rounded,
                        label: isDropTarget ? 'Drop into Inbox' : 'Inbox',
                        selected: selection.type == SidebarFilterType.inbox,
                        isCollapsed: isCollapsed,
                        onTap: () => onSelectionChanged(const SidebarSelection(
                          type: SidebarFilterType.inbox,
                          title: 'Inbox',
                        )),
                      ),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.star_rounded,
                  label: 'Favorites',
                  selected: selection.type == SidebarFilterType.favorites,
                  isCollapsed: isCollapsed,
                  onTap: () => onSelectionChanged(const SidebarSelection(
                    type: SidebarFilterType.favorites,
                    title: 'Favorites',
                  )),
                ),
                _SidebarItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Trash',
                  selected: selection.type == SidebarFilterType.trash,
                  isCollapsed: isCollapsed,
                  onTap: () => onSelectionChanged(const SidebarSelection(
                    type: SidebarFilterType.trash,
                    title: 'Trash',
                  )),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Folders Section ─────────────────────────────────────
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FOLDERS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.textTertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => const CreateFolderDialog(),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.add, size: 16, color: colors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Divider(height: 16),

                foldersAsync.when(
                  data: (folders) {
                    if (folders.isEmpty && !isCollapsed) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                        child: Text('No folders yet',
                            style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                      );
                    }
                    return Column(
                      children: folders.map((f) {
                        final isSelected = selection.type == SidebarFilterType.folder && selection.id == f.id;

                        return _FolderSidebarItem(
                          folder: f,
                          selected: isSelected,
                          isCollapsed: isCollapsed,
                          onTap: () => onSelectionChanged(SidebarSelection(
                            type: SidebarFilterType.folder,
                            id: f.id,
                            title: f.name,
                          )),
                          onEdit: () => _handleEditFolder(context, f),
                          onDelete: () => _handleDeleteFolder(context, ref, f, colors),
                          onNoteDropped: (note) async {
                            await ref.read(noteRepositoryProvider).saveNote(note.copyWith(folderId: f.id));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Moved "${note.title.trim().isEmpty ? 'Untitled Document' : note.title}" to ${f.name}'),
                                  backgroundColor: AppColors.success,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Tags Section ────────────────────────────────────────
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    child: Text(
                      'TAGS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.textTertiary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else
                  const Divider(height: 16),

                tagsAsync.when(
                  data: (tags) {
                    if (tags.isEmpty && !isCollapsed) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                        child: Text('No tags yet',
                            style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                      );
                    }
                    return Column(
                      children: tags.map((t) {
                        final isSelected = selection.type == SidebarFilterType.tag && selection.id == t.id;
                        final tagColor = t.colorValue != null ? Color(t.colorValue!) : colors.primary;

                        return _SidebarItem(
                          icon: Icons.tag_rounded,
                          iconColor: tagColor,
                          label: t.name,
                          selected: isSelected,
                          isCollapsed: isCollapsed,
                          onTap: () => onSelectionChanged(SidebarSelection(
                            type: SidebarFilterType.tag,
                            id: t.id,
                            title: '#${t.name}',
                          )),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),

          // User Profile / Settings at bottom
          Container(height: 1, color: colors.border.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => const SettingsDialog(),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: colors.primary.withOpacity(0.15),
                      child: Icon(Icons.person_outline_rounded, size: 16, color: colors.primary),
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Local Workspace',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.settings_outlined, size: 16, color: colors.textTertiary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEditFolder(BuildContext context, Folder folder) async {
    await showDialog(
      context: context,
      builder: (ctx) => CreateFolderDialog(folderToEdit: folder),
    );
  }

  void _handleDeleteFolder(BuildContext context, WidgetRef ref, Folder folder, AppColorScheme colors) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colors.border.withOpacity(0.5)),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete "${folder.name}"?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          'Notes inside this folder will not be deleted.\nThey will be safely moved to your Inbox.',
          style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
            child: const Text('Delete Folder', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(noteRepositoryProvider).deleteFolder(folder.id);
      if (selection.type == SidebarFilterType.folder && selection.id == folder.id) {
        onSelectionChanged(const SidebarSelection(type: SidebarFilterType.allNotes, title: 'All Notes'));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder "${folder.name}" deleted. Notes moved to Inbox.'),
            backgroundColor: colors.surface2,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _SearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.query, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
      _controller.selection = TextSelection.collapsed(offset: widget.query.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.border.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 9),
          Icon(Icons.search_rounded, size: 16, color: colors.textTertiary),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: TextStyle(fontSize: 12, color: colors.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 12),
                isDense: true,
                filled: false,
              ),
            ),
          ),
          if (widget.query.isNotEmpty)
            InkWell(
              onTap: () {
                _controller.clear();
                widget.onChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.clear_rounded, size: 14, color: colors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool selected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.selected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCollapsed ? 0 : AppSpacing.sm + 2,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: widget.selected
              ? colors.primary.withOpacity(0.12)
              : (_isHovered ? colors.surface2.withOpacity(0.6) : Colors.transparent),
          gradient: widget.selected ? colors.prismGradient : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: widget.selected
                ? colors.primary.withOpacity(0.35)
                : (_isHovered ? colors.border.withOpacity(0.5) : Colors.transparent),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              widget.icon,
              size: 17,
              color: widget.selected
                  ? colors.primary
                  : (widget.iconColor ?? (_isHovered ? colors.textPrimary : colors.textSecondary)),
            ),
            if (!widget.isCollapsed) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
                    color: widget.selected ? colors.primary : colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: widget.isCollapsed ? Tooltip(message: widget.label, child: content) : content,
      ),
    );
  }
}

class _FolderSidebarItem extends StatefulWidget {
  final Folder folder;
  final bool selected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Note) onNoteDropped;

  const _FolderSidebarItem({
    required this.folder,
    required this.selected,
    required this.isCollapsed,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onNoteDropped,
  });

  @override
  State<_FolderSidebarItem> createState() => _FolderSidebarItemState();
}

class _FolderSidebarItemState extends State<_FolderSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final folderColor = widget.folder.colorValue != null
        ? Color(widget.folder.colorValue!)
        : colors.primary;

    return DragTarget<Note>(
      onWillAcceptWithDetails: (details) => details.data.folderId != widget.folder.id,
      onAcceptWithDetails: (details) => widget.onNoteDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;

        Widget content = MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : AppSpacing.sm + 2,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isDropTarget
                  ? colors.primary.withOpacity(0.2)
                  : (widget.selected
                      ? colors.primary.withOpacity(0.12)
                      : (_isHovered ? colors.surface2.withOpacity(0.6) : Colors.transparent)),
              gradient: widget.selected && !isDropTarget ? colors.prismGradient : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: isDropTarget
                    ? colors.primary
                    : (widget.selected
                        ? colors.primary.withOpacity(0.35)
                        : (_isHovered ? colors.border.withOpacity(0.5) : Colors.transparent)),
                width: isDropTarget ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  isDropTarget ? Icons.folder_open_rounded : Icons.folder_rounded,
                  size: 17,
                  color: isDropTarget ? colors.primary : folderColor,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isDropTarget ? 'Drop into ${widget.folder.name}' : widget.folder.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: (widget.selected || isDropTarget) ? FontWeight.w700 : FontWeight.w500,
                        color: (widget.selected || isDropTarget) ? colors.primary : colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Action Menu Button on Hover
                  if (_isHovered && !isDropTarget)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, size: 16, color: colors.textTertiary),
                      tooltip: 'Folder options',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      color: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        side: BorderSide(color: colors.border.withOpacity(0.5)),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') widget.onEdit();
                        if (val == 'delete') widget.onDelete();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 15),
                              SizedBox(width: 8),
                              Text('Edit / Rename', style: TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete Folder', style: TextStyle(fontSize: 12.5, color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: widget.isCollapsed ? Tooltip(message: widget.folder.name, child: content) : content,
          ),
        );
      },
    );
  }
}


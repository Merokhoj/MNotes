import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/neo_glass.dart';
import '../../data/providers/data_providers.dart';
import '../../domain/models/note.dart';
import '../../features/notes/presentation/note_editor_screen.dart';
import '../../features/notes/presentation/widgets/sidebar.dart';
import '../../features/notes/presentation/widgets/notes_list.dart';
import '../../features/notes/presentation/widgets/title_bar.dart';
import '../../features/media/data/services/attachment_storage_service.dart';
import '../../features/export/services/document_export_service.dart';
import '../providers/settings_provider.dart';

const _uuid = Uuid();

class AppShellPage extends ConsumerStatefulWidget {
  final VoidCallback onNewNote;
  const AppShellPage({super.key, required this.onNewNote});

  @override
  ConsumerState<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends ConsumerState<AppShellPage> {
  String? _selectedNoteId;
  bool _showEditor = false;
  String _searchQuery = '';

  SidebarSelection _selection = const SidebarSelection(
    type: SidebarFilterType.allNotes,
    title: 'All Notes',
  );

  bool _isSidebarCollapsed = false;
  bool _isNotesListCollapsed = false;
  bool _isSidebarDragging = false;
  bool _isNotesListDragging = false;

  void _handleNewNote() async {
    final newId = _uuid.v4();
    final repo = ref.read(noteRepositoryProvider);
    final newNote = Note(
      id: newId,
      title: '',
      preview: '',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repo.saveNote(newNote);

    setState(() {
      _selectedNoteId = newId;
      _showEditor = true;
    });
    widget.onNewNote();
  }

  void _handleImportNote() async {
    final service = ref.read(attachmentServiceProvider);
    final filePath = await service.pickNativeFilePath();
    if (filePath == null) return;

    try {
      final parsed = await DocumentExportService.parseMarkdownImport(filePath);
      final newId = _uuid.v4();
      final repo = ref.read(noteRepositoryProvider);
      final newNote = Note(
        id: newId,
        title: parsed['title'] ?? 'Imported Note',
        preview: parsed['content']?.isNotEmpty == true
            ? (parsed['content']!.length > 100
                ? '${parsed['content']!.substring(0, 100)}...'
                : parsed['content']!)
            : '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.saveNote(newNote);

      setState(() {
        _selectedNoteId = newId;
        _showEditor = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${parsed["title"]}" successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleNoteSelected(String id) {
    setState(() {
      _selectedNoteId = id;
      _showEditor = true;
    });
  }

  void _handleBackToNotes() {
    setState(() {
      _showEditor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          return _buildMobileLayout(context, colors);
        } else {
          return _buildDesktopLayout(context, colors);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppColorScheme colors) {
    return PopScope(
      canPop: !_showEditor,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showEditor) {
          _handleBackToNotes();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: _showEditor
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to notes',
                  onPressed: _handleBackToNotes,
                )
              : Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Open menu',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
          title: Text(
            _showEditor ? 'Edit Note' : _selection.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          actions: [
            if (!_showEditor)
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Create new note',
                onPressed: _handleNewNote,
              ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: colors.sidebarBackground,
          child: SafeArea(
            child: SidebarWidget(
              isCollapsed: false,
              selection: _selection,
              searchQuery: _searchQuery,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              onSelectionChanged: (newSel) {
                setState(() {
                  _selection = newSel;
                  _showEditor = false;
                });
                Navigator.pop(context);
              },
            ),
          ),
        ),
        body: _showEditor && _selectedNoteId != null
            ? NoteEditorScreen(noteId: _selectedNoteId!)
            : NotesListWidget(
                selection: _selection,
                searchQuery: _searchQuery,
                selectedNoteId: _selectedNoteId,
                onNoteSelected: _handleNoteSelected,
                onNoteActionCompleted: () {
                  setState(() {
                    _selectedNoteId = null;
                    _showEditor = false;
                  });
                },
              ),
        floatingActionButton: (!_showEditor)
            ? FloatingActionButton(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                onPressed: _handleNewNote,
                tooltip: 'New Note',
                child: const Icon(Icons.add_rounded, size: 24),
              )
            : null,
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppColorScheme colors) {
    final settings = ref.watch(settingsProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _handleNewNote,
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): _handleImportNote,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: colors.background,
          body: Column(
            children: [
              // ── Title Bar ─────────────────────────────────────────────
              TitleBarWidget(
                onNewNote: _handleNewNote,
                onImportNote: _handleImportNote,
                isSidebarCollapsed: _isSidebarCollapsed,
                isNotesListCollapsed: _isNotesListCollapsed,
                onToggleSidebar: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                onToggleNotesList: () => setState(() => _isNotesListCollapsed = !_isNotesListCollapsed),
              ),
              // ── 3-Column Main Area ─────────────────────────────────────
              Expanded(
                child: Row(
                  children: [
                    // 1. Left Sidebar
                    AnimatedContainer(
                      duration: _isSidebarDragging ? Duration.zero : const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: _isSidebarCollapsed ? AppSpacing.sidebarCollapsedWidth : settings.sidebarWidth,
                      decoration: BoxDecoration(color: colors.sidebarBackground),
                      child: SidebarWidget(
                        isCollapsed: _isSidebarCollapsed,
                        selection: _selection,
                        searchQuery: _searchQuery,
                        onSearchChanged: (q) => setState(() => _searchQuery = q),
                        onSelectionChanged: (newSel) => setState(() => _selection = newSel),
                      ),
                    ),
                    ResizeSplitter(
                      color: colors.border.withOpacity(0.5),
                      activeColor: colors.primary,
                      onDragStart: () => setState(() => _isSidebarDragging = true),
                      onDragEnd: () => setState(() => _isSidebarDragging = false),
                      onDrag: (dx) {
                        if (!_isSidebarCollapsed) {
                          ref.read(settingsProvider.notifier).updateSidebarWidth(settings.sidebarWidth + dx);
                        }
                      },
                    ),

                    // 2. Middle Notes List
                    AnimatedContainer(
                      duration: _isNotesListDragging ? Duration.zero : const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: _isNotesListCollapsed ? 0 : settings.notesListWidth,
                      decoration: BoxDecoration(color: colors.surface),
                      clipBehavior: Clip.hardEdge,
                      child: OverflowBox(
                        minWidth: settings.notesListWidth,
                        maxWidth: settings.notesListWidth,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: settings.notesListWidth,
                          child: NotesListWidget(
                            selection: _selection,
                            searchQuery: _searchQuery,
                            selectedNoteId: _selectedNoteId,
                            onNoteSelected: _handleNoteSelected,
                            onNoteActionCompleted: () {
                              setState(() {
                                _selectedNoteId = null;
                                _showEditor = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    if (!_isNotesListCollapsed)
                      ResizeSplitter(
                        color: colors.border.withOpacity(0.5),
                        activeColor: colors.primary,
                        onDragStart: () => setState(() => _isNotesListDragging = true),
                        onDragEnd: () => setState(() => _isNotesListDragging = false),
                        onDrag: (dx) {
                          ref.read(settingsProvider.notifier).updateNotesListWidth(settings.notesListWidth + dx);
                        },
                      ),

                    // 3. Right Editor Area
                    Expanded(
                      child: _showEditor && _selectedNoteId != null
                          ? NoteEditorScreen(
                              key: ValueKey(_selectedNoteId),
                              noteId: _selectedNoteId!,
                            )
                          : _EditorEmptyState(
                              onNewNote: _handleNewNote,
                              onImportNote: _handleImportNote,
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

class _EditorEmptyState extends StatelessWidget {
  final VoidCallback onNewNote;
  final VoidCallback? onImportNote;
  const _EditorEmptyState({required this.onNewNote, this.onImportNote});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: colors.prismGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.notePencil(PhosphorIconsStyle.bold),
                  size: 46,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'MindSparQ Notes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture ideas, organize research literature, and draft structured block documents with local-first speed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl + 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onImportNote != null) ...[
                    NeoGlassButton(
                      onPressed: onImportNote!,
                      tooltip: 'Import Markdown Note (Ctrl+O)',
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Row(
                        children: [
                          Icon(Icons.file_upload_outlined, size: 15, color: colors.textPrimary),
                          const SizedBox(width: 6),
                          const Text('Import File'),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  NeoGlassButton(
                    onPressed: onNewNote,
                    isPrimary: true,
                    tooltip: 'Create New Note (Ctrl+N)',
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Create Note', style: TextStyle(color: Colors.white)),
                      ],
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

/// Interactive draggable splitter handle for resizing panels
class ResizeSplitter extends StatefulWidget {
  final ValueChanged<double> onDrag;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final Color color;
  final Color activeColor;

  const ResizeSplitter({
    super.key,
    required this.onDrag,
    this.onDragStart,
    this.onDragEnd,
    required this.color,
    required this.activeColor,
  });

  @override
  State<ResizeSplitter> createState() => _ResizeSplitterState();
}

class _ResizeSplitterState extends State<ResizeSplitter> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final active = _isHovered || _isDragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          setState(() => _isDragging = true);
          widget.onDragStart?.call();
        },
        onHorizontalDragUpdate: (details) {
          widget.onDrag(details.delta.dx);
        },
        onHorizontalDragEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onHorizontalDragCancel: () {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        child: Container(
          width: 8,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: active ? 3.0 : 1.0,
            decoration: BoxDecoration(
              color: active ? widget.activeColor : widget.color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: widget.activeColor.withOpacity(0.35),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

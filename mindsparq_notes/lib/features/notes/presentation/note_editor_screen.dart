import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/neo_glass.dart';
import '../../../app/providers/note_editor_provider.dart';
import '../../../data/providers/data_providers.dart';
import '../../media/data/services/attachment_storage_service.dart';
import '../../media/presentation/dialogs/attach_file_dialog.dart';
import '../../research/data/services/research_storage_service.dart';
import '../../research/presentation/widgets/research_sidebar_panel.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/gestures.dart'
    show PointerScrollEvent, kSecondaryMouseButton;
import '../../export/presentation/dialogs/export_dialog.dart';
import '../../ai/presentation/dialogs/ai_action_dialog.dart';
import '../../ai/data/services/ai_writing_service.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../domain/models/note.dart';
import 'dialogs/add_tag_dialog.dart';
import 'services/markdown_paste_service.dart';
import 'widgets/editor_context_menu.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  String? _lastLoadedNoteId;
  bool _isResearchOpen = false;
  ResearchTab _researchTab = ResearchTab.aiAssistant;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  TextStyle _getEditorTextStyle(String fontName, double size, Color color, {double height = 1.15}) {
    switch (fontName) {
      case 'Outfit':
        return GoogleFonts.outfit(fontSize: size, height: height, color: color);
      case 'JetBrains Mono':
        return GoogleFonts.jetBrainsMono(
            fontSize: size, height: height, color: color);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(
            fontSize: size, height: height, color: color);
      case 'Merriweather':
        return GoogleFonts.merriweather(
            fontSize: size, height: height, color: color);
      case 'Inter':
      default:
        return GoogleFonts.inter(fontSize: size, height: height, color: color);
    }
  }

  void _insertImageNode(EditorState editorState, String imagePath) {
    final doc = editorState.document;
    final selection = editorState.selection;
    final int targetIndex = (selection != null && selection.end.path.isNotEmpty)
        ? selection.end.path[0] + 1
        : doc.root.children.length;

    final transaction = editorState.transaction;
    transaction.insertNode(
      [targetIndex],
      Node(
        type: 'image',
        attributes: {'url': imagePath},
      ),
    );
    editorState.apply(transaction);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image inserted into document!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handlePickAndInsertImage(EditorState editorState) async {
    final attachment = await showDialog(
      context: context,
      builder: (ctx) =>
          AttachFileDialog(noteId: widget.noteId, imagesOnly: true),
    );

    if (attachment != null && attachment.filePath != null) {
      _insertImageNode(editorState, attachment.filePath as String);
    }
  }

  void _handleOpenExport(NoteEditorState editorData) {
    showDialog(
      context: context,
      builder: (ctx) => ExportDialog(
        note: editorData.note,
        editorState: editorData.editorState,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final editorStateAsync =
        ref.watch(noteEditorControllerProvider(widget.noteId));
    final attachmentsAsync = ref.watch(noteAttachmentsProvider(widget.noteId));
    final researchAsync =
        ref.watch(researchMetadataStateProvider(widget.noteId));

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          ref
              .read(noteEditorControllerProvider(widget.noteId).notifier)
              .saveImmediately();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Note saved'),
                duration: Duration(milliseconds: 700)),
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyR,
            control: true, shift: true): () {
          setState(() => _isResearchOpen = !_isResearchOpen);
        },
      },
      child: Focus(
        autofocus: true,
        child: editorStateAsync.when(
          data: (editorData) {
            if (_lastLoadedNoteId != editorData.note.id) {
              _titleController.text = editorData.note.title;
              _lastLoadedNoteId = editorData.note.id;
            }

            final isResearchActive =
                researchAsync.value?.isResearchMode == true;
            final attachmentCount = attachmentsAsync.value?.length ?? 0;

            return Column(
              children: [
                // ── Top Header Bar (Frosted Navigation & Status) ───────────
                Container(
                  height: 46,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                        bottom:
                            BorderSide(color: colors.border.withOpacity(0.5))),
                  ),
                  child: LayoutBuilder(
                    builder: (context, headerConstraints) {
                      final isCompact = headerConstraints.maxWidth < 900;
                      final isNarrow = headerConstraints.maxWidth < 740;
                      final isUltraCompact = headerConstraints.maxWidth < 560;

                      return Row(
                        children: [
                          Icon(PhosphorIcons.folder(PhosphorIconsStyle.regular),
                              size: 15, color: colors.textTertiary),
                          const SizedBox(width: AppSpacing.xs),
                          if (!isCompact) ...[
                            Text(
                              'Notes',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textTertiary),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                                PhosphorIcons.caretRight(
                                    PhosphorIconsStyle.regular),
                                size: 11,
                                color: colors.textTertiary),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                editorData.note.title.isEmpty
                                    ? 'Untitled Document'
                                    : editorData.note.title,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Word Count & Reading Time Pill
                          if (!isUltraCompact)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: colors.surface2,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusFull),
                                border: Border.all(
                                    color: colors.border.withOpacity(0.6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isNarrow
                                        ? '${editorData.wordCount}w'
                                        : '${editorData.wordCount} words',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if (!isCompact) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                        width: 3,
                                        height: 3,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: colors.textTertiary)),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${editorData.readingTimeMinutes} min read',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: colors.textTertiary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          if (!isUltraCompact)
                            const SizedBox(width: AppSpacing.sm),

                          // Dynamic Auto-Save Indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: editorData.isSaving
                                  ? const Color(0xFFF59E0B).withOpacity(0.12)
                                  : AppColors.success.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(
                                color: editorData.isSaving
                                    ? const Color(0xFFF59E0B).withOpacity(0.3)
                                    : AppColors.success.withOpacity(0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  editorData.isSaving
                                      ? Icons.sync_rounded
                                      : Icons.cloud_done_rounded,
                                  size: 13,
                                  color: editorData.isSaving
                                      ? const Color(0xFFF59E0B)
                                      : AppColors.success,
                                ),
                                if (!isNarrow) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    editorData.isSaving ? 'Saving...' : 'Saved',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: editorData.isSaving
                                          ? const Color(0xFFF59E0B)
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Attachments Badge Button
                          Tooltip(
                            message: 'Attachments ($attachmentCount)',
                            child: InkWell(
                              onTap: () {
                                setState(() => _isResearchOpen = true);
                              },
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(PhosphorIcons.paperclip(),
                                        size: 16, color: colors.textSecondary),
                                    if (attachmentCount > 0) ...[
                                      const SizedBox(width: 3),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$attachmentCount',
                                          style: const TextStyle(
                                              fontSize: 9.5,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // AI Assistant Toggle Button
                          Tooltip(
                            message: (_isResearchOpen &&
                                    _researchTab == ResearchTab.aiAssistant)
                                ? 'Close AI Assistant'
                                : 'Open AI Assistant & Chat (Ctrl+Shift+A)',
                            child: InkWell(
                              onTap: () {
                                if (_isResearchOpen &&
                                    _researchTab == ResearchTab.aiAssistant) {
                                  setState(() => _isResearchOpen = false);
                                } else {
                                  setState(() {
                                    _isResearchOpen = true;
                                    _researchTab = ResearchTab.aiAssistant;
                                  });
                                }
                              },
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 7 : 10,
                                    vertical: 4.5),
                                decoration: BoxDecoration(
                                  color: (_isResearchOpen &&
                                          _researchTab ==
                                              ResearchTab.aiAssistant)
                                      ? AppColors.accent.withOpacity(0.18)
                                      : AppColors.accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                  border: Border.all(
                                    color: (_isResearchOpen &&
                                            _researchTab ==
                                                ResearchTab.aiAssistant)
                                        ? AppColors.accent
                                        : AppColors.accent.withOpacity(0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 15,
                                      color: AppColors.accent,
                                    ),
                                    if (!isCompact) ...[
                                      const SizedBox(width: 5),
                                      const Text(
                                        'AI Assistant',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Research Mode Toggle Button
                          Tooltip(
                            message: (_isResearchOpen &&
                                    _researchTab != ResearchTab.aiAssistant)
                                ? 'Hide Research Workspace'
                                : 'Research Workspace & Citations (Ctrl+Shift+R)',
                            child: InkWell(
                              onTap: () {
                                if (_isResearchOpen &&
                                    _researchTab != ResearchTab.aiAssistant) {
                                  setState(() => _isResearchOpen = false);
                                } else {
                                  setState(() {
                                    _isResearchOpen = true;
                                    _researchTab = ResearchTab.citations;
                                  });
                                }
                              },
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 7 : 9,
                                    vertical: 4.5),
                                decoration: BoxDecoration(
                                  color: (_isResearchOpen &&
                                          _researchTab !=
                                              ResearchTab.aiAssistant)
                                      ? colors.primary.withOpacity(0.14)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                  border: Border.all(
                                    color: (_isResearchOpen &&
                                            _researchTab !=
                                                ResearchTab.aiAssistant)
                                        ? colors.primary.withOpacity(0.4)
                                        : colors.border.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.science_rounded,
                                      size: 16,
                                      color: (_isResearchOpen &&
                                                  _researchTab !=
                                                      ResearchTab
                                                          .aiAssistant) ||
                                              isResearchActive
                                          ? colors.primary
                                          : colors.textSecondary,
                                    ),
                                    if (!isCompact) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        'Research',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: (_isResearchOpen &&
                                                  _researchTab !=
                                                      ResearchTab.aiAssistant)
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: (_isResearchOpen &&
                                                      _researchTab !=
                                                          ResearchTab
                                                              .aiAssistant) ||
                                                  isResearchActive
                                              ? colors.primary
                                              : colors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Favorite Button
                          IconButton(
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(6),
                            icon: Icon(
                              editorData.note.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                              color: editorData.note.isFavorite
                                  ? const Color(0xFFF59E0B)
                                  : colors.textTertiary,
                            ),
                            tooltip: editorData.note.isFavorite
                                ? 'Unfavorite'
                                : 'Add to favorites',
                            onPressed: () {
                              ref
                                  .read(noteEditorControllerProvider(
                                          widget.noteId)
                                      .notifier)
                                  .toggleFavorite();
                            },
                          ),

                          // Export Button
                          IconButton(
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(6),
                            icon: Icon(PhosphorIcons.export(),
                                size: 18, color: colors.textTertiary),
                            tooltip: 'Export Document (Markdown, HTML, TXT)',
                            onPressed: () => _handleOpenExport(editorData),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ── Trash Warning Banner ───────────────────────────────────
                if (editorData.note.isTrashed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: 7),
                    color: AppColors.error.withOpacity(0.12),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This note is currently in the Trash.',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(noteRepositoryProvider)
                                .restoreFromTrash(editorData.note.id);
                          },
                          icon: const Icon(Icons.restore_rounded, size: 14),
                          label: const Text('Restore Note'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            textStyle: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Main Content Area (Ribbon Toolbar + MS Docs Digital Canvas + Responsive Dock) ──
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, rootConstraints) {
                      final isNarrow = rootConstraints.maxWidth < 780;
                      final isMobile = rootConstraints.maxWidth < 600;

                      final editorWorkspace = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Full-Width Top Formatting Ribbon / Toolbar
                          Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border(
                                bottom: BorderSide(
                                  color: colors.border.withOpacity(0.4),
                                  width: 0.8,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: _EditorToolbar(
                              editorState: editorData.editorState,
                              note: editorData.note,
                              onInsertImage: () => _handlePickAndInsertImage(
                                  editorData.editorState),
                              onToggleResearch: () {
                                if (_isResearchOpen &&
                                    _researchTab != ResearchTab.aiAssistant) {
                                  setState(() => _isResearchOpen = false);
                                } else {
                                  setState(() {
                                    _isResearchOpen = true;
                                    _researchTab = ResearchTab.citations;
                                  });
                                }
                              },
                              onToggleAi: () {
                                if (_isResearchOpen &&
                                    _researchTab == ResearchTab.aiAssistant) {
                                  setState(() => _isResearchOpen = false);
                                } else {
                                  setState(() {
                                    _isResearchOpen = true;
                                    _researchTab = ResearchTab.aiAssistant;
                                  });
                                }
                              },
                              isResearchOpen: _isResearchOpen &&
                                  _researchTab != ResearchTab.aiAssistant,
                              isAiOpen: _isResearchOpen &&
                                  _researchTab == ResearchTab.aiAssistant,
                            ),
                          ),

                          // 2. Centered MS Docs Digital Paper Canvas (Generous margins & padding)
                          Expanded(
                            child: Container(
                              color: colors.background,
                              alignment: Alignment.topCenter,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8.0 : 20.0,
                                vertical: isMobile ? 8.0 : 16.0,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 860.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusLg),
                                      border: Border.all(
                                        color: colors.border.withOpacity(0.38),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      isMobile ? 18.0 : 52.0,
                                      isMobile ? 24.0 : 44.0, // More breathing room at the top
                                      isMobile ? 18.0 : 52.0,
                                      8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title TextField (Prominent 32px Bold)
                                        TextField(
                                          controller: _titleController,
                                          onChanged: (val) {
                                            ref
                                                .read(
                                                    noteEditorControllerProvider(
                                                            widget.noteId)
                                                        .notifier)
                                                .updateTitle(val);
                                          },
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge
                                              ?.copyWith(
                                                color: colors.textPrimary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: isMobile ? 24 : 32,
                                                letterSpacing: -0.5,
                                              ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                            fillColor: Colors.transparent,
                                            filled: false,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                            hintText: 'Untitled Document',
                                            hintStyle: TextStyle(
                                              fontSize: isMobile ? 24 : 32,
                                              fontWeight: FontWeight.w800,
                                              color: colors.textTertiary
                                                  .withOpacity(0.35),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          maxLines: 1,
                                          textInputAction: TextInputAction.next,
                                        ),

                                        const SizedBox(height: 14),

                                        // Interactive Neo-Glass Tag Pills Row
                                        Row(
                                          children: [
                                            Icon(
                                              PhosphorIcons.tag(
                                                  PhosphorIconsStyle.fill),
                                              size: 13,
                                              color: colors.textTertiary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                child: Row(
                                                  children: [
                                                    ...editorData.note.tags
                                                        .map((t) {
                                                      final tagColor = t
                                                                  .colorValue !=
                                                              null
                                                          ? Color(t.colorValue!)
                                                          : colors.primary;
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(right: 6),
                                                        child: NeoGlassBadge(
                                                          label: '#${t.name}',
                                                          color: tagColor,
                                                          onDelete: () {
                                                            ref
                                                                .read(noteEditorControllerProvider(
                                                                        widget
                                                                            .noteId)
                                                                    .notifier)
                                                                .removeTag(
                                                                    t.id);
                                                          },
                                                        ),
                                                      );
                                                    }),

                                                    // Add Tag Button
                                                    NeoGlassBadge(
                                                      label: '+ Tag',
                                                      color:
                                                          colors.textSecondary,
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (ctx) =>
                                                              AddTagDialog(
                                                            currentTags:
                                                                editorData
                                                                    .note.tags,
                                                            onTagSelected:
                                                                (tag) {
                                                              ref
                                                                  .read(noteEditorControllerProvider(
                                                                          widget
                                                                              .noteId)
                                                                      .notifier)
                                                                  .addTag(tag);
                                                            },
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 16),
                                        Divider(
                                            color:
                                                colors.border.withOpacity(0.3),
                                            height: 1),
                                        const SizedBox(height: 12),

                                        // AppFlowy Editor (Professional typography configured via Settings)
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final settings =
                                                  ref.watch(settingsProvider);
                                              final aiService =
                                                  ref.watch(aiWritingServiceProvider);
                                              final currentFontSize = isMobile
                                                  ? (settings.editorFontSize -
                                                      1.0)
                                                  : settings.editorFontSize;

                                              final customBuilders = Map<String, BlockComponentBuilder>.from(standardBlockComponentBuilderMap);
                                              customBuilders[ParagraphBlockKeys.type] = ParagraphBlockComponentBuilder(
                                                configuration: BlockComponentConfiguration(
                                                  // Split spacing symmetrically: half above + half below each block.
                                                  // Using only(bottom:) stacks the full gap between consecutive paragraphs,
                                                  // making Enter appear to create a double-sized gap.
                                                  padding: (node) => EdgeInsets.symmetric(
                                                    vertical: settings.paragraphSpacing / 2,
                                                  ),
                                                ),
                                              );
                                              customBuilders[TodoListBlockKeys.type] = TodoListBlockComponentBuilder(
                                                configuration: BlockComponentConfiguration(
                                                  padding: (node) => const EdgeInsets.symmetric(vertical: 0.0),
                                                ),
                                              );
                                              customBuilders[BulletedListBlockKeys.type] = BulletedListBlockComponentBuilder(
                                                configuration: BlockComponentConfiguration(
                                                  padding: (node) => const EdgeInsets.symmetric(vertical: 0.0),
                                                ),
                                              );
                                              customBuilders[NumberedListBlockKeys.type] = NumberedListBlockComponentBuilder(
                                                configuration: BlockComponentConfiguration(
                                                  padding: (node) => const EdgeInsets.symmetric(vertical: 0.0),
                                                ),
                                              );
                                              customBuilders[DividerBlockKeys.type] = DividerBlockComponentBuilder(
                                                configuration: BlockComponentConfiguration(
                                                  padding: (node) => const EdgeInsets.symmetric(vertical: 4.0),
                                                ),
                                              );

                                              return Listener(
                                                onPointerDown: (event) {
                                                  if (event.kind == PointerDeviceKind.mouse &&
                                                      event.buttons == kSecondaryMouseButton) {
                                                    final sel = editorData.editorState.selection;
                                                    if (sel != null && !sel.isCollapsed) {
                                                      final textList = editorData.editorState.getTextInSelection(sel);
                                                      final selectedText = textList.join('\n');
                                                      if (selectedText.trim().isNotEmpty) {
                                                        final fullDocText = editorData.editorState.document.root.children
                                                            .map((n) => n.delta?.toPlainText() ?? '')
                                                            .where((s) => s.trim().isNotEmpty)
                                                            .join('\n');
                                                        EditorContextMenu.show(
                                                          context: context,
                                                          position: event.position,
                                                          selectedText: selectedText,
                                                          fullDocText: fullDocText,
                                                          aiService: aiService,
                                                          editorState: editorData.editorState,
                                                        );
                                                      }
                                                    }
                                                  }
                                                },
                                                child: AppFlowyEditor(
                                                  editorState:
                                                      editorData.editorState,
                                                  contextMenuItems: const [],
                                                  editorStyle:
                                                      EditorStyle.desktop(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8, bottom: 48),
                                                    cursorColor: colors.primary,
                                                    selectionColor: colors.primary
                                                        .withOpacity(0.22),
                                                    textStyleConfiguration:
                                                        TextStyleConfiguration(
                                                      text: _getEditorTextStyle(
                                                        settings.editorFont,
                                                        currentFontSize,
                                                        colors.textPrimary,
                                                        height: settings.lineHeight,
                                                      ),
                                                      code: GoogleFonts
                                                          .jetBrainsMono(
                                                        fontSize:
                                                            currentFontSize - 2.5,
                                                        height: settings.lineHeight + 0.1,
                                                        color: colors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  blockComponentBuilders:
                                                      customBuilders,
                                                  commandShortcutEvents: [
                                                  CommandShortcutEvent(
                                                    key: 'smart markdown paste',
                                                    getDescription: () =>
                                                        'paste rich markdown content',
                                                    command: 'ctrl+v',
                                                    handler: (editorState) {
                                                      MarkdownPasteService
                                                              .handlePaste(
                                                                  editorState)
                                                          .then((handled) {
                                                        if (!handled) {
                                                          for (final event
                                                              in standardCommandShortcutEvents) {
                                                            if (event.key ==
                                                                'paste the content') {
                                                              event.handler(
                                                                  editorState);
                                                              break;
                                                            }
                                                          }
                                                        }
                                                      });
                                                      return KeyEventResult
                                                          .handled;
                                                    },
                                                  ),
                                                  CommandShortcutEvent(
                                                    key:
                                                        'smart markdown paste mac',
                                                    getDescription: () =>
                                                        'paste rich markdown content',
                                                    command: 'cmd+v',
                                                    handler: (editorState) {
                                                      MarkdownPasteService
                                                              .handlePaste(
                                                                  editorState)
                                                          .then((handled) {
                                                        if (!handled) {
                                                          for (final event
                                                              in standardCommandShortcutEvents) {
                                                            if (event.key ==
                                                                'paste the content') {
                                                              event.handler(
                                                                  editorState);
                                                              break;
                                                            }
                                                          }
                                                        }
                                                      });
                                                      return KeyEventResult
                                                          .handled;
                                                    },
                                                  ),
                                                  ...standardCommandShortcutEvents
                                                      .where((e) =>
                                                          e.key !=
                                                          'paste the content'),
                                                ],
                                                characterShortcutEvents:
                                                    standardCharacterShortcutEvents,
                                              ));
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Stack(
                          children: [
                            editorWorkspace,
                            if (_isResearchOpen) ...[
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _isResearchOpen = false),
                                  child: Container(
                                      color: Colors.black.withOpacity(0.35)),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                bottom: 0,
                                right: 0,
                                width: rootConstraints.maxWidth
                                    .clamp(320.0, 420.0),
                                child: Material(
                                  elevation: 16,
                                  child: ResearchSidebarPanel(
                                    key: ValueKey(_researchTab),
                                    note: editorData.note,
                                    editorState: editorData.editorState,
                                    initialTab: _researchTab,
                                    onClose: () =>
                                        setState(() => _isResearchOpen = false),
                                    onInsertImage: (path) => _insertImageNode(
                                        editorData.editorState, path),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: editorWorkspace),
                          if (_isResearchOpen)
                            ResearchSidebarPanel(
                              key: ValueKey(_researchTab),
                              note: editorData.note,
                              editorState: editorData.editorState,
                              initialTab: _researchTab,
                              onClose: () =>
                                  setState(() => _isResearchOpen = false),
                              onInsertImage: (path) => _insertImageNode(
                                  editorData.editorState, path),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, _) => Center(child: Text('Error loading note: $err')),
        ),
      ),
    );
  }
}

/// Floating Neo-Glass Modern Rich Text & AI Toolbar with Desktop & Mobile Horizontal Scroll
class _EditorToolbar extends ConsumerStatefulWidget {
  final EditorState editorState;
  final Note note;
  final VoidCallback? onInsertImage;
  final VoidCallback? onToggleResearch;
  final VoidCallback? onToggleAi;
  final bool isResearchOpen;
  final bool isAiOpen;

  const _EditorToolbar({
    required this.editorState,
    required this.note,
    this.onInsertImage,
    this.onToggleResearch,
    this.onToggleAi,
    this.isResearchOpen = false,
    this.isAiOpen = false,
  });

  @override
  ConsumerState<_EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends ConsumerState<_EditorToolbar> {
  late final ScrollController _scrollController;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_checkScrollability);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollability);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollability() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final canLeft = offset > 4;
    final canRight = offset < max - 4;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      if (mounted) {
        setState(() {
          _canScrollLeft = canLeft;
          _canScrollRight = canRight;
        });
      }
    }
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + offset)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _triggerShortcut(String pattern) {
    for (final event in standardCommandShortcutEvents) {
      if (event.key.toLowerCase().contains(pattern.toLowerCase())) {
        event.handler(widget.editorState);
        return;
      }
    }
  }

  void _insertNode(String type, {int? level, String text = ''}) {
    final doc = widget.editorState.document;
    final selection = widget.editorState.selection;
    final int targetIndex = (selection != null && selection.end.path.isNotEmpty)
        ? selection.end.path[0] + 1
        : doc.root.children.length;

    final transaction = widget.editorState.transaction;
    Node node;
    switch (type) {
      case 'heading':
        node = headingNode(level: level ?? 1, text: text);
        break;
      case 'bulleted_list':
        node = bulletedListNode(text: text);
        break;
      case 'numbered_list':
        node = numberedListNode();
        break;
      case 'todo_list':
        node = todoListNode(checked: false);
        break;
      case 'quote':
        node = quoteNode();
        break;
      case 'divider':
        node = dividerNode();
        break;
      case 'paragraph':
      default:
        node = paragraphNode(text: text);
        break;
    }
    transaction.insertNode([targetIndex], node);
    widget.editorState.apply(transaction);
  }

  void _triggerAiAction(BuildContext context, {String? defaultTask}) {
    final selection = widget.editorState.selection;
    String selectedText = '';
    if (selection != null) {
      selectedText =
          widget.editorState.getTextInSelection(selection).join('\n').trim();
    }

    final docText = widget.editorState.document.root.children
        .map((n) => n.delta?.toPlainText() ?? '')
        .where((s) => s.trim().isNotEmpty)
        .join('\n');

    final textToProcess = selectedText.isNotEmpty ? selectedText : docText;

    AiActionDialog.show(
      context,
      selectedText: textToProcess,
      fullDocumentContext: docText,
      initialTask: defaultTask,
      onApplyProposal: (replacement) {
        if (selectedText.isNotEmpty && selection != null) {
          widget.editorState.insertTextAtCurrentSelection(replacement);
        } else {
          final doc = widget.editorState.document;
          final length = doc.root.children.length;
          final transaction = widget.editorState.transaction;
          transaction.insertNode([length], paragraphNode(text: replacement));
          widget.editorState.apply(transaction);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final hasApiKey = ref.watch(aiWritingServiceProvider).hasApiKey;

    return NeoGlassContainer(
      blur: 16,
      borderRadius: AppSpacing.radiusMd,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notif) {
          _checkScrollability();
          return false;
        },
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent && _scrollController.hasClients) {
              final delta = event.scrollDelta.dy != 0
                  ? event.scrollDelta.dy
                  : event.scrollDelta.dx;
              _scrollController.jumpTo(
                (_scrollController.offset + delta)
                    .clamp(0.0, _scrollController.position.maxScrollExtent),
              );
            }
          },
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: LayoutBuilder(
              builder: (context, toolbarConstraints) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _checkScrollability());
                return Row(
                  children: [
                    if (_canScrollLeft)
                      _ToolbarArrowButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Scroll toolbar left',
                        onTap: () => _scrollBy(-160),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            // ── 1. Font Family Dropdown ──
                            Container(
                              height: 28,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: colors.surface2.withOpacity(0.6),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(
                                    color: colors.border.withOpacity(0.4)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: settings.editorFont,
                                  icon: Icon(Icons.arrow_drop_down_rounded,
                                      size: 16, color: colors.textSecondary),
                                  dropdownColor: colors.surface,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Inter', child: Text('Inter')),
                                    DropdownMenuItem(
                                        value: 'Outfit', child: Text('Outfit')),
                                    DropdownMenuItem(
                                        value: 'JetBrains Mono',
                                        child: Text('Mono')),
                                    DropdownMenuItem(
                                        value: 'Playfair Display',
                                        child: Text('Playfair')),
                                    DropdownMenuItem(
                                        value: 'Merriweather',
                                        child: Text('Serif')),
                                  ],
                                  onChanged: (newFont) {
                                    if (newFont != null) {
                                      settingsNotifier
                                          .updateEditorFont(newFont);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // ── 2. Font Size Stepper ──
                            Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: colors.surface2.withOpacity(0.6),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(
                                    color: colors.border.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: settings.editorFontSize > 12.0
                                        ? () => settingsNotifier
                                            .updateEditorFontSize(
                                                settings.editorFontSize - 1.0)
                                        : null,
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(
                                            AppSpacing.radiusSm)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 4),
                                      child: Icon(Icons.remove_rounded,
                                          size: 14,
                                          color: colors.textSecondary),
                                    ),
                                  ),
                                  Text(
                                    '${settings.editorFontSize.toInt()}',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary),
                                  ),
                                  InkWell(
                                    onTap: settings.editorFontSize < 28.0
                                        ? () => settingsNotifier
                                            .updateEditorFontSize(
                                                settings.editorFontSize + 1.0)
                                        : null,
                                    borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(
                                            AppSpacing.radiusSm)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 4),
                                      child: Icon(Icons.add_rounded,
                                          size: 14,
                                          color: colors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            _VerticalDivider(color: colors.border),

                            // ── 3. Text Formatting ──
                            _ToolbarItem(
                              icon:
                                  PhosphorIcons.textB(PhosphorIconsStyle.bold),
                              tooltip: 'Bold (Ctrl+B)',
                              onTap: () => _triggerShortcut('bold'),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.textItalic(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Italic (Ctrl+I)',
                              onTap: () => _triggerShortcut('italic'),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.textUnderline(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Underline (Ctrl+U)',
                              onTap: () => _triggerShortcut('underline'),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.textStrikethrough(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Strikethrough (Ctrl+Shift+S)',
                              onTap: () => _triggerShortcut('strikethrough'),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.code(PhosphorIconsStyle.bold),
                              tooltip: 'Code Block (Ctrl+E)',
                              onTap: () => _triggerShortcut('code'),
                            ),

                            _VerticalDivider(color: colors.border),

                            // ── 4. Line & Paragraph Spacing ──
                            _ParagraphSpacingToolbarItem(
                              currentSpacing: settings.paragraphSpacing,
                              onSpacingChanged: (val) =>
                                  settingsNotifier.updateParagraphSpacing(val),
                            ),

                            _VerticalDivider(color: colors.border),

                            // ── 5. Blocks & Lists ──
                            _ToolbarItem(
                              icon: PhosphorIcons.textHOne(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Heading 1 (#)',
                              onTap: () => _insertNode('heading', level: 1),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.textHTwo(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Heading 2 (##)',
                              onTap: () => _insertNode('heading', level: 2),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.listBullets(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Bulleted List (-)',
                              onTap: () => _insertNode('bulleted_list'),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.listNumbers(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Numbered List (1.)',
                              onTap: () => _insertNode('numbered_list'),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.checkSquare(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Checklist / Todo ([ ])',
                              onTap: () => _insertNode('todo_list'),
                            ),
                            _ToolbarItem(
                              icon:
                                  PhosphorIcons.quotes(PhosphorIconsStyle.bold),
                              tooltip: 'Quote Block (>)',
                              onTap: () => _insertNode('quote'),
                            ),
                            _ToolbarItem(
                              icon:
                                  PhosphorIcons.minus(PhosphorIconsStyle.bold),
                              tooltip: 'Divider Line (---)',
                              onTap: () => _insertNode('divider'),
                            ),

                            _VerticalDivider(color: colors.border),

                            // ── 5. ✨ AI Writing Assistant Menu ──
                            PopupMenuButton<String>(
                              tooltip: hasApiKey
                                  ? 'AI Writing Assistant (Google Gemini 2.0 Flash)'
                                  : 'AI Writing Assistant (Local Smart AI Engine)',
                              offset: const Offset(0, 36),
                              color: colors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                side: BorderSide(
                                    color: AppColors.accent.withOpacity(0.3)),
                              ),
                              onSelected: (val) {
                                if (val == 'dock') {
                                  widget.onToggleAi?.call();
                                } else if (val == 'research_dock') {
                                  widget.onToggleResearch?.call();
                                } else if (val == 'selection') {
                                  _triggerAiAction(context);
                                } else if (val == 'summarize') {
                                  _triggerAiAction(context,
                                      defaultTask: 'summarize');
                                } else if (val == 'action_items') {
                                  _triggerAiAction(context,
                                      defaultTask: 'action_items');
                                } else if (val == 'expand') {
                                  _triggerAiAction(context,
                                      defaultTask: 'expand');
                                } else if (val == 'flashcards') {
                                  _triggerAiAction(context,
                                      defaultTask: 'flashcards');
                                } else if (val == 'format_markdown') {
                                  final count = MarkdownPasteService
                                      .formatRawMarkdownInDocument(
                                          widget.editorState);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                              Icons.auto_fix_high_rounded,
                                              color: Colors.white,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(count > 0
                                                ? 'Successfully formatted $count markdown block(s) into rich text!'
                                                : 'Document is already clean!'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: count > 0
                                          ? AppColors.success
                                          : AppColors.accent,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  enabled: false,
                                  height: 32,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bolt_rounded,
                                          size: 14, color: AppColors.accent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          hasApiKey
                                              ? 'Gemini 2.0 Flash • Connected'
                                              : 'Local Smart AI • Offline',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent,
                                            letterSpacing: 0.3,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(height: 6),
                                const PopupMenuItem(
                                  value: 'format_markdown',
                                  child: Row(
                                    children: [
                                      Icon(Icons.auto_fix_high_rounded,
                                          size: 16, color: AppColors.accent),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Format Raw Markdown',
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'selection',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_note_rounded,
                                          size: 16, color: AppColors.accent),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Rewrite & Tone Actions...',
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'summarize',
                                  child: Row(
                                    children: [
                                      Icon(Icons.summarize_rounded,
                                          size: 16, color: AppColors.info),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Summarize Document',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'action_items',
                                  child: Row(
                                    children: [
                                      Icon(Icons.checklist_rtl_rounded,
                                          size: 16, color: AppColors.success),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Key Action Items',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'expand',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline_rounded,
                                          size: 16, color: Color(0xFFF59E0B)),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Brainstorm Expansion Ideas',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'flashcards',
                                  child: Row(
                                    children: [
                                      Icon(Icons.style_rounded,
                                          size: 16, color: Color(0xFF8B5CF6)),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Generate Study Flashcards',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'dock',
                                  child: Row(
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          size: 16, color: AppColors.accent),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Open AI Chat Dock',
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.accent),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.accent.withOpacity(0.18),
                                      AppColors.accent.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                  border: Border.all(
                                      color: AppColors.accent.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.auto_awesome_rounded,
                                        size: 14, color: AppColors.accent),
                                    SizedBox(width: 4),
                                    Text(
                                      'AI Write',
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent),
                                    ),
                                    Icon(Icons.arrow_drop_down_rounded,
                                        size: 16, color: AppColors.accent),
                                  ],
                                ),
                              ),
                            ),

                            _VerticalDivider(color: colors.border),

                            // ── 6. Paste / Undo / Redo / Image / AI / Research ──
                            _ToolbarItem(
                              icon: PhosphorIcons.clipboardText(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Smart Paste Markdown (Ctrl+V)',
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final handled =
                                    await MarkdownPasteService.handlePaste(
                                        widget.editorState);
                                if (mounted && handled) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Pasted and formatted markdown cleanly!'),
                                      backgroundColor: AppColors.success,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.arrowUUpLeft(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Undo (Ctrl+Z)',
                              onTap: () => _triggerShortcut('undo'),
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.arrowUUpRight(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'Redo (Ctrl+Y)',
                              onTap: () => _triggerShortcut('redo'),
                            ),
                            _ToolbarItem(
                              icon:
                                  PhosphorIcons.image(PhosphorIconsStyle.bold),
                              tooltip: 'Insert Image',
                              onTap: widget.onInsertImage ?? () {},
                            ),
                            _ToolbarItem(
                              icon: PhosphorIcons.sparkle(
                                  PhosphorIconsStyle.bold),
                              tooltip: 'AI Assistant Dock (Ctrl+Shift+A)',
                              isActive: widget.isAiOpen,
                              onTap: widget.onToggleAi ?? () {},
                            ),
                            _ToolbarItem(
                              icon:
                                  PhosphorIcons.books(PhosphorIconsStyle.bold),
                              tooltip:
                                  'Research & Citations Dock (Ctrl+Shift+R)',
                              isActive: widget.isResearchOpen,
                              onTap: widget.onToggleResearch ?? () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_canScrollRight)
                      _ToolbarArrowButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Scroll toolbar right',
                        onTap: () => _scrollBy(160),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: 26,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border:
                Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Icon(icon, size: 17, color: AppColors.accent),
        ),
      ),
    );
  }
}

class _ToolbarItem extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolbarItem({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary.withOpacity(0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final Color color;
  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: color.withOpacity(0.3),
    );
  }
}

/// Compact neo-glass toolbar widget for line/paragraph spacing with stepper & modal launcher
class _ParagraphSpacingToolbarItem extends StatelessWidget {
  final double currentSpacing;
  final ValueChanged<double> onSpacingChanged;

  const _ParagraphSpacingToolbarItem({
    required this.currentSpacing,
    required this.onSpacingChanged,
  });

  void _openSpacingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ParagraphSpacingDialog(
        initialSpacing: currentSpacing,
        onApply: onSpacingChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: colors.surface2.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.border.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with tooltip
          Tooltip(
            message: 'Paragraph Spacing (Click for options)',
            child: InkWell(
              onTap: () => _openSpacingDialog(context),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppSpacing.radiusSm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Icon(
                  Icons.format_line_spacing_rounded,
                  size: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),

          // Stepper: Decrement (-)
          Tooltip(
            message: 'Decrease Spacing (-1 pt)',
            child: InkWell(
              onTap: currentSpacing > 0.0
                  ? () => onSpacingChanged((currentSpacing - 1.0).clamp(0.0, 24.0))
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(
                  Icons.remove_rounded,
                  size: 13,
                  color: currentSpacing > 0.0
                      ? colors.textSecondary
                      : colors.textTertiary.withOpacity(0.35),
                ),
              ),
            ),
          ),

          // Current Spacing Label (Clickable to open dialog/manual entry)
          Tooltip(
            message: 'Current spacing: ${currentSpacing % 1 == 0 ? currentSpacing.toInt() : currentSpacing.toStringAsFixed(1)} pt (Click to change)',
            child: InkWell(
              onTap: () => _openSpacingDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  '${currentSpacing % 1 == 0 ? currentSpacing.toInt() : currentSpacing.toStringAsFixed(1)} pt',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),

          // Stepper: Increment (+)
          Tooltip(
            message: 'Increase Spacing (+1 pt)',
            child: InkWell(
              onTap: currentSpacing < 24.0
                  ? () => onSpacingChanged((currentSpacing + 1.0).clamp(0.0, 24.0))
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(
                  Icons.add_rounded,
                  size: 13,
                  color: currentSpacing < 24.0
                      ? colors.textSecondary
                      : colors.textTertiary.withOpacity(0.35),
                ),
              ),
            ),
          ),

          // Dropdown Arrow (Click for presets & manual input)
          Tooltip(
            message: 'Spacing Presets & Manual Input',
            child: InkWell(
              onTap: () => _openSpacingDialog(context),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppSpacing.radiusSm),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 1, right: 4, top: 4, bottom: 4),
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for quick presets and manual numerical input for paragraph spacing
class _ParagraphSpacingDialog extends StatefulWidget {
  final double initialSpacing;
  final ValueChanged<double> onApply;

  const _ParagraphSpacingDialog({
    required this.initialSpacing,
    required this.onApply,
  });

  @override
  State<_ParagraphSpacingDialog> createState() => _ParagraphSpacingDialogState();
}

class _ParagraphSpacingDialogState extends State<_ParagraphSpacingDialog> {
  late final TextEditingController _controller;
  late double _selectedSpacing;

  static const List<double> _presetOptions = [
    0.0, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpacing = widget.initialSpacing;
    _controller = TextEditingController(
      text: _formatValue(widget.initialSpacing),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double val) {
    return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
  }

  void _applyAndClose(double val) {
    final clamped = val.clamp(0.0, 24.0);
    widget.onApply(clamped);
    if (mounted) Navigator.of(context).pop();
  }

  void _submitFromText() {
    final val = double.tryParse(_controller.text.trim());
    if (val != null) {
      _applyAndClose(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: colors.border.withOpacity(0.5)),
      ),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.format_line_spacing_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paragraph Spacing',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                      ),
                      Text(
                        'Vertical space between blocks (Default: 1 pt)',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick Presets
            Text(
              'Quick Presets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presetOptions.map((val) {
                final isSelected = (_selectedSpacing == val);
                String label;
                if (val == 0.0) {
                  label = '0 pt (None)';
                } else if (val == 1.0) {
                  label = '1 pt (Default)';
                } else if (val == 2.0) {
                  label = '2 pt (Tight)';
                } else if (val == 4.0) {
                  label = '4 pt';
                } else if (val == 6.0) {
                  label = '6 pt (Relaxed)';
                } else {
                  label = '${val.toInt()} pt';
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSpacing = val;
                      _controller.text = _formatValue(val);
                    });
                    _applyAndClose(val);
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.18)
                          : colors.surface2.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : colors.border.withOpacity(0.4),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.accent : colors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Manual Input Section
            Text(
              'Manual Input (Custom pt)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Quick Decrement
                IconButton(
                  onPressed: () {
                    final curr = double.tryParse(_controller.text.trim()) ?? _selectedSpacing;
                    final next = (curr - 1.0).clamp(0.0, 24.0);
                    setState(() {
                      _selectedSpacing = next;
                      _controller.text = _formatValue(next);
                    });
                  },
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: colors.textSecondary,
                ),
                // Text Field
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.surface2.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: colors.border.withOpacity(0.5)),
                    ),
                    child: TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                        border: InputBorder.none,
                        suffixText: 'pt',
                        suffixStyle: TextStyle(
                          fontSize: 11,
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onSubmitted: (_) => _submitFromText(),
                    ),
                  ),
                ),
                // Quick Increment
                IconButton(
                  onPressed: () {
                    final curr = double.tryParse(_controller.text.trim()) ?? _selectedSpacing;
                    final next = (curr + 1.0).clamp(0.0, 24.0);
                    setState(() {
                      _selectedSpacing = next;
                      _controller.text = _formatValue(next);
                    });
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                // Apply Button
                ElevatedButton(
                  onPressed: _submitFromText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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

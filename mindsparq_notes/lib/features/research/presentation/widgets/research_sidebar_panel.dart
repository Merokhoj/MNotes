import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/note.dart';
import '../../../media/data/services/attachment_storage_service.dart';
import '../../../media/domain/models/note_attachment.dart';
import '../../../media/presentation/dialogs/attach_file_dialog.dart';
import '../../../export/presentation/dialogs/export_dialog.dart';
import '../../../export/services/document_export_service.dart';
import '../../data/services/research_storage_service.dart';
import '../../domain/models/research_metadata.dart';
import '../../../ai/presentation/widgets/ai_assistant_tab.dart';
import '../../../notes/presentation/services/markdown_paste_service.dart';

enum ResearchTab {
  aiAssistant('✨ AI'),
  citations('Citations'),
  attachments('Files'),
  outline('Outline'),
  export('Export');

  final String label;
  const ResearchTab(this.label);
}

class ResearchSidebarPanel extends ConsumerStatefulWidget {
  final Note note;
  final EditorState editorState;
  final VoidCallback onClose;
  final Function(String imagePath)? onInsertImage;
  final ResearchTab initialTab;

  const ResearchSidebarPanel({
    super.key,
    required this.note,
    required this.editorState,
    required this.onClose,
    this.onInsertImage,
    this.initialTab = ResearchTab.aiAssistant,
  });

  @override
  ConsumerState<ResearchSidebarPanel> createState() => _ResearchSidebarPanelState();
}

class _ResearchSidebarPanelState extends ConsumerState<ResearchSidebarPanel> {
  late ResearchTab _currentTab;
  CitationFormat _citationFormat = CitationFormat.apa7;

  // Controllers for research metadata
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorsCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _journalCtrl;
  late final TextEditingController _volPagesCtrl;
  late final TextEditingController _doiCtrl;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _titleCtrl = TextEditingController();
    _authorsCtrl = TextEditingController();
    _yearCtrl = TextEditingController();
    _journalCtrl = TextEditingController();
    _volPagesCtrl = TextEditingController();
    _doiCtrl = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant ResearchSidebarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _currentTab = widget.initialTab;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorsCtrl.dispose();
    _yearCtrl.dispose();
    _journalCtrl.dispose();
    _volPagesCtrl.dispose();
    _doiCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(ResearchMetadata meta) {
    if (_titleCtrl.text != meta.sourceTitle) _titleCtrl.text = meta.sourceTitle;
    if (_authorsCtrl.text != meta.authors) _authorsCtrl.text = meta.authors;
    if (_yearCtrl.text != meta.publicationYear) _yearCtrl.text = meta.publicationYear;
    if (_journalCtrl.text != meta.journalOrPublisher) _journalCtrl.text = meta.journalOrPublisher;
    if (_volPagesCtrl.text != meta.volumeAndPages) _volPagesCtrl.text = meta.volumeAndPages;
    if (_doiCtrl.text != meta.doiOrUrl) _doiCtrl.text = meta.doiOrUrl;
  }

  void _saveMetadataChanges(ResearchMetadata current) {
    final updated = current.copyWith(
      sourceTitle: _titleCtrl.text.trim(),
      authors: _authorsCtrl.text.trim(),
      publicationYear: _yearCtrl.text.trim(),
      journalOrPublisher: _journalCtrl.text.trim(),
      volumeAndPages: _volPagesCtrl.text.trim(),
      doiOrUrl: _doiCtrl.text.trim(),
    );
    ref.read(researchMetadataStateProvider(widget.note.id).notifier).updateMetadata(updated);
  }

  void _insertBibliographyToNote(ResearchMetadata meta) {
    final formatted = meta.format(_citationFormat);
    final doc = widget.editorState.document;
    final length = doc.root.children.length;

    // Insert H2 "References" and citation paragraph
    final transaction = widget.editorState.transaction;
    
    // Check if references heading already exists
    bool hasReferencesHeader = false;
    for (final child in doc.root.children) {
      if (child.type == 'heading' && child.delta?.toPlainText().toLowerCase().contains('reference') == true) {
        hasReferencesHeader = true;
        break;
      }
    }

    if (!hasReferencesHeader) {
      transaction.insertNode(
        [length],
        headingNode(
          level: 2,
          text: 'References',
        ),
      );
      transaction.insertNode(
        [length + 1],
        paragraphNode(
          text: formatted,
        ),
      );
    } else {
      transaction.insertNode(
        [length],
        paragraphNode(
          text: formatted,
        ),
      );
    }

    widget.editorState.apply(transaction);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bibliography reference inserted into document!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final metaAsync = ref.watch(researchMetadataStateProvider(widget.note.id));

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(left: BorderSide(color: colors.border.withOpacity(0.5))),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface2,
              border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.4))),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Research Workspace',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                  tooltip: 'Close Research Panel',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.3))),
            ),
            child: Row(
              children: ResearchTab.values.map((tab) {
                final isSelected = _currentTab == tab;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentTab = tab),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? colors.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.accent : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Tab Body
          Expanded(
            child: _currentTab == ResearchTab.aiAssistant
                ? AiAssistantTab(
                    note: widget.note,
                    editorState: widget.editorState,
                    onReplaceSelection: (newText) {
                      MarkdownPasteService.insertMarkdown(
                        widget.editorState,
                        newText,
                        replaceSelection: true,
                      );
                    },
                    onInsertBelow: (newText) {
                      MarkdownPasteService.insertMarkdown(
                        widget.editorState,
                        newText,
                        replaceSelection: false,
                      );
                    },
                  )
                : metaAsync.when(
                    data: (meta) {
                      _syncControllers(meta);
                      switch (_currentTab) {
                        case ResearchTab.aiAssistant:
                          return const SizedBox.shrink();
                        case ResearchTab.citations:
                          return _buildCitationsTab(colors, meta);
                        case ResearchTab.attachments:
                          return _buildAttachmentsTab(colors);
                        case ResearchTab.outline:
                          return _buildOutlineTab(colors);
                        case ResearchTab.export:
                          return _buildExportTab(colors, meta);
                      }
                    },
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(fontSize: 11))),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Citations ───────────────────────────────────────────────────────

  Widget _buildCitationsTab(AppColorScheme colors, ResearchMetadata meta) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Live Citation Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: colors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GENERATED CITATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  DropdownButton<CitationFormat>(
                    value: _citationFormat,
                    underline: const SizedBox(),
                    isDense: true,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
                    icon: const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.accent),
                    items: CitationFormat.values.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _citationFormat = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                meta.hasCitationData
                    ? meta.format(_citationFormat)
                    : 'Fill in the metadata below to generate a formal citation.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  fontStyle: meta.hasCitationData ? FontStyle.normal : FontStyle.italic,
                  color: meta.hasCitationData ? colors.textPrimary : colors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: meta.generateInTextCitation()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('In-text citation copied: ${meta.generateInTextCitation()}'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 12),
                      label: const Text('In-Text', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        side: BorderSide(color: colors.border),
                        foregroundColor: colors.textPrimary,
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: meta.format(_citationFormat)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Full citation copied!'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 12),
                      label: const Text('Copy', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _insertBibliographyToNote(meta),
                  icon: const Icon(Icons.post_add_rounded, size: 14),
                  label: const Text('Insert to References in Note', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        Text(
          'RESEARCH METADATA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        _buildTextField('Source / Paper Title', _titleCtrl, colors, meta, 'e.g. Computing Machinery and Intelligence'),
        _buildTextField('Authors (separated by comma)', _authorsCtrl, colors, meta, 'e.g. Alan Turing, John von Neumann'),
        Row(
          children: [
            Expanded(child: _buildTextField('Year', _yearCtrl, colors, meta, '1950')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildTextField('Vol & Pages', _volPagesCtrl, colors, meta, '59(236), 433-460')),
          ],
        ),
        _buildTextField('Journal / Publisher', _journalCtrl, colors, meta, 'e.g. Mind, Oxford Univ Press'),
        _buildTextField('DOI or URL', _doiCtrl, colors, meta, 'e.g. 10.1093/mind/LIX.236.433'),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    AppColorScheme colors,
    ResearchMetadata meta,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary)),
          const SizedBox(height: 3),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.border.withOpacity(0.5)),
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) => _saveMetadataChanges(meta),
              style: TextStyle(fontSize: 12, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 11, color: colors.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(left: 8, bottom: 15),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Attachments ─────────────────────────────────────────────────────

  Widget _buildAttachmentsTab(AppColorScheme colors) {
    final attachmentsAsync = ref.watch(noteAttachmentsProvider(widget.note.id));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NOTE ATTACHMENTS',
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
                  builder: (ctx) => AttachFileDialog(noteId: widget.note.id),
                ),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: AppColors.accent),
                      SizedBox(width: 2),
                      Text('Attach', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Expanded(
            child: attachmentsAsync.when(
              data: (attachments) {
                if (attachments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.attachment_rounded, size: 36, color: colors.textTertiary.withOpacity(0.5)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('No attachments yet', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Attach images, research papers (PDF), or documents.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final att = attachments[i];
                    final isImage = att.fileType == AttachmentType.image;
                    final isPdf = att.fileType == AttachmentType.pdf;

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: colors.border.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isImage
                                ? Icons.image_rounded
                                : (isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded),
                            color: isImage
                                ? Colors.teal
                                : (isPdf ? Colors.redAccent : AppColors.accent),
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  att.fileName,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  att.formattedSize,
                                  style: TextStyle(fontSize: 10, color: colors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                          if (isImage && widget.onInsertImage != null)
                            IconButton(
                              icon: const Icon(Icons.add_photo_alternate_outlined, size: 15),
                              tooltip: 'Insert into text',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              onPressed: () => widget.onInsertImage!(att.filePath),
                            ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, size: 15),
                            tooltip: 'Open with default app',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            onPressed: () => ref.read(attachmentServiceProvider).openAttachment(att.filePath),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                            tooltip: 'Delete attachment',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            onPressed: () async {
                              await ref.read(attachmentServiceProvider).deleteAttachment(widget.note.id, att.id);
                              ref.invalidate(noteAttachmentsProvider(widget.note.id));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, _) => Center(child: Text('Error loading attachments: $err')),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Document Outline (TOC) ──────────────────────────────────────────

  Widget _buildOutlineTab(AppColorScheme colors) {
    final headings = <Map<String, dynamic>>[];
    for (final node in widget.editorState.document.root.children) {
      if (node.type == 'heading') {
        final level = node.attributes['level'] ?? 1;
        final text = node.delta?.toPlainText().trim() ?? '';
        if (text.isNotEmpty) {
          headings.add({'level': level, 'text': text});
        }
      }
    }

    if (headings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_list_bulleted_rounded, size: 36, color: colors.textTertiary.withOpacity(0.5)),
              const SizedBox(height: AppSpacing.sm),
              Text('No headings yet', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              const SizedBox(height: 4),
              Text('Type # followed by space to create headings in your note.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: colors.textTertiary)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: headings.length,
      itemBuilder: (context, i) {
        final item = headings[i];
        final level = item['level'] as int;
        final text = item['text'] as String;

        return Padding(
          padding: EdgeInsets.only(
            left: (level - 1) * 12.0,
            bottom: 6,
          ),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'H$level',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: level == 1 ? FontWeight.w600 : FontWeight.w400,
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
        );
      },
    );
  }

  // ── Tab 4: Quick Export ────────────────────────────────────────────────────

  Widget _buildExportTab(AppColorScheme colors, ResearchMetadata meta) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'ONE-CLICK EXPORT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _buildExportButton(
          title: 'Export as Markdown (.md)',
          subtitle: 'Includes YAML metadata & citations',
          icon: PhosphorIcons.markdownLogo(),
          colors: colors,
          onTap: () async {
            final file = await DocumentExportService.exportToMarkdownFile(
              widget.note,
              widget.editorState,
              researchMetadata: meta,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported to ${file.path}'),
                  backgroundColor: AppColors.success,
                  action: SnackBarAction(
                    label: 'Open',
                    textColor: Colors.white,
                    onPressed: () {
                      if (Platform.isWindows) {
                        Process.run('explorer.exe', ['/select,', file.path]);
                      }
                    },
                  ),
                ),
              );
            }
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        _buildExportButton(
          title: 'Export as Web Page (.html)',
          subtitle: 'Standalone styled document with print CSS',
          icon: PhosphorIcons.browsers(),
          colors: colors,
          onTap: () async {
            final file = await DocumentExportService.exportToHtmlFile(
              widget.note,
              widget.editorState,
              researchMetadata: meta,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported to ${file.path}'),
                  backgroundColor: AppColors.success,
                  action: SnackBarAction(
                    label: 'Open',
                    textColor: Colors.white,
                    onPressed: () {
                      if (Platform.isWindows) {
                        Process.run('cmd', ['/c', 'start', '', file.path]);
                      }
                    },
                  ),
                ),
              );
            }
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        _buildExportButton(
          title: 'Export as Plain Text (.txt)',
          subtitle: 'Raw text without formatting',
          icon: PhosphorIcons.fileText(),
          colors: colors,
          onTap: () async {
            final file = await DocumentExportService.exportToPlainTextFile(
              widget.note,
              widget.editorState,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported to ${file.path}'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => ExportDialog(note: widget.note, editorState: widget.editorState),
          ),
          icon: const Icon(Icons.tune_rounded, size: 16),
          label: const Text('Advanced Export Settings...'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.border),
            foregroundColor: colors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required AppColorScheme colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: colors.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 10.5, color: colors.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

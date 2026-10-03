import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/note.dart';
import '../../data/services/ai_writing_service.dart';
import '../../domain/models/ai_message.dart';
import '../../../notes/presentation/services/markdown_paste_service.dart';

const _uuid = Uuid();

class AiAssistantTab extends ConsumerStatefulWidget {
  final Note note;
  final EditorState editorState;
  final Function(String text)? onReplaceSelection;
  final Function(String text)? onInsertBelow;

  const AiAssistantTab({
    super.key,
    required this.note,
    required this.editorState,
    this.onReplaceSelection,
    this.onInsertBelow,
  });

  @override
  ConsumerState<AiAssistantTab> createState() => _AiAssistantTabState();
}

class _AiAssistantTabState extends ConsumerState<AiAssistantTab> {
  final List<AiMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isProcessing = false;
  String _selectedContext = '';

  @override
  void initState() {
    super.initState();
    _selectedContext = _getSelectedText();
    widget.editorState.selectionNotifier.addListener(_onSelectionChanged);
    // Welcome message
    _messages.add(
      AiMessage(
        id: _uuid.v4(),
        isUser: false,
        text: 'Hello! I am your MindSparQ AI Writing & Research Assistant. You can ask me to rewrite, summarize, explain concepts, generate study flashcards, or draft content based on your note.',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    widget.editorState.selectionNotifier.removeListener(_onSelectionChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    final text = _getSelectedText();
    if (text.isNotEmpty && text != _selectedContext && mounted) {
      setState(() {
        _selectedContext = text;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getDocumentContext() {
    final buffer = StringBuffer();
    if (widget.note.title.isNotEmpty) buffer.writeln('Title: ${widget.note.title}');
    final doc = widget.editorState.document;
    for (final node in doc.root.children) {
      final delta = node.delta;
      if (delta != null) {
        final text = delta.toPlainText().trim();
        if (text.isNotEmpty) buffer.writeln(text);
      }
    }
    return buffer.toString().trim();
  }

  String _getSelectedText() {
    final sel = widget.editorState.selection;
    if (sel == null || sel.isCollapsed) return '';
    try {
      return widget.editorState.getTextInSelection(sel).join('\n').trim();
    } catch (_) {
      return '';
    }
  }

  void _handleSend([String? presetPrompt]) async {
    final query = presetPrompt ?? _inputCtrl.text.trim();
    if (query.isEmpty) return;

    if (presetPrompt == null) _inputCtrl.clear();

    final userMsg = AiMessage(
      id: _uuid.v4(),
      isUser: true,
      text: query,
      timestamp: DateTime.now(),
    );

    final loadingMsg = AiMessage(
      id: _uuid.v4(),
      isUser: false,
      text: 'Thinking...',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isProcessing = true;
    });
    _scrollToBottom();

    final service = ref.read(aiWritingServiceProvider);
    final docContext = _getDocumentContext();
    final activeContext = _selectedContext.isNotEmpty ? _selectedContext : _getSelectedText();

    final responseText = await service.executeTask(
      task: 'chat',
      text: query,
      documentContext: activeContext.isNotEmpty
          ? 'USER HIGHLIGHTED NOTE EXCERPT:\n"""\n$activeContext\n"""\n\nFULL NOTE CONTEXT:\n$docContext'
          : docContext,
    );

    if (mounted) {
      setState(() {
        _messages.removeWhere((m) => m.id == loadingMsg.id);
        _messages.add(
          AiMessage(
            id: _uuid.v4(),
            isUser: false,
            text: responseText,
            timestamp: DateTime.now(),
            proposedReplacement: responseText,
          ),
        );
        _isProcessing = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final aiService = ref.watch(aiWritingServiceProvider);
    final hasApiKey = aiService.hasApiKey;

    return Column(
      children: [
        // ── Active Engine & Model Badge Bar (Side Dock) ───────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surface2.withOpacity(0.6),
            border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.35))),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: hasApiKey ? AppColors.success : AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (hasApiKey ? AppColors.success : AppColors.accent).withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                hasApiKey ? 'Gemini 2.0 Flash' : 'Local Smart AI',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: (hasApiKey ? AppColors.success : AppColors.accent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (hasApiKey ? AppColors.success : AppColors.accent).withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  hasApiKey ? 'LATEST • FAST' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: hasApiKey ? AppColors.success : AppColors.accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                hasApiKey ? 'Cloud GenAI' : 'Deterministic',
                style: TextStyle(fontSize: 10, color: colors.textTertiary),
              ),
            ],
          ),
        ),

        // ── Active Highlighted Selection Context Banner ───────────
        if (_selectedContext.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              border: Border(bottom: BorderSide(color: AppColors.accent.withOpacity(0.25))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Referencing Highlighted Text (${_selectedContext.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _selectedContext = ''),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.close_rounded, size: 14, color: colors.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedContext.length > 95
                      ? '${_selectedContext.substring(0, 95)}...'
                      : _selectedContext,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

        // ── Quick Prompt Suggestions ─────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
          color: colors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _selectedContext.isNotEmpty
                  ? [
                      _buildPromptChip('✨ Polish Selection',
                          () => _handleSend('Improve and polish the following excerpt, enhancing clarity and flow:\n\n"$_selectedContext"')),
                      _buildPromptChip('📝 Summarize Selection',
                          () => _handleSend('Summarize the key points of the selected excerpt:\n\n"$_selectedContext"')),
                      _buildPromptChip('🔍 Explain Concepts',
                          () => _handleSend('Explain the key concepts and terms in this selected excerpt:\n\n"$_selectedContext"')),
                      _buildPromptChip('⚡ Action Items',
                          () => _handleSend('Extract actionable checklist items from this selected excerpt:\n\n"$_selectedContext"')),
                    ]
                  : [
                      _buildPromptChip('Summarize note',
                          () => _handleSend('Summarize this note in 3 crisp bullet points.')),
                      _buildPromptChip('Extract Action Items',
                          () => _handleSend('Extract all action items into a checklist.')),
                      _buildPromptChip('Explain Key Terms',
                          () => _handleSend('Explain the key terms and concepts in this note.')),
                      _buildPromptChip('Make Academic',
                          () => _handleSend('Rewrite the key findings in formal academic tone.')),
                      _buildPromptChip('Generate Flashcards',
                          () => _handleSend('Create revision flashcards from this note.')),
                    ],
            ),
          ),
        ),
        Divider(height: 1, color: colors.border.withOpacity(0.3)),

        // ── Message History ──────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final msg = _messages[i];
              return _buildMessageBubble(msg, colors);
            },
          ),
        ),

        // ── Bottom Input Row ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border.withOpacity(0.4))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: colors.border.withOpacity(0.5)),
                  ),
                  child: TextField(
                    controller: _inputCtrl,
                    style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask AI anything about this note...',
                      hintStyle: TextStyle(fontSize: 12, color: colors.textTertiary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              InkWell(
                onTap: _isProcessing ? null : () => _handleSend(),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isProcessing ? colors.surface2 : colors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    _isProcessing ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChip(String label, VoidCallback onTap) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: colors.border.withOpacity(0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.sparkle(), size: 11, color: colors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage msg, AppColorScheme colors) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 28),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(12).copyWith(bottomRight: Radius.zero),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.4),
          ),
        ),
      );
    }

    // Assistant Card (Notelify inspired)
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12).copyWith(topLeft: Radius.zero),
          border: Border.all(color: colors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), size: 14, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  'MindSparQ AI',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.primary),
                ),
                const Spacer(),
                if (!msg.isLoading)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied response!'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.copy_rounded, size: 14, color: colors.textTertiary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (msg.isLoading)
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text('Thinking...', style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                ],
              )
            else
              SelectableText(
                msg.text,
                style: TextStyle(fontSize: 12.5, height: 1.45, color: colors.textPrimary),
                contextMenuBuilder: (context, editableTextState) {
                  final textSelection = editableTextState.textEditingValue.selection;
                  final selectedText = textSelection.textInside(editableTextState.textEditingValue.text);
                  final buttonItems = editableTextState.contextMenuButtonItems;
                  if (selectedText.trim().isNotEmpty) {
                    buttonItems.insert(
                      0,
                      ContextMenuButtonItem(
                        label: '📌 Insert Selection to Note',
                        onPressed: () {
                          ContextMenuController.removeAny();
                          MarkdownPasteService.insertMarkdown(widget.editorState, selectedText);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selected text inserted into note with rich formatting!'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: buttonItems,
                  );
                },
              ),

            // Action Buttons on Card
            if (!msg.isLoading && msg.proposedReplacement != null) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: colors.border.withOpacity(0.3)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (widget.onReplaceSelection != null) {
                        widget.onReplaceSelection!(msg.proposedReplacement!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Replaced selection in document with rich formatting!'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.find_replace_rounded, size: 13),
                    label: const Text('Replace Selection'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary.withOpacity(0.6)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      minimumSize: Size.zero,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (widget.onInsertBelow != null) {
                        widget.onInsertBelow!(msg.proposedReplacement!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Inserted into document with rich formatting!'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.post_add_rounded, size: 13),
                    label: const Text('Insert to Note'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

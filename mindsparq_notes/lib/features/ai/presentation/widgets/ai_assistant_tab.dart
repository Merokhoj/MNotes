import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/providers/settings_provider.dart';
import '../../../../domain/models/note.dart';
import '../../data/services/ai_writing_service.dart';
import '../../data/services/voice_to_text_service.dart';
import '../../domain/models/ai_message.dart';
import '../../../notes/presentation/services/markdown_paste_service.dart';
import '../../../media/data/services/attachment_storage_service.dart';

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

  // Attachments and Voice Input State
  String? _attachedFilePath;
  String? _attachedFileName;
  bool _isListeningVoice = false;

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
        text: 'Hello! I am your MindSparQ AI Writing & Research Assistant. You can ask questions, attach images or documents, dictate with voice, or synthesize content based on your note.',
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

  void _pickAttachment({bool imagesOnly = false}) async {
    final service = ref.read(attachmentServiceProvider);
    final path = await service.pickNativeFilePath(imagesOnly: imagesOnly);
    if (path != null && mounted) {
      setState(() {
        _attachedFilePath = path;
        _attachedFileName = p.basename(path);
      });
    }
  }

  void _toggleVoiceDictation() async {
    final voiceService = ref.read(voiceToTextServiceProvider);
    if (_isListeningVoice) {
      voiceService.stopListening();
      setState(() => _isListeningVoice = false);
      return;
    }

    setState(() => _isListeningVoice = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listening... speak now or press Windows + H for instant dictation'),
        duration: Duration(seconds: 3),
      ),
    );

    final text = await voiceService.listenOnce();

    if (mounted) {
      setState(() => _isListeningVoice = false);
      if (text != null && text.trim().isNotEmpty) {
        if (_inputCtrl.text.trim().isEmpty) {
          _inputCtrl.text = text.trim();
        } else {
          _inputCtrl.text = '${_inputCtrl.text.trim()} ${text.trim()}';
        }
        _inputCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _inputCtrl.text.length));
      }
    }
  }

  void _openApiKeyDialog() {
    final currentKey = ref.read(settingsProvider).geminiApiKey;
    final ctrl = TextEditingController(text: currentKey);
    bool isSaving = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final colors = ctx.appColors;
          return AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.key_rounded, color: AppColors.accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Google Gemini API Key',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your free Google Gemini API Key to enable live cloud AI, multimodal document & image synthesis, and deep research.',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    labelText: 'Gemini API Key',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    border: const OutlineInputBorder(),
                    errorText: error,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get your key free at: aistudio.google.com/apikey',
                  style: TextStyle(fontSize: 11, color: colors.textTertiary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colors.primary),
                onPressed: isSaving ? null : () async {
                  final key = ctrl.text.trim();
                  setDlgState(() { isSaving = true; error = null; });
                  final res = await AiWritingService.validateApiKey(key);
                  if (res.isValid) {
                    await ref.read(settingsProvider.notifier).updateGeminiApiKey(key);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Connected to ${res.activeModel}! Live GenAI is now active.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } else {
                    setDlgState(() {
                      isSaving = false;
                      error = res.message;
                    });
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Connect & Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSend([String? presetPrompt]) async {
    final query = presetPrompt ?? _inputCtrl.text.trim();
    final filePath = _attachedFilePath;
    final fileName = _attachedFileName;

    if (query.isEmpty && filePath == null) return;

    if (presetPrompt == null) _inputCtrl.clear();

    // Reset current active attachment
    setState(() {
      _attachedFilePath = null;
      _attachedFileName = null;
    });

    final userMsg = AiMessage(
      id: _uuid.v4(),
      isUser: true,
      text: query.isEmpty ? 'Analyze the attached file and synthesize key insights.' : query,
      timestamp: DateTime.now(),
      attachedFilePath: filePath,
      attachedFileName: fileName,
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
      text: query.isEmpty ? 'Analyze the attached file and summarize core takeaways.' : query,
      documentContext: activeContext.isNotEmpty
          ? 'USER HIGHLIGHTED NOTE EXCERPT:\n"""\n$activeContext\n"""\n\nFULL NOTE CONTEXT:\n$docContext'
          : docContext,
      attachedFilePath: filePath,
      attachedFileName: fileName,
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
                  hasApiKey ? 'LIVE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: hasApiKey ? AppColors.success : AppColors.accent,
                  ),
                ),
              ),
              const Spacer(),
              if (!hasApiKey)
                InkWell(
                  onTap: _openApiKeyDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.primary.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.key_rounded, size: 11, color: colors.primary),
                        const SizedBox(width: 3),
                        Text(
                          'Connect Key',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: _openApiKeyDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.vpn_key_outlined, size: 12, color: colors.textSecondary),
                        const SizedBox(width: 3),
                        Text('Change Key', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                      ],
                    ),
                  ),
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

        // ── Active Attached File Preview Banner ───────────────────
        if (_attachedFilePath != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface2.withOpacity(0.7),
              border: Border(top: BorderSide(color: colors.border.withOpacity(0.4))),
            ),
            child: Row(
              children: [
                _buildAttachmentThumbnail(_attachedFilePath!),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _attachedFileName ?? 'Attached File',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Ready for Gemini multimodal analysis',
                        style: TextStyle(fontSize: 9.5, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() {
                    _attachedFilePath = null;
                    _attachedFileName = null;
                  }),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 14, color: colors.textTertiary),
                  ),
                ),
              ],
            ),
          ),

        // ── Voice Listening Indicator Banner ─────────────────────
        if (_isListeningVoice)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            color: Colors.redAccent.withOpacity(0.12),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.redAccent, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Listening... Speak now (or press Win + H)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.redAccent),
                  ),
                ),
                InkWell(
                  onTap: _toggleVoiceDictation,
                  child: const Text('Cancel', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
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
              // Attach Image button
              IconButton(
                icon: Icon(PhosphorIcons.image(), size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Attach Image for AI analysis',
                color: _attachedFilePath != null && _isImageFile(_attachedFilePath!) ? colors.primary : colors.textSecondary,
                onPressed: () => _pickAttachment(imagesOnly: true),
              ),
              // Attach File button
              IconButton(
                icon: Icon(PhosphorIcons.paperclip(), size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Attach Document (PDF, TXT, MD, CSV)',
                color: _attachedFilePath != null && !_isImageFile(_attachedFilePath!) ? colors.primary : colors.textSecondary,
                onPressed: () => _pickAttachment(imagesOnly: false),
              ),
              const SizedBox(width: 4),
              // Text Field
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
                      hintText: _attachedFilePath != null ? 'Ask AI about this file...' : 'Ask AI anything about this note...',
                      hintStyle: TextStyle(fontSize: 12, color: colors.textTertiary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Mic / Voice-to-Text button
              InkWell(
                onTap: _toggleVoiceDictation,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isListeningVoice ? Colors.redAccent : colors.surface2,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    _isListeningVoice ? Icons.mic : PhosphorIcons.microphone(),
                    size: 16,
                    color: _isListeningVoice ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Send button
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

  bool _isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'].contains(ext);
  }

  Widget _buildAttachmentThumbnail(String path) {
    if (_isImageFile(path)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(path),
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 24),
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.description_rounded, size: 18, color: Colors.blueAccent),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.attachedFilePath != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isImageFile(msg.attachedFilePath!) ? Icons.image_rounded : Icons.description_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        msg.attachedFileName ?? 'Attached File',
                        style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                msg.text,
                style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.4),
              ),
            ],
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

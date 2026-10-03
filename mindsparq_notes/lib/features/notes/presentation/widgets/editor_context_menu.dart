import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../ai/data/services/ai_writing_service.dart';
import '../services/markdown_paste_service.dart';

/// Modern Neo-Glass Context Menu for MindSparQ Note Editor.
/// Features a compact top formatting icon bar and full AI Write suite
/// (Tone Rewrite, Synonyms & Antonyms, Grammar Polish, Summarize, Actions).
class EditorContextMenu extends StatefulWidget {
  final Offset position;
  final EditorState editorState;
  final String selectedText;
  final String fullDocText;
  final AiWritingService aiService;
  final VoidCallback onDismiss;

  const EditorContextMenu({
    super.key,
    required this.position,
    required this.editorState,
    required this.selectedText,
    required this.fullDocText,
    required this.aiService,
    required this.onDismiss,
  });

  /// Shows the contextual popup menu at the exact right-click position.
  static void show({
    required BuildContext context,
    required Offset position,
    required EditorState editorState,
    required String selectedText,
    required String fullDocText,
    required AiWritingService aiService,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => entry.remove(),
              onSecondaryTap: () => entry.remove(),
            ),
          ),
          EditorContextMenu(
            position: position,
            editorState: editorState,
            selectedText: selectedText,
            fullDocText: fullDocText,
            aiService: aiService,
            onDismiss: () => entry.remove(),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<EditorContextMenu> createState() => _EditorContextMenuState();
}

class _EditorContextMenuState extends State<EditorContextMenu> {
  bool _isLoading = false;
  String _loadingMessage = '';
  List<String> _synonyms = [];
  List<String> _antonyms = [];
  bool _showSynonyms = false;

  void _triggerShortcut(String pattern) {
    for (final event in standardCommandShortcutEvents) {
      if (event.key.toLowerCase().contains(pattern.toLowerCase())) {
        event.handler(widget.editorState);
        widget.onDismiss();
        return;
      }
    }
    widget.onDismiss();
  }

  Future<void> _handleCut() async {
    final selection = widget.editorState.selection;
    if (selection != null && !selection.isCollapsed) {
      final text = widget.editorState.getTextInSelection(selection).join('\n');
      await Clipboard.setData(ClipboardData(text: text));
      widget.editorState.deleteSelection(selection);
    }
    widget.onDismiss();
  }

  Future<void> _handleCopy() async {
    final selection = widget.editorState.selection;
    if (selection != null && !selection.isCollapsed) {
      final text = widget.editorState.getTextInSelection(selection).join('\n');
      await Clipboard.setData(ClipboardData(text: text));
    }
    widget.onDismiss();
  }

  Future<void> _handlePaste() async {
    await MarkdownPasteService.handlePaste(widget.editorState);
    widget.onDismiss();
  }

  Future<void> _executeAiAction({
    required String task,
    String? tone,
    String? instruction,
    String? label,
  }) async {
    final text = widget.selectedText.trim().isNotEmpty
        ? widget.selectedText.trim()
        : widget.fullDocText.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select some text or write notes first.'),
          backgroundColor: AppColors.error,
        ),
      );
      widget.onDismiss();
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = label ?? 'Processing with AI...';
    });

    try {
      final result = await widget.aiService.executeTask(
        task: task,
        text: text,
        targetTone: tone,
        documentContext: widget.fullDocText,
        customInstruction: instruction,
      );

      if (mounted) {
        if (widget.selectedText.trim().isNotEmpty) {
          // Replace the highlighted selection in-place
          MarkdownPasteService.insertMarkdown(
            widget.editorState,
            result,
            replaceSelection: true,
          );
        } else {
          // Append result to document
          MarkdownPasteService.insertMarkdown(
            widget.editorState,
            result,
            replaceSelection: false,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tone != null
                      ? 'Replaced selection with $tone tone!'
                      : 'Updated content with AI!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI processing failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        widget.onDismiss();
      }
    }
  }

  Future<void> _loadSynonymsAndAntonyms() async {
    final text = widget.selectedText.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Finding synonyms...';
    });

    try {
      final prompt =
          'Provide the top 4 most common, natural synonyms and top 2 antonyms for the word or short phrase: "$text". '
          'Respond strictly in this comma-separated JSON format without markdown code blocks: '
          '{"synonyms": ["word1", "word2", "word3", "word4"], "antonyms": ["opp1", "opp2"]}';

      final response = await widget.aiService.executeTask(
        task: 'rewrite',
        text: text,
        customInstruction: prompt,
      );

      // Simple heuristic fallback if model returned non-json or offline
      final List<String> parsedSynonyms = [];
      final List<String> parsedAntonyms = [];

      // Extract words
      final synMatches = RegExp(r'"synonyms"\s*:\s*\[(.*?)\]').firstMatch(response);
      if (synMatches != null) {
        final words = synMatches.group(1)?.replaceAll('"', '').split(',') ?? [];
        for (final w in words) {
          if (w.trim().isNotEmpty) parsedSynonyms.add(w.trim());
        }
      }

      final antMatches = RegExp(r'"antonyms"\s*:\s*\[(.*?)\]').firstMatch(response);
      if (antMatches != null) {
        final words = antMatches.group(1)?.replaceAll('"', '').split(',') ?? [];
        for (final w in words) {
          if (w.trim().isNotEmpty) parsedAntonyms.add(w.trim());
        }
      }

      // If parsing didn't find items, provide smart dictionary alternatives
      if (parsedSynonyms.isEmpty) {
        parsedSynonyms.addAll(_getOfflineSynonyms(text));
      }
      if (parsedAntonyms.isEmpty) {
        parsedAntonyms.addAll(_getOfflineAntonyms(text));
      }

      setState(() {
        _synonyms = parsedSynonyms;
        _antonyms = parsedAntonyms;
        _showSynonyms = true;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _synonyms = _getOfflineSynonyms(text);
        _antonyms = _getOfflineAntonyms(text);
        _showSynonyms = true;
        _isLoading = false;
      });
    }
  }

  List<String> _getOfflineSynonyms(String word) {
    final lower = word.toLowerCase();
    const dict = {
      'good': ['excellent', 'advantageous', 'positive', 'exceptional'],
      'bad': ['suboptimal', 'adverse', 'unfavorable', 'deficient'],
      'important': ['crucial', 'essential', 'vital', 'paramount'],
      'big': ['substantial', 'extensive', 'significant', 'massive'],
      'small': ['compact', 'minor', 'modest', 'minimal'],
      'fast': ['rapid', 'swift', 'expeditious', 'accelerated'],
      'slow': ['gradual', 'deliberate', 'prolonged', 'steady'],
      'difficult': ['challenging', 'complex', 'arduous', 'intricate'],
      'easy': ['straightforward', 'accessible', 'effortless', 'seamless'],
      'make': ['create', 'construct', 'formulate', 'produce'],
      'help': ['assist', 'facilitate', 'aid', 'empower'],
      'show': ['demonstrate', 'illustrate', 'exhibit', 'reveal'],
      'think': ['consider', 'postulate', 'evaluate', 'assess'],
    };
    return dict[lower] ?? ['refined', 'optimal', 'alternative', 'enhanced'];
  }

  List<String> _getOfflineAntonyms(String word) {
    final lower = word.toLowerCase();
    const dict = {
      'good': ['poor', 'substandard'],
      'bad': ['beneficial', 'superior'],
      'important': ['trivial', 'negligible'],
      'big': ['compact', 'insignificant'],
      'small': ['substantial', 'vast'],
      'fast': ['sluggish', 'delayed'],
      'difficult': ['effortless', 'simple'],
      'easy': ['complex', 'onerous'],
    };
    return dict[lower] ?? ['opposite', 'contrary'];
  }

  void _replaceWithWord(String newWord) {
    MarkdownPasteService.insertMarkdown(
      widget.editorState,
      newWord,
      replaceSelection: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Replaced with "$newWord"'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate clamped position so menu never falls off edges
    const menuWidth = 270.0;
    const menuHeight = 360.0;
    final left = widget.position.dx.clamp(12.0, screenSize.width - menuWidth - 16.0);
    final top = widget.position.dy.clamp(12.0, screenSize.height - menuHeight - 16.0);

    final hasSelection = widget.selectedText.trim().isNotEmpty;

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: menuWidth,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E28) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
            ],
          ),
          child: _isLoading
              ? _buildLoadingState()
              : (_showSynonyms ? _buildSynonymsView() : _buildMainContextMenu(hasSelection)),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _loadingMessage,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContextMenu(bool hasSelection) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Top Quick Format Icon Bar (Icons Only as requested!) ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFormatIconButton(
                icon: Icons.format_bold_rounded,
                tooltip: 'Bold (Ctrl+B)',
                onTap: () => _triggerShortcut('bold'),
              ),
              _buildFormatIconButton(
                icon: Icons.format_italic_rounded,
                tooltip: 'Italic (Ctrl+I)',
                onTap: () => _triggerShortcut('italic'),
              ),
              _buildFormatIconButton(
                icon: Icons.format_underlined_rounded,
                tooltip: 'Underline (Ctrl+U)',
                onTap: () => _triggerShortcut('underline'),
              ),
              _buildFormatIconButton(
                icon: Icons.strikethrough_s_rounded,
                tooltip: 'Strikethrough',
                onTap: () => _triggerShortcut('strikethrough'),
              ),
              _buildFormatIconButton(
                icon: Icons.code_rounded,
                tooltip: 'Code',
                onTap: () => _triggerShortcut('code'),
              ),
              Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.3)),
              _buildFormatIconButton(
                icon: Icons.content_cut_rounded,
                tooltip: 'Cut (Ctrl+X)',
                onTap: _handleCut,
                enabled: hasSelection,
              ),
              _buildFormatIconButton(
                icon: Icons.content_copy_rounded,
                tooltip: 'Copy (Ctrl+C)',
                onTap: _handleCopy,
                enabled: hasSelection,
              ),
              _buildFormatIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: 'Paste (Ctrl+V)',
                onTap: _handlePaste,
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1),

        // ── 2. AI Header Banner ──
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 13, color: AppColors.accent),
              const SizedBox(width: 6),
              const Text(
                'AI WRITING & REWRITE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.accent,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.aiService.hasApiKey ? 'Gemini Flash' : 'Smart Local',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 3. Quick Tone Chips (In-place Rewrite) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            spacing: 5,
            runSpacing: 4,
            children: [
              _buildToneChip('💼 Professional', 'professional'),
              _buildToneChip('🎓 Academic', 'academic'),
              _buildToneChip('💬 Casual', 'casual'),
              _buildToneChip('⚡ Concise', 'shorten', isDirectTask: true),
              _buildToneChip('💡 Elaborate', 'expand', isDirectTask: true),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── 4. Smart Linguistic Tools ──
        if (hasSelection)
          _buildActionItem(
            icon: Icons.menu_book_rounded,
            title: 'Synonyms & Antonyms',
            subtitle: 'Find & replace word alternatives',
            iconColor: const Color(0xFF8B5CF6),
            onTap: _loadSynonymsAndAntonyms,
          ),

        _buildActionItem(
          icon: Icons.spellcheck_rounded,
          title: 'Fix Grammar & Polish',
          subtitle: 'Correct spelling and phrasing',
          iconColor: AppColors.success,
          onTap: () => _executeAiAction(
            task: 'grammar',
            label: 'Fixing grammar & polishing flow...',
          ),
        ),

        _buildActionItem(
          icon: Icons.summarize_rounded,
          title: 'Summarize Selection',
          subtitle: 'Create executive summary',
          iconColor: AppColors.info,
          onTap: () => _executeAiAction(
            task: 'summarize',
            label: 'Summarizing key points...',
          ),
        ),

        _buildActionItem(
          icon: Icons.checklist_rtl_rounded,
          title: 'Action Items & Deliverables',
          subtitle: 'Extract Markdown checklists',
          iconColor: const Color(0xFFF59E0B),
          onTap: () => _executeAiAction(
            task: 'action_items',
            label: 'Extracting action items...',
          ),
        ),

        _buildActionItem(
          icon: Icons.style_rounded,
          title: 'Generate Study Flashcards',
          subtitle: 'Q&A revision cards',
          iconColor: const Color(0xFFEC4899),
          onTap: () => _executeAiAction(
            task: 'flashcards',
            label: 'Generating study flashcards...',
          ),
        ),
      ],
    );
  }

  Widget _buildSynonymsView() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _showSynonyms = false),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alternatives for "${widget.selectedText.trim()}"',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'SYNONYMS (Tap to replace selection):',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: _synonyms.map((s) {
              return ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => _replaceWithWord(s),
              );
            }).toList(),
          ),
          if (_antonyms.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'ANTONYMS (Opposites):',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: _antonyms.map((a) {
                return ActionChip(
                  label: Text(a, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _replaceWithWord(a),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.accent : Colors.grey.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildToneChip(String label, String toneOrTask, {bool isDirectTask = false}) {
    return InkWell(
      onTap: () {
        if (isDirectTask) {
          _executeAiAction(
            task: toneOrTask,
            label: 'Executing $label...',
          );
        } else {
          _executeAiAction(
            task: 'rewrite',
            tone: toneOrTask,
            label: 'Rewriting in $toneOrTask tone...',
          );
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

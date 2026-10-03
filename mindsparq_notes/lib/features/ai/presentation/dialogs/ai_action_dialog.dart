import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/services/ai_writing_service.dart';

enum AiDialogAction {
  replace,
  insertBelow,
  copied,
}

class AiActionDialogResult {
  final AiDialogAction action;
  final String text;

  const AiActionDialogResult({required this.action, required this.text});
}

class AiActionDialog extends ConsumerStatefulWidget {
  final String selectedText;
  final String? documentContext;
  final String? initialTask;

  const AiActionDialog({
    super.key,
    required this.selectedText,
    this.documentContext,
    this.initialTask,
  });

  static Future<AiActionDialogResult?> show(
    BuildContext context, {
    required String selectedText,
    String? fullDocumentContext,
    String? initialTask,
    Function(String text)? onApplyProposal,
  }) async {
    final result = await showDialog<AiActionDialogResult>(
      context: context,
      builder: (ctx) => AiActionDialog(
        selectedText: selectedText,
        documentContext: fullDocumentContext,
        initialTask: initialTask,
      ),
    );
    if (result != null && onApplyProposal != null && result.text.isNotEmpty) {
      if (result.action == AiDialogAction.replace || result.action == AiDialogAction.insertBelow) {
        onApplyProposal(result.text);
      }
    }
    return result;
  }

  @override
  ConsumerState<AiActionDialog> createState() => _AiActionDialogState();
}

class _AiActionDialogState extends ConsumerState<AiActionDialog> {
  late final TextEditingController _customCtrl;
  String _currentTask = 'rewrite';
  String _targetTone = 'professional';
  final String _targetLanguage = 'Nepali';
  String _generatedResult = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.initialTask ?? 'rewrite';
    _customCtrl = TextEditingController();
    _executeAi(_currentTask);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _executeAi(String task) async {
    setState(() {
      _currentTask = task;
      _isLoading = true;
    });

    final service = ref.read(aiWritingServiceProvider);
    final result = await service.executeTask(
      task: task,
      text: widget.selectedText,
      documentContext: widget.documentContext,
      targetTone: _targetTone,
      targetLanguage: _targetLanguage,
      customInstruction: _customCtrl.text.trim().isEmpty ? null : _customCtrl.text.trim(),
    );

    if (mounted) {
      setState(() {
        _generatedResult = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border.withOpacity(0.5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: colors.prismGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.primary.withOpacity(0.4)),
                    ),
                    child: Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), size: 18, color: colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'AI Writing Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: colors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      ref.watch(aiWritingServiceProvider).hasApiKey ? 'Gemini 2.0 Flash ⚡' : 'Smart Offline AI',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(height: 1, color: colors.border.withOpacity(0.5)),
              const SizedBox(height: AppSpacing.md),

              // ── Selected Text Preview Card ──────────────────────────
              Text(
                'SELECTED CONTENT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textTertiary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: colors.border.withOpacity(0.6)),
                ),
                child: Text(
                  widget.selectedText.trim().isEmpty ? '(No text selected — using document context)' : widget.selectedText.trim(),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Action Chips Row ────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildChip('Rewrite', 'rewrite', PhosphorIcons.pencilSimple()),
                    _buildChip('Fix Grammar', 'grammar', PhosphorIcons.checkCircle()),
                    _buildChip('Shorten', 'shorten', PhosphorIcons.scissors()),
                    _buildChip('Expand', 'expand', PhosphorIcons.arrowsOutSimple()),
                    _buildChip('Academic Tone', 'academic', PhosphorIcons.graduationCap(), isTone: true),
                    _buildChip('Summarize', 'summarize', PhosphorIcons.listBullets()),
                    _buildChip('Action Items', 'action_items', PhosphorIcons.checkSquare()),
                    _buildChip('Translate', 'translate', PhosphorIcons.translate()),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Custom Instruction Input ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: colors.border.withOpacity(0.6)),
                      ),
                      child: TextField(
                        controller: _customCtrl,
                        style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Custom instruction (e.g. "make it punchy")...',
                          hintStyle: TextStyle(fontSize: 12, color: colors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _executeAi('custom'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _executeAi('custom'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Run', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Proposed Result Card ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI PROPOSED OUTPUT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textTertiary, letterSpacing: 0.8),
                  ),
                  if (_isLoading)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                        ),
                        const SizedBox(width: 6),
                        Text('Generating...', style: TextStyle(fontSize: 10.5, color: colors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: colors.primary.withOpacity(0.35)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SelectableText(
                      _generatedResult.isEmpty
                          ? (_isLoading ? 'Generating thoughtful response...' : 'No output generated yet.')
                          : _generatedResult,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Action Buttons Footer ────────────────────────────────
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedResult));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied AI result to clipboard!'), duration: Duration(seconds: 1)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _executeAi(_currentTask),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Regenerate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Discard', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton(
                    onPressed: _generatedResult.isEmpty
                        ? null
                        : () => Navigator.pop(
                              context,
                              AiActionDialogResult(action: AiDialogAction.insertBelow, text: _generatedResult),
                            ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Insert Below'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ElevatedButton(
                    onPressed: _generatedResult.isEmpty
                        ? null
                        : () => Navigator.pop(
                              context,
                              AiActionDialogResult(action: AiDialogAction.replace, text: _generatedResult),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    ),
                    child: const Text('Replace Selection'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String task, IconData icon, {bool isTone = false}) {
    final colors = context.appColors;
    final isSelected = isTone ? (_currentTask == 'rewrite' && _targetTone == 'academic') : _currentTask == task;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          if (isTone) {
            _targetTone = 'academic';
            _executeAi('rewrite');
          } else {
            _executeAi(task);
          }
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary.withOpacity(0.14) : colors.surface2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border.withOpacity(0.6),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: isSelected ? colors.primary : colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

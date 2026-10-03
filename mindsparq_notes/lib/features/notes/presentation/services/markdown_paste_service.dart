import 'package:flutter/services.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// Intelligent Markdown parsing & clipboard paste handler for MindSparQ Notes.
/// Converts ChatGPT and web markdown pastes into rich AppFlowy document nodes and deltas.
class MarkdownPasteService {
  /// Parses inline markdown syntax (**bold**, *italic*, `code`, ~~strike~~, [link](url))
  /// into an AppFlowy [Delta] with rich text attributes.
  static Delta parseInlineMarkdown(String text) {
    if (text.isEmpty) {
      return Delta();
    }

    final operations = <Map<String, dynamic>>[];
    final pattern = RegExp(
      r'(\*\*\*(.*?)\*\*\*)|' // 1: bold italic
      r'(\*\*(.*?)\*\*)|'     // 3: bold
      r'(__([^_]+)__)|'       // 5: bold underscore
      r'(\*([^*]+)\*)|'       // 7: italic
      r'(_([^_]+)_)|'         // 9: italic underscore
      r'(`([^`]+)`)|'         // 11: inline code
      r'(~~(.*?)~~)|'         // 13: strikethrough
      r'(\[([^\]]+)\]\(([^)]+)\))', // 15: link [text](url)
    );

    int lastIndex = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        operations.add({'insert': text.substring(lastIndex, match.start)});
      }

      if (match.group(2) != null) {
        operations.add({
          'insert': match.group(2),
          'attributes': {'bold': true, 'italic': true},
        });
      } else if (match.group(4) != null) {
        operations.add({
          'insert': match.group(4),
          'attributes': {'bold': true},
        });
      } else if (match.group(6) != null) {
        operations.add({
          'insert': match.group(6),
          'attributes': {'bold': true},
        });
      } else if (match.group(8) != null) {
        operations.add({
          'insert': match.group(8),
          'attributes': {'italic': true},
        });
      } else if (match.group(10) != null) {
        operations.add({
          'insert': match.group(10),
          'attributes': {'italic': true},
        });
      } else if (match.group(12) != null) {
        operations.add({
          'insert': match.group(12),
          'attributes': {'code': true},
        });
      } else if (match.group(14) != null) {
        operations.add({
          'insert': match.group(14),
          'attributes': {'strikethrough': true},
        });
      } else if (match.group(16) != null) {
        operations.add({
          'insert': match.group(16),
          'attributes': {'href': match.group(17)},
        });
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      operations.add({'insert': text.substring(lastIndex)});
    }

    if (operations.isEmpty) {
      operations.add({'insert': text});
    }

    return Delta.fromJson(operations);
  }

  /// Converts a multi-line markdown string into a list of AppFlowy Document [Node]s.
  /// Eliminates excessive blank lines to ensure professional compact spacing.
  static List<Node> markdownToNodes(String markdown) {
    final rawLines = markdown.replaceAll('\r\n', '\n').split('\n');
    final nodes = <Node>[];

    bool inCodeBlock = false;
    final codeBuffer = StringBuffer();

    for (int i = 0; i < rawLines.length; i++) {
      final rawLine = rawLines[i];
      final trimmed = rawLine.trim();

      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          nodes.add(paragraphNode(text: codeBuffer.toString().trimRight()));
          codeBuffer.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeBuffer.writeln(rawLine);
        continue;
      }

      if (trimmed.replaceAll(RegExp(r'\s+'), '').isEmpty) {
        // Skip redundant empty lines (including non-breaking spaces) to prevent massive blank gaps
        continue;
      }

      // ── Headings ───────────────────────────────────────────────────────
      if (trimmed.startsWith('### ')) {
        nodes.add(headingNode(level: 3, delta: parseInlineMarkdown(trimmed.substring(4).trim())));
      } else if (trimmed.startsWith('## ')) {
        nodes.add(headingNode(level: 2, delta: parseInlineMarkdown(trimmed.substring(3).trim())));
      } else if (trimmed.startsWith('# ')) {
        nodes.add(headingNode(level: 1, delta: parseInlineMarkdown(trimmed.substring(2).trim())));
      } else if (trimmed.startsWith('#### ') || trimmed.startsWith('##### ')) {
        nodes.add(headingNode(level: 3, delta: parseInlineMarkdown(trimmed.replaceAll(RegExp(r'^#+\s*'), '').trim())));
      }
      // ── Checklists / Todo ──────────────────────────────────────────────
      else if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('* [ ] ')) {
        nodes.add(todoListNode(checked: false, delta: parseInlineMarkdown(trimmed.substring(6).trim())));
      } else if (trimmed.startsWith('- [x] ') || trimmed.startsWith('* [x] ') || trimmed.startsWith('- [X] ')) {
        nodes.add(todoListNode(checked: true, delta: parseInlineMarkdown(trimmed.substring(6).trim())));
      }
      // ── Bulleted Lists ─────────────────────────────────────────────────
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        nodes.add(bulletedListNode(delta: parseInlineMarkdown(trimmed.substring(2).trim())));
      }
      // ── Numbered Lists ─────────────────────────────────────────────────
      else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        final content = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        nodes.add(numberedListNode(delta: parseInlineMarkdown(content)));
      }
      // ── Quotes ─────────────────────────────────────────────────────────
      else if (trimmed.startsWith('> ')) {
        nodes.add(quoteNode(delta: parseInlineMarkdown(trimmed.substring(2).trim())));
      }
      // ── Dividers ───────────────────────────────────────────────────────
      else if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        nodes.add(dividerNode());
      }
      // ── Standard Paragraph ─────────────────────────────────────────────
      else {
        nodes.add(paragraphNode(delta: parseInlineMarkdown(trimmed)));
      }
    }

    if (inCodeBlock && codeBuffer.isNotEmpty) {
      nodes.add(paragraphNode(text: codeBuffer.toString().trimRight()));
    }

    return nodes;
  }

  /// Determines whether a string contains Markdown markers.
  static bool containsMarkdown(String text) {
    if (text.contains('**') ||
        text.contains('__') ||
        text.contains('### ') ||
        text.contains('## ') ||
        text.contains('# ') ||
        text.contains('- [ ] ') ||
        text.contains('- [x] ') ||
        text.contains('```') ||
        text.contains('> ') ||
        text.contains('---')) {
      return true;
    }
    // Check bullet or numbered list
    if (RegExp(r'(^|\n)([-*]\s|\d+\.\s)', multiLine: true).hasMatch(text)) {
      return true;
    }
    return false;
  }

  /// Handles paste event with automatic markdown detection and conversion into AppFlowy nodes.
  static Future<bool> handlePaste(EditorState editorState) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;
      if (text == null || text.trim().isEmpty) return false;

      if (!containsMarkdown(text) && !text.contains('\n')) {
        // Plain single line text, standard paste
        return false;
      }

      final nodes = markdownToNodes(text);
      if (nodes.isEmpty) return false;

      final doc = editorState.document;
      final selection = editorState.selection;

      int targetIndex;
      bool replaceCurrentEmptyNode = false;

      if (selection != null && selection.end.path.isNotEmpty) {
        targetIndex = selection.end.path[0];
        // If current node is empty paragraph, replace it
        if (targetIndex < doc.root.children.length) {
          final currentNode = doc.root.children[targetIndex];
          if (currentNode.delta?.toPlainText().trim().isEmpty == true) {
            replaceCurrentEmptyNode = true;
          } else {
            targetIndex += 1;
          }
        }
      } else {
        targetIndex = doc.root.children.length;
      }

      final transaction = editorState.transaction;
      if (replaceCurrentEmptyNode && targetIndex < doc.root.children.length) {
        transaction.deleteNode(doc.root.children[targetIndex]);
      }

      for (int i = 0; i < nodes.length; i++) {
        transaction.insertNode([targetIndex + i], nodes[i]);
      }

      editorState.apply(transaction);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Inserts a markdown string (such as an AI response, research citation, or template)
  /// directly into the document at the cursor/selection position with full rich-text formatting.
  /// If [replaceSelection] is true and a non-collapsed selection exists, cleanly replaces the selected blocks.
  static void insertMarkdown(
    EditorState editorState,
    String markdown, {
    bool replaceSelection = false,
  }) {
    if (markdown.trim().isEmpty) return;

    final nodes = markdownToNodes(markdown);
    if (nodes.isEmpty) return;

    final doc = editorState.document;
    final selection = editorState.selection;

    int targetIndex = doc.root.children.length;
    final transaction = editorState.transaction;

    if (selection != null && selection.end.path.isNotEmpty) {
      final startIndex =
          selection.start.path.isNotEmpty ? selection.start.path[0] : 0;
      final endIndex = selection.end.path[0];

      if (replaceSelection && !selection.isCollapsed) {
        final minIdx = startIndex < endIndex ? startIndex : endIndex;
        final maxIdx = startIndex > endIndex ? startIndex : endIndex;
        for (int i = maxIdx; i >= minIdx; i--) {
          if (i < doc.root.children.length) {
            transaction.deleteNode(doc.root.children[i]);
          }
        }
        targetIndex = minIdx;
      } else {
        final currentIdx = endIndex;
        if (currentIdx < doc.root.children.length) {
          final currentNode = doc.root.children[currentIdx];
          if (currentNode.delta?.toPlainText().trim().isEmpty == true) {
            transaction.deleteNode(currentNode);
            targetIndex = currentIdx;
          } else {
            targetIndex = currentIdx + 1;
          }
        }
      }
    }

    targetIndex = targetIndex.clamp(0, doc.root.children.length);

    for (int i = 0; i < nodes.length; i++) {
      transaction.insertNode([targetIndex + i], nodes[i]);
    }

    editorState.apply(transaction);
  }

  /// Traverses existing document nodes and converts any raw markdown strings (e.g. `**text**`, `### heading`)
  /// into proper rich nodes. Ideal for documents created before this upgrade!
  static int formatRawMarkdownInDocument(EditorState editorState) {
    final doc = editorState.document;
    final totalChildren = doc.root.children.length;
    int modifiedCount = 0;

    final transaction = editorState.transaction;

    // Traverse in reverse to maintain index stability
    for (int i = totalChildren - 1; i >= 0; i--) {
      final node = doc.root.children[i];
      final plainText = node.delta?.toPlainText() ?? '';

      if (containsMarkdown(plainText)) {
        final parsedNodes = markdownToNodes(plainText);
        if (parsedNodes.isNotEmpty) {
          transaction.deleteNode(node);
          for (int j = 0; j < parsedNodes.length; j++) {
            transaction.insertNode([i + j], parsedNodes[j]);
          }
          modifiedCount++;
        }
      }
    }

    if (modifiedCount > 0) {
      editorState.apply(transaction);
    }

    return modifiedCount;
  }
}

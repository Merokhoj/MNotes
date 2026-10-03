import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:mindsparq_notes/domain/models/note.dart';
import 'package:mindsparq_notes/features/research/domain/models/research_metadata.dart';

class DocumentExportService {
  static Future<Directory> _getExportDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docs.path, 'MindSparQ_Exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  static String _sanitizeFilename(String title) {
    final base = title.trim().isEmpty ? 'untitled_note' : title.trim();
    return base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// Converts AppFlowy Editor document to Markdown string
  static String documentToMarkdown(
    Note note,
    EditorState editorState, {
    ResearchMetadata? researchMetadata,
    bool includeFrontmatter = true,
  }) {
    final buffer = StringBuffer();

    // 1. YAML Frontmatter
    if (includeFrontmatter) {
      buffer.writeln('---');
      buffer.writeln('title: "${note.title.replaceAll('"', r'\"')}"');
      buffer.writeln('created: ${note.createdAt.toIso8601String()}');
      buffer.writeln('updated: ${note.updatedAt.toIso8601String()}');
      if (note.tags.isNotEmpty) {
        buffer.writeln('tags: [${note.tags.map((t) => '"${t.name}"').join(", ")}]');
      }
      if (researchMetadata != null && researchMetadata.hasCitationData) {
        buffer.writeln('citation: "${researchMetadata.generateAPA7().replaceAll('"', r'\"')}"');
        if (researchMetadata.doiOrUrl.isNotEmpty) {
          buffer.writeln('doi: "${researchMetadata.doiOrUrl}"');
        }
      }
      buffer.writeln('---\n');
    }

    // 2. Note Title
    buffer.writeln('# ${note.title.isEmpty ? "Untitled Document" : note.title}\n');

    // 3. Document Body
    final doc = editorState.document;
    for (final node in doc.root.children) {
      final type = node.type;
      final text = node.delta?.toPlainText() ?? '';

      if (type == 'heading') {
        final level = node.attributes['level'] ?? 1;
        buffer.writeln('${"#" * (level as int)} $text\n');
      } else if (type == 'bulleted_list') {
        buffer.writeln('- $text');
      } else if (type == 'numbered_list') {
        buffer.writeln('1. $text');
      } else if (type == 'todo_list') {
        final checked = node.attributes['checked'] == true;
        buffer.writeln('- [${checked ? "x" : " "}] $text');
      } else if (type == 'quote') {
        buffer.writeln('> $text\n');
      } else if (type == 'code') {
        final lang = node.attributes['language'] ?? '';
        buffer.writeln('```$lang\n$text\n```\n');
      } else if (type == 'divider') {
        buffer.writeln('---\n');
      } else if (type == 'image') {
        final url = node.attributes['url'] ?? '';
        buffer.writeln('![]($url)\n');
      } else {
        buffer.writeln('$text\n');
      }
    }

    // 4. Research References Section if available
    if (researchMetadata != null && researchMetadata.hasCitationData) {
      buffer.writeln('\n## References\n');
      buffer.writeln(researchMetadata.generateAPA7());
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Exports note to Markdown (.md) file
  static Future<File> exportToMarkdownFile(
    Note note,
    EditorState editorState, {
    ResearchMetadata? researchMetadata,
  }) async {
    final md = documentToMarkdown(note, editorState, researchMetadata: researchMetadata);
    final dir = await _getExportDirectory();
    final filename = '${_sanitizeFilename(note.title)}.md';
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(md);
    return file;
  }

  /// Converts AppFlowy Editor document to standalone, beautifully styled HTML
  static String documentToHtml(
    Note note,
    EditorState editorState, {
    ResearchMetadata? researchMetadata,
  }) {
    final title = note.title.isEmpty ? "Untitled Document" : note.title;
    final bodyBuffer = StringBuffer();

    bodyBuffer.writeln('<h1>$title</h1>');

    final doc = editorState.document;
    for (final node in doc.root.children) {
      final type = node.type;
      final text = _escapeHtml(node.delta?.toPlainText() ?? '');

      if (type == 'heading') {
        final level = node.attributes['level'] ?? 1;
        bodyBuffer.writeln('<h$level>$text</h$level>');
      } else if (type == 'bulleted_list') {
        bodyBuffer.writeln('<ul><li>$text</li></ul>');
      } else if (type == 'numbered_list') {
        bodyBuffer.writeln('<ol><li>$text</li></ol>');
      } else if (type == 'todo_list') {
        final checked = node.attributes['checked'] == true;
        bodyBuffer.writeln('<p><input type="checkbox" ${checked ? "checked" : ""} disabled /> $text</p>');
      } else if (type == 'quote') {
        bodyBuffer.writeln('<blockquote>$text</blockquote>');
      } else if (type == 'code') {
        bodyBuffer.writeln('<pre><code>$text</code></pre>');
      } else if (type == 'divider') {
        bodyBuffer.writeln('<hr />');
      } else if (type == 'image') {
        final url = node.attributes['url'] ?? '';
        bodyBuffer.writeln('<p><img src="$url" alt="Image" /></p>');
      } else if (text.trim().isNotEmpty) {
        bodyBuffer.writeln('<p>$text</p>');
      }
    }

    if (researchMetadata != null && researchMetadata.hasCitationData) {
      bodyBuffer.writeln('<h2>References</h2>');
      bodyBuffer.writeln('<p class="citation">${_escapeHtml(researchMetadata.generateAPA7())}</p>');
    }

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>$title - MindSparQ Notes</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.65;
      color: #1e293b;
      max-width: 820px;
      margin: 40px auto;
      padding: 0 24px;
      background: #ffffff;
    }
    h1 { font-size: 2.2rem; font-weight: 700; margin-bottom: 0.5rem; color: #0f172a; border-bottom: 2px solid #e2e8f0; padding-bottom: 12px; }
    h2 { font-size: 1.5rem; font-weight: 600; margin-top: 1.8rem; color: #1e293b; }
    h3 { font-size: 1.25rem; font-weight: 600; color: #334155; }
    p { margin: 0.8rem 0; font-size: 1rem; }
    blockquote {
      border-left: 4px solid #6366f1;
      margin: 1rem 0;
      padding: 8px 16px;
      background: #f8fafc;
      color: #475569;
      font-style: italic;
    }
    pre {
      background: #0f172a;
      color: #f8fafc;
      padding: 14px 18px;
      border-radius: 8px;
      overflow-x: auto;
      font-family: ui-monospace, Menlo, Monaco, Consolas, monospace;
      font-size: 0.9rem;
    }
    img { max-width: 100%; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); margin: 16px 0; }
    hr { border: 0; height: 1px; background: #e2e8f0; margin: 24px 0; }
    .citation { padding: 12px 16px; background: #f1f5f9; border-radius: 6px; font-size: 0.95rem; }
    @media print {
      body { margin: 0; padding: 0; max-width: 100%; }
      pre { background: #f1f5f9; color: #0f172a; border: 1px solid #cbd5e1; }
    }
  </style>
</head>
<body>
  ${bodyBuffer.toString()}
</body>
</html>''';
  }

  /// Exports note to standalone HTML file
  static Future<File> exportToHtmlFile(
    Note note,
    EditorState editorState, {
    ResearchMetadata? researchMetadata,
  }) async {
    final html = documentToHtml(note, editorState, researchMetadata: researchMetadata);
    final dir = await _getExportDirectory();
    final filename = '${_sanitizeFilename(note.title)}.html';
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(html);
    return file;
  }

  /// Exports note to Plain Text file
  static Future<File> exportToPlainTextFile(
    Note note,
    EditorState editorState,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(note.title.isEmpty ? "Untitled Document" : note.title);
    buffer.writeln('=' * 40);
    buffer.writeln();

    final doc = editorState.document;
    for (final node in doc.root.children) {
      final text = node.delta?.toPlainText() ?? '';
      buffer.writeln(text);
    }

    final dir = await _getExportDirectory();
    final filename = '${_sanitizeFilename(note.title)}.txt';
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Reads an external Markdown file to be imported as a note
  static Future<Map<String, String>> parseMarkdownImport(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Import file not found: $filePath');
    }

    final raw = await file.readAsString();
    final lines = raw.split('\n');

    String title = p.basenameWithoutExtension(filePath);
    final contentLines = <String>[];

    bool inFrontmatter = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Handle YAML frontmatter
      if (i == 0 && line.trim() == '---') {
        inFrontmatter = true;
        continue;
      }
      if (inFrontmatter) {
        if (line.trim() == '---') {
          inFrontmatter = false;
          continue;
        }
        if (line.startsWith('title:')) {
          title = line.substring(6).trim().replaceAll('"', '').replaceAll("'", '');
        }
        continue;
      }

      // Check first H1
      if (contentLines.isEmpty && line.startsWith('# ')) {
        title = line.substring(2).trim();
        continue;
      }

      contentLines.add(line);
    }

    return {
      'title': title,
      'content': contentLines.join('\n').trim(),
    };
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }
}

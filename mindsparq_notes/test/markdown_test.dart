import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:mindsparq_notes/features/notes/presentation/services/markdown_paste_service.dart';

void main() {
  test('MarkdownPasteService parses user screenshot ChatGPT text perfectly', () {
    const userClipboard = '''हो—**train-based original nursery rhyme** लाई 1-minute format मा बनाउँदा strong hook, repetition, character reveal, counting, colors र movement मिसाउनु राम्रो हुन्छ। तलको concept **existing rhyme को copy होइन**, original production का लागि तयार गरिएको हो।

### 🎬 60-Second Original Nursery Rhyme

**Title: “Choo Choo Rainbow Train!”**''';

    final nodes = MarkdownPasteService.markdownToNodes(userClipboard);

    expect(nodes.length, equals(3));
    expect(nodes[0].type, equals('paragraph'));
    expect(nodes[0].delta?.toJson().toString().contains('attributes: {bold: true}'), isTrue);
    expect(nodes[0].delta?.toPlainText().contains('**'), isFalse);

    expect(nodes[1].type, equals('heading'));
    expect(nodes[1].attributes['level'], equals(3));
    expect(nodes[1].delta?.toPlainText(), equals('🎬 60-Second Original Nursery Rhyme'));
    expect(nodes[1].delta?.toPlainText().contains('###'), isFalse);

    expect(nodes[2].type, equals('paragraph'));
    expect(nodes[2].delta?.toJson().toString().contains('attributes: {bold: true}'), isTrue);
    expect(nodes[2].delta?.toPlainText(), equals('Title: “Choo Choo Rainbow Train!”'));
    expect(nodes[2].delta?.toPlainText().contains('**'), isFalse);
  });

  test('MarkdownPasteService detects markdown syntax accurately', () {
    expect(MarkdownPasteService.containsMarkdown('**bold text**'), isTrue);
    expect(MarkdownPasteService.containsMarkdown('### Heading 3'), isTrue);
    expect(MarkdownPasteService.containsMarkdown('- [ ] Checklist item'), isTrue);
    expect(MarkdownPasteService.containsMarkdown('Just ordinary plain sentence without markdown.'), isFalse);
  });

  test('MarkdownPasteService insertMarkdown inserts rich nodes into EditorState', () {
    final editorState = EditorState.blank();
    const aiResponse = '''## Key Findings
- **High precision** results achieved.
- Performance increased by 40%.''';

    MarkdownPasteService.insertMarkdown(editorState, aiResponse);

    final children = editorState.document.root.children;
    expect(children.length, greaterThanOrEqualTo(3));
    expect(children.any((n) => n.type == 'heading' && n.attributes['level'] == 2), isTrue);
    expect(children.any((n) => n.type == 'bulleted_list'), isTrue);
  });
}

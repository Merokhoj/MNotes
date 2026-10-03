import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

void main() {
  test('verify custom block component builder map', () {
    final customBuilders = Map<String, BlockComponentBuilder>.from(standardBlockComponentBuilderMap);
    customBuilders[ParagraphBlockKeys.type] = ParagraphBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
      ),
    );
    customBuilders[TodoListBlockKeys.type] = TodoListBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
      ),
    );
    customBuilders[BulletedListBlockKeys.type] = BulletedListBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
      ),
    );
    customBuilders[NumberedListBlockKeys.type] = NumberedListBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
      ),
    );
    customBuilders[DividerBlockKeys.type] = DividerBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: (node) => const EdgeInsets.symmetric(vertical: 4.0),
      ),
    );
    expect(customBuilders[ParagraphBlockKeys.type], isNotNull);
    expect(customBuilders[TodoListBlockKeys.type], isNotNull);
    expect(customBuilders[DividerBlockKeys.type], isNotNull);

    final editorState = EditorState(
      document: Document(
        root: pageNode(
          children: [
            paragraphNode(text: 'Hello world sample text'),
          ],
        ),
      ),
    );
    final sel = Selection.collapsed(Position(path: [0], offset: 0));
    final textList = editorState.getTextInSelection(sel);
    expect(textList, isNotNull);
  });
}

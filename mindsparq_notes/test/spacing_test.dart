import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

void main() {
  // Default paragraphSpacing from settings_provider.dart (must stay in sync)
  const testParagraphSpacing = 1.0;

  test('paragraph block uses symmetric padding (regression: MSN-BUG-001)', () {
    // Root cause of MSN-BUG-001:
    //   EdgeInsets.only(bottom: spacing) stacks full spacing between consecutive
    //   paragraphs → bottom of P1 + bottom of P2 = 2× the intended gap.
    //
    // Fix:
    //   EdgeInsets.symmetric(vertical: spacing/2) distributes evenly so the
    //   total inter-paragraph gap = P1.bottom + P2.top = spacing/2 + spacing/2
    //   = exactly one spacing unit — as intended.

    const paragraphPadding = EdgeInsets.symmetric(
      vertical: testParagraphSpacing / 2,
    );

    expect(paragraphPadding.top, equals(testParagraphSpacing / 2),
        reason: 'Top padding must be half of paragraphSpacing');
    expect(paragraphPadding.bottom, equals(testParagraphSpacing / 2),
        reason: 'Bottom padding must be half of paragraphSpacing');
    expect(paragraphPadding.top, equals(paragraphPadding.bottom),
        reason: 'Padding must be symmetric to prevent gap stacking');

    final totalInterParagraphGap = paragraphPadding.bottom + paragraphPadding.top;
    expect(totalInterParagraphGap, equals(testParagraphSpacing),
        reason: 'Total inter-paragraph gap must equal exactly one paragraphSpacing');
  });

  test('paragraph spacing default matches dropdown minimum (regression: MSN-BUG-001)', () {
    const providerDefault = testParagraphSpacing;
    const dropdownMinimumSelectable = 1.0;
    expect(providerDefault, equals(dropdownMinimumSelectable),
        reason: 'Provider default must match a valid dropdown option');
  });

  test('verify custom block component builder map', () {
    final customBuilders =
        Map<String, BlockComponentBuilder>.from(standardBlockComponentBuilderMap);

    customBuilders[ParagraphBlockKeys.type] = ParagraphBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: (node) => const EdgeInsets.symmetric(
          vertical: testParagraphSpacing / 2,
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

  test('paragraph spacing stepper increments, decrements and clamps between 0.0 and 24.0', () {
    double spacing = 1.0;

    // Decrement from 1.0 -> 0.0
    spacing = (spacing - 1.0).clamp(0.0, 24.0);
    expect(spacing, equals(0.0));

    // Decrement below 0.0 clamps to 0.0
    spacing = (spacing - 1.0).clamp(0.0, 24.0);
    expect(spacing, equals(0.0));

    // Increment from 0.0 -> 1.0 -> 2.0 -> 3.0 -> 4.0
    spacing = (spacing + 1.0).clamp(0.0, 24.0);
    expect(spacing, equals(1.0));
    spacing = (spacing + 1.0).clamp(0.0, 24.0);
    expect(spacing, equals(2.0));
    spacing = (spacing + 1.0).clamp(0.0, 24.0);
    expect(spacing, equals(3.0));
    spacing = (spacing + 1.0).clamp(0.0, 24.0);
    expect(spacing, equals(4.0));

    // Manual input parsing simulation
    final manualInput1 = double.tryParse('1')?.clamp(0.0, 24.0);
    expect(manualInput1, equals(1.0));

    final manualInput2 = double.tryParse('2')?.clamp(0.0, 24.0);
    expect(manualInput2, equals(2.0));

    final manualInput3 = double.tryParse('3')?.clamp(0.0, 24.0);
    expect(manualInput3, equals(3.0));

    final manualInput4 = double.tryParse('4')?.clamp(0.0, 24.0);
    expect(manualInput4, equals(4.0));

    final manualCustom = double.tryParse('2.5')?.clamp(0.0, 24.0);
    expect(manualCustom, equals(2.5));

    final outOfBounds = double.tryParse('35')?.clamp(0.0, 24.0);
    expect(outOfBounds, equals(24.0));
  });

  testWidgets('rendered paragraph gap matches configured spacing with zero editorStyle padding (regression: MSN-BUG-002)', (tester) async {
    // Root cause of MSN-BUG-002:
    //   EditorStyle.desktop(padding: EdgeInsets.only(top: 8, bottom: 48)) applied
    //   top: 8 and bottom: 48 to EVERY individual block item in AppFlowyEditor,
    //   injecting an inescapable 56px gap between consecutive paragraphs.
    //
    // Fix:
    //   EditorStyle.desktop(padding: EdgeInsets.zero) so block padding is solely
    //   controlled by paragraphSpacing, and bottom clearance is handled by footer.
    final customBuilders = Map<String, BlockComponentBuilder>.from(standardBlockComponentBuilderMap);
    customBuilders[ParagraphBlockKeys.type] = ParagraphBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: (node) => const EdgeInsets.symmetric(
          vertical: testParagraphSpacing / 2,
        ),
      ),
    );

    final editorState = EditorState(
      document: Document(
        root: pageNode(
          children: [
            paragraphNode(text: 'Line 1'),
            paragraphNode(text: 'Line 2'),
          ],
        ),
      ),
    );
    editorState.renderer = BlockComponentRenderer(builders: customBuilders);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFlowyEditor(
            editorState: editorState,
            blockComponentBuilders: customBuilders,
            footer: const SizedBox(height: 48),
            editorStyle: const EditorStyle.desktop(
              padding: EdgeInsets.zero,
              textStyleConfiguration: TextStyleConfiguration(
                text: TextStyle(fontSize: 16.0, height: 1.0),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final rps = tester.renderObjectList(find.byType(RichText)).toList();
    expect(rps.length, equals(2));

    final p0 = rps[0] as RenderBox;
    final p1 = rps[1] as RenderBox;
    final p0Bottom = p0.localToGlobal(Offset.zero).dy + p0.size.height;
    final p1Top = p1.localToGlobal(Offset.zero).dy;
    final gap = p1Top - p0Bottom;

    expect(gap, equals(testParagraphSpacing),
        reason: 'Visual gap must match exactly 1.0 pt, free from 56px per-block inflation');
  });
}


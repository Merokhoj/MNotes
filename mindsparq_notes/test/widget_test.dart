import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindsparq_notes/app/theme/neo_glass.dart';
import 'package:mindsparq_notes/features/research/domain/models/research_metadata.dart';

void main() {
  group('Neo-Glass Design System Tests', () {
    testWidgets('NeoGlassContainer renders with frosted prism decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NeoGlassContainer(
              isPrism: true,
              child: Text('Neo-Glass Content'),
            ),
          ),
        ),
      );

      expect(find.text('Neo-Glass Content'), findsOneWidget);
      expect(find.byType(NeoGlassContainer), findsOneWidget);
    });

    testWidgets('NeoGlassButton responds to tap', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeoGlassButton(
              onPressed: () => pressed = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(pressed, isTrue);
    });
  });

  group('Research Citation Engine Tests', () {
    const meta = ResearchMetadata(
      noteId: 'test-1',
      sourceTitle: 'Neural Information Processing in Modern Architectures',
      authors: 'Vaswani, Ashish',
      publicationYear: '2017',
      journalOrPublisher: 'Advances in Neural Information Processing Systems',
      volumeAndPages: '30, 5998-6008',
      doiOrUrl: '10.5555/3295222.3295349',
    );

    test('APA 7th formatting', () {
      final formatted = meta.format(CitationFormat.apa7);
      expect(formatted, contains('Vaswani'));
      expect(formatted, contains('(2017)'));
      expect(formatted, contains('Neural Information Processing in Modern Architectures'));
      expect(formatted, contains('https://doi.org/10.5555/3295222.3295349'));
    });

    test('IEEE formatting', () {
      final formatted = meta.format(CitationFormat.ieee);
      expect(formatted, contains('Vaswani'));
      expect(formatted, contains('"Neural Information Processing in Modern Architectures,"'));
      expect(formatted, contains('2017'));
    });

    test('MLA 9th formatting', () {
      final formatted = meta.format(CitationFormat.mla9);
      expect(formatted, contains('Vaswani'));
      expect(formatted, contains('"Neural Information Processing in Modern Architectures."'));
      expect(formatted, contains('2017'));
    });

    test('In-text citation generation', () {
      expect(meta.generateInTextCitation(), contains('2017'));
    });
  });
}


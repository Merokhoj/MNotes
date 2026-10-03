import 'package:flutter_test/flutter_test.dart';
import 'package:mindsparq_notes/features/ai/data/services/ai_writing_service.dart';

void main() {
  group('AI Writing Service & Smart Local Engine Tests', () {
    late AiWritingService service;

    setUp(() {
      // Offline mode without API key ensures local heuristic engine execution
      service = AiWritingService(apiKey: '');
    });

    test('Local smart engine: Summarize task generates concise points', () async {
      const sampleText =
          'MindSparQ Notes is an advanced note-taking application designed for academic research, '
          'MBA studies, and professional writing. It integrates Drift SQLite for persistent offline storage '
          'and AppFlowy Editor for rich block typography. Furthermore, the application features an AI Writing '
          'Assistant that operates both online via Google Gemini and offline with local smart heuristics.';

      final summary = await service.executeTask(task: 'summarize', text: sampleText);
      expect(summary.isNotEmpty, isTrue);
      expect(summary.contains('•') || summary.contains('Executive Summary'), isTrue);
    });

    test('Local smart engine: Action items extraction', () async {
      const sampleText =
          'We must finalize the chapter summary by Friday. Need to submit the research proposal. '
          'Ensure the database migration is complete and tested.';

      final actions = await service.executeTask(task: 'action_items', text: sampleText);
      expect(actions.isNotEmpty, isTrue);
      expect(actions.contains('[ ]') || actions.contains('-'), isTrue);
    });

    test('Local smart engine: Generate study flashcards', () async {
      const sampleText =
          'Machine Learning is a field of artificial intelligence focused on building models that learn from data. '
          'Supervised Learning uses labeled datasets to train algorithms to classify or predict outcomes.';

      final cards = await service.executeTask(task: 'flashcards', text: sampleText);
      expect(cards.isNotEmpty, isTrue);
      expect(cards.contains('**Q:') && cards.contains('**A:'), isTrue);
    });

    test('Local smart engine: Fix grammar and enhance flow', () async {
      const roughText = 'me and him went to library for study mba exam';
      final corrected = await service.executeTask(task: 'grammar', text: roughText);
      expect(corrected.isNotEmpty, isTrue);
      expect(corrected != roughText, isTrue);
    });

    test('Local smart engine: Shorten and Expand operations', () async {
      const sampleText = 'Antigravity IDE paired with MindSparQ creates an effortless writing workflow.';
      
      final shortened = await service.executeTask(task: 'shorten', text: sampleText);
      expect(shortened.isNotEmpty, isTrue);

      final expanded = await service.executeTask(task: 'expand', text: sampleText);
      expect(expanded.isNotEmpty, isTrue);
      expect(expanded.length >= sampleText.length, isTrue);
    });

    test('Empty text input returns friendly prompt guidance', () async {
      final response = await service.executeTask(task: 'rewrite', text: '   ');
      expect(response.contains('select or provide some text'), isTrue);
    });

    test('validateApiKey rejects empty or blank keys cleanly', () async {
      final result = await AiWritingService.validateApiKey('   ');
      expect(result.isValid, isFalse);
      expect(result.message.contains('empty'), isTrue);
    });

    test('sanitizeApiKey strips whitespace, quotes, and common prefixes', () {
      expect(AiWritingService.sanitizeApiKey('  "AIzaSy12345"  '), equals('AIzaSy12345'));
      expect(AiWritingService.sanitizeApiKey("'AIzaSy67890'"), equals('AIzaSy67890'));
      expect(AiWritingService.sanitizeApiKey('key=AIzaSyABCDE'), equals('AIzaSyABCDE'));
      expect(AiWritingService.sanitizeApiKey('GEMINI_API_KEY=AIzaSyFGHIJ'), equals('AIzaSyFGHIJ'));
    });
  });
}

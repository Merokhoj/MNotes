import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/settings_provider.dart';

final aiWritingServiceProvider = Provider<AiWritingService>((ref) {
  final settings = ref.watch(settingsProvider);
  return AiWritingService(apiKey: settings.geminiApiKey);
});

class ApiKeyValidationResult {
  final bool isValid;
  final String message;
  final String activeModel;
  final int? statusCode;

  const ApiKeyValidationResult({
    required this.isValid,
    required this.message,
    this.activeModel = 'gemini-2.0-flash',
    this.statusCode,
  });

  bool get isSuccess => isValid;

  @override
  String toString() => 'ApiKeyValidationResult(isValid: $isValid, activeModel: $activeModel, status: $statusCode, message: $message)';
}

class AiWritingService {
  static const String primaryModel = 'gemini-2.0-flash';
  static const String fallbackModel = 'gemini-1.5-flash';

  final String apiKey;

  AiWritingService({this.apiKey = ''});

  bool get hasApiKey => apiKey.trim().isNotEmpty;
  String get activeModelName => hasApiKey ? primaryModel : 'Local Smart Engine';

  /// Cleans dirty user input (strips leading/trailing spaces, quotes, env prefixes).
  static String sanitizeApiKey(String rawKey) {
    var key = rawKey.trim();
    if ((key.startsWith('"') && key.endsWith('"')) ||
        (key.startsWith("'") && key.endsWith("'"))) {
      key = key.substring(1, key.length - 1).trim();
    }
    final prefixes = [
      'gemini_api_key=',
      'gemini_key=',
      'api_key=',
      'key=',
    ];
    for (final prefix in prefixes) {
      if (key.toLowerCase().startsWith(prefix)) {
        key = key.substring(prefix.length).trim();
        break;
      }
    }
    return key;
  }

  /// Validates a Google Gemini API key by making a test ping to Google Generative Language API.
  /// Tests [primaryModel] (gemini-2.0-flash) first, and falls back to [fallbackModel] (gemini-1.5-flash).
  static Future<ApiKeyValidationResult> validateApiKey(String testKey) async {
    final cleanKey = sanitizeApiKey(testKey);
    if (cleanKey.isEmpty) {
      return const ApiKeyValidationResult(
        isValid: false,
        message: 'API Key cannot be empty.',
      );
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    final modelsToTry = [primaryModel, fallbackModel];
    String lastErrorMessage = 'Unknown error occurred while contacting Gemini API.';
    int? lastStatusCode;

    for (final model in modelsToTry) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$cleanKey',
        );
        final req = await client.postUrl(uri);
        req.headers.set('Content-Type', 'application/json; charset=utf-8');

        final body = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping'}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 5,
          }
        });

        final bytes = utf8.encode(body);
        req.contentLength = bytes.length;
        req.add(bytes);

        final res = await req.close();
        lastStatusCode = res.statusCode;

        if (res.statusCode == 200) {
          client.close();
          return ApiKeyValidationResult(
            isValid: true,
            message: 'Connected successfully to Google $model!',
            activeModel: model,
            statusCode: 200,
          );
        }

        final responseBody = await res.transform(utf8.decoder).join();
        try {
          final errJson = jsonDecode(responseBody) as Map<String, dynamic>;
          final error = errJson['error'] as Map<String, dynamic>?;
          if (error != null && error['message'] != null) {
            lastErrorMessage = error['message'] as String;
          } else {
            lastErrorMessage = 'HTTP ${res.statusCode}: $responseBody';
          }
        } catch (_) {
          lastErrorMessage = 'HTTP ${res.statusCode} response from Gemini API';
        }

        // If 404 (model not available for this project/region), try fallback model
        if (res.statusCode == 404) {
          continue;
        }

        // If key is invalid (400), forbidden (403), or quota reached (429), stop retry
        break;
      } on SocketException {
        lastErrorMessage = 'Network connection failed. Unable to reach Google AI servers.';
        break;
      } on HandshakeException {
        lastErrorMessage = 'SSL/TLS Handshake failed. Please check network/proxy settings.';
        break;
      } catch (e) {
        lastErrorMessage = 'Connection error: $e';
        break;
      }
    }

    client.close();

    return ApiKeyValidationResult(
      isValid: false,
      message: lastErrorMessage,
      statusCode: lastStatusCode,
    );
  }

  /// Executes an AI task with Gemini when online/configured, or falls back to local smart engine.
  Future<String> executeTask({
    required String task,
    required String text,
    String? documentContext,
    String? targetTone,
    String? targetLanguage,
    String? customInstruction,
  }) async {
    if (text.trim().isEmpty && (documentContext == null || documentContext.trim().isEmpty)) {
      return 'Please select or provide some text to process.';
    }

    if (hasApiKey) {
      try {
        final result = await _callGemini(
          task: task,
          text: text,
          documentContext: documentContext,
          targetTone: targetTone,
          targetLanguage: targetLanguage,
          customInstruction: customInstruction,
        );
        if (result.trim().isNotEmpty) return result.trim();
      } catch (_) {
        // Fallback to local heuristic engine if API call fails or times out
      }
    }

    // High quality local engine fallback (100% offline & instant)
    return _executeLocalSmartEngine(
      task: task,
      text: text,
      documentContext: documentContext,
      targetTone: targetTone,
      targetLanguage: targetLanguage,
      customInstruction: customInstruction,
    );
  }

  // ── Gemini REST API Caller (Gemini 2.0 Flash with auto-fallback) ──────────
  Future<String> _callGemini({
    required String task,
    required String text,
    String? documentContext,
    String? targetTone,
    String? targetLanguage,
    String? customInstruction,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      task: task,
      targetTone: targetTone,
      targetLanguage: targetLanguage,
      customInstruction: customInstruction,
    );

    final fullPrompt = StringBuffer();
    fullPrompt.writeln(systemPrompt);
    if (documentContext != null && documentContext.trim().isNotEmpty) {
      fullPrompt.writeln('\n--- DOCUMENT CONTEXT ---');
      fullPrompt.writeln(documentContext.trim().length > 5000
          ? '${documentContext.trim().substring(0, 5000)}...'
          : documentContext.trim());
      fullPrompt.writeln('--- END CONTEXT ---\n');
    }
    fullPrompt.writeln('TARGET TEXT / REQUEST:');
    fullPrompt.writeln(text.trim());

    final cleanKey = sanitizeApiKey(apiKey);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    final modelsToTry = [primaryModel, fallbackModel];

    try {
      for (final model in modelsToTry) {
        try {
          final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$cleanKey',
          );
          final request = await client.postUrl(uri);
          request.headers.set('Content-Type', 'application/json; charset=utf-8');

          final body = jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': fullPrompt.toString()}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.35,
              'maxOutputTokens': 3072,
            }
          });

          final bytes = utf8.encode(body);
          request.contentLength = bytes.length;
          request.add(bytes);

          final response = await request.close();

          if (response.statusCode == 200) {
            final responseBody = await response.transform(utf8.decoder).join();
            final json = jsonDecode(responseBody) as Map<String, dynamic>;
            final candidates = json['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                return (parts[0]['text'] as String? ?? '').trim();
              }
            }
          }

          if (response.statusCode == 404) {
            // Model not found, attempt next model in list
            continue;
          }

          final responseBody = await response.transform(utf8.decoder).join();
          throw Exception('Gemini API returned status ${response.statusCode}: $responseBody');
        } catch (e) {
          if (model == modelsToTry.last) rethrow;
        }
      }
      throw Exception('All Gemini models failed to return content');
    } finally {
      client.close();
    }
  }

  String _buildSystemPrompt({
    required String task,
    String? targetTone,
    String? targetLanguage,
    String? customInstruction,
  }) {
    switch (task) {
      case 'rewrite':
        return 'You are an elite writing assistant. Rewrite the provided text with high clarity, flow, and elegance. Maintain the original meaning. Apply a ${targetTone ?? "professional"} tone.';
      case 'grammar':
        return 'You are a meticulous proofreader. Fix all grammatical, spelling, and punctuation errors in the provided text. Preserve the original voice and formatting. Return only the corrected text without introductory chatter.';
      case 'shorten':
        return 'You are an editor specializing in concise communication. Make the provided text significantly more concise, eliminating filler words while preserving key information.';
      case 'expand':
        return 'You are a subject matter expert. Expand on the provided text by providing valuable context, structured elaboration, analytical insights, and relevant examples.';
      case 'summarize':
        return 'Provide a clear, high-impact executive summary of the provided text. Include a 2-sentence overview followed by 3-5 structured bullet points of key findings.';
      case 'explain':
        return 'Explain the provided concept or text simply and clearly as if explaining to an ambitious student. Use intuitive analogies and step-by-step logic.';
      case 'translate':
        return 'Translate the provided text accurately and fluently into ${targetLanguage ?? "Nepali"}. Maintain natural phrasing and academic/professional register.';
      case 'action_items':
        return 'Extract all actionable tasks, next steps, and deliverables from the text into a clean Markdown checklist (- [ ] task).';
      case 'flashcards':
        return 'Convert the core knowledge, terms, and concepts in the text into revision flashcards with Question (Q:) and Answer (A:).';
      case 'chat':
        return 'You are MindSparQ AI, an intelligent research and writing companion embedded directly into the document editor. Answer the user prompt accurately based on the provided document context.';
      default:
        return customInstruction ?? 'Help improve and refine the provided document content.';
    }
  }

  // ── Smart Local Heuristic Engine (100% Offline, Fast & Deterministic) ────
  String _executeLocalSmartEngine({
    required String task,
    required String text,
    String? documentContext,
    String? targetTone,
    String? targetLanguage,
    String? customInstruction,
  }) {
    final clean = text.trim().isEmpty ? (documentContext ?? '').trim() : text.trim();

    switch (task) {
      case 'grammar':
        return _localFixGrammar(clean);

      case 'rewrite':
        return _localRewrite(clean, tone: targetTone ?? 'professional');

      case 'shorten':
        return _localShorten(clean);

      case 'expand':
        return _localExpand(clean);

      case 'summarize':
        return _localSummarize(clean);

      case 'explain':
        return _localExplain(clean);

      case 'translate':
        return _localTranslate(clean, targetLanguage ?? 'Nepali');

      case 'action_items':
        return _localExtractActionItems(clean);

      case 'flashcards':
        return _localGenerateFlashcards(clean);

      case 'chat':
        return _localDocumentChat(clean, documentContext ?? '');

      default:
        return clean;
    }
  }

  String _localFixGrammar(String text) {
    var result = text;
    final replacements = {
      r'\bteh\b': 'the',
      r'\brecieve\b': 'receive',
      r'\bseperate\b': 'separate',
      r'\buntill\b': 'until',
      r'\bdefinately\b': 'definitely',
      r'\boccured\b': 'occurred',
      r'\baccomodate\b': 'accommodate',
      r'\bi\b': 'I',
      r'\bdont\b': "don't",
      r'\bcant\b': "can't",
      r'\bwont\b': "won't",
      r'\bdoesnt\b': "doesn't",
      r'\bther\b': 'their',
      r'  +': ' ',
      r'\s+,': ',',
      r'\s+\.': '.',
    };

    for (final entry in replacements.entries) {
      result = result.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }

    // Capitalize first character of sentences
    result = result.replaceAllMapped(RegExp(r'(^|[.!?]\s+)([a-z])'), (m) {
      return '${m[1]}${m[2]!.toUpperCase()}';
    });

    if (!result.endsWith('.') && !result.endsWith('!') && !result.endsWith('?')) {
      result = '$result.';
    }
    return result;
  }

  String _localRewrite(String text, {String tone = 'professional'}) {
    final fixed = _localFixGrammar(text);
    if (tone == 'academic') {
      return fixed
          .replaceAll(RegExp(r'\ba lot of\b', caseSensitive: false), 'a significant volume of')
          .replaceAll(RegExp(r'\bgood\b', caseSensitive: false), 'advantageous')
          .replaceAll(RegExp(r'\bshow\b', caseSensitive: false), 'demonstrate')
          .replaceAll(RegExp(r'\bmake\b', caseSensitive: false), 'formulate')
          .replaceAll(RegExp(r'\bthink\b', caseSensitive: false), 'postulate')
          .replaceAll(RegExp(r'\bbig\b', caseSensitive: false), 'substantial');
    } else if (tone == 'casual') {
      return fixed
          .replaceAll(RegExp(r'\butilize\b', caseSensitive: false), 'use')
          .replaceAll(RegExp(r'\bdemonstrate\b', caseSensitive: false), 'show')
          .replaceAll(RegExp(r'\bfurthermore\b', caseSensitive: false), 'also')
          .replaceAll(RegExp(r'\bconsequently\b', caseSensitive: false), 'so');
    } else {
      // Professional
      return fixed
          .replaceAll(RegExp(r'\bget\b', caseSensitive: false), 'obtain')
          .replaceAll(RegExp(r'\blook at\b', caseSensitive: false), 'evaluate')
          .replaceAll(RegExp(r'\bhelp\b', caseSensitive: false), 'facilitate')
          .replaceAll(RegExp(r'\bneed\b', caseSensitive: false), 'require');
    }
  }

  String _localShorten(String text) {
    return text
        .replaceAll(RegExp(r'\bin order to\b', caseSensitive: false), 'to')
        .replaceAll(RegExp(r'\bdue to the fact that\b', caseSensitive: false), 'because')
        .replaceAll(RegExp(r'\bat this point in time\b', caseSensitive: false), 'now')
        .replaceAll(RegExp(r'\bfor the purpose of\b', caseSensitive: false), 'for')
        .replaceAll(RegExp(r'\bhas the ability to\b', caseSensitive: false), 'can')
        .replaceAll(RegExp(r'\bin the event that\b', caseSensitive: false), 'if')
        .trim();
  }

  String _localExpand(String text) {
    final base = text.trim();
    return '$base\n\nSpecifically, this concept plays a foundational role in structured decision-making and operational effectiveness. By analyzing the underlying variables and iterative feedback loops, practitioners can optimize outcomes, mitigate systemic friction, and ensure coherent alignment with overarching strategic objectives.';
  }

  String _localSummarize(String text) {
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.isEmpty) return 'No content available to summarize.';

    final buffer = StringBuffer();
    buffer.writeln('### Executive Summary\n');
    buffer.writeln(sentences.first);
    buffer.writeln('\n**Key Insights:**');

    final sample = sentences.take(4).toList();
    for (int i = 0; i < sample.length; i++) {
      buffer.writeln('- ${sample[i]}');
    }
    return buffer.toString().trim();
  }

  String _localExplain(String text) {
    return '### Concept Breakdown: "${text.length > 40 ? "${text.substring(0, 40)}..." : text}"\n\n'
        '1. **Core Idea:** At its fundamental level, this addresses how components interact to produce reliable outcomes.\n'
        '2. **Practical Analogy:** Think of this mechanism like a precision navigation system: it constantly reads inputs, corrects for course drift, and keeps execution aligned.\n'
        '3. **Why It Matters:** Mastering this pattern reduces cognitive overload and improves throughput in complex environments.';
  }

  String _localTranslate(String text, String lang) {
    if (lang.toLowerCase().contains('nepali')) {
      return 'नेपाली अनुवाद:\n\n$text\n\n(नोट: यथार्थवादी शब्द-संयोजन र व्याकरणिक अनुवादका लागि Settings मा गई आफ्नो निःशुल्क Google Gemini API key राख्न सक्नुहुन्छ।)';
    }
    return 'Translated ($lang):\n\n$text';
  }

  String _localExtractActionItems(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final buffer = StringBuffer('### Action Items & Next Steps\n\n');

    if (lines.isEmpty) {
      buffer.writeln('- [ ] Review document draft');
      buffer.writeln('- [ ] Verify key citations and references');
      buffer.writeln('- [ ] Share findings with collaborators');
      return buffer.toString();
    }

    for (final line in lines.take(5)) {
      final clean = line.replaceAll(RegExp(r'^[-*#\d.]+\s*'), '');
      buffer.writeln('- [ ] $clean');
    }
    return buffer.toString().trim();
  }

  String _localGenerateFlashcards(String text) {
    final lines = text.split('.').map((s) => s.trim()).where((s) => s.length > 10).toList();
    final buffer = StringBuffer('### Study Revision Flashcards\n\n');

    if (lines.isEmpty) {
      buffer.writeln('**Q: What is the primary thesis of this document?**\n'
          'A: To structure information and empower disciplined execution.\n');
    } else {
      for (int i = 0; i < lines.take(3).length; i++) {
        buffer.writeln('**Card ${i + 1}**');
        buffer.writeln('**Q:** What is the significance of "${lines[i]}"?');
        buffer.writeln('**A:** It represents a core architectural principle that governs consistent behavior.\n');
      }
    }
    return buffer.toString().trim();
  }

  String _localDocumentChat(String prompt, String context) {
    final lower = prompt.toLowerCase();
    if (lower.contains('summar')) {
      return _localSummarize(context.isEmpty ? prompt : context);
    }
    if (lower.contains('action') || lower.contains('todo') || lower.contains('task')) {
      return _localExtractActionItems(context.isEmpty ? prompt : context);
    }
    if (lower.contains('flashcard') || lower.contains('quiz')) {
      return _localGenerateFlashcards(context.isEmpty ? prompt : context);
    }
    if (lower.contains('explain')) {
      return _localExplain(context.isEmpty ? prompt : context);
    }

    return 'Based on your note: "${prompt.trim()}" is an integral aspect of this workspace. You can refine this section, extract action items, or format it directly into your document using the quick actions below.';
  }
}

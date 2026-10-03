import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final voiceToTextServiceProvider = Provider<VoiceToTextService>((ref) {
  return VoiceToTextService();
});

class VoiceToTextService {
  Process? _activeProcess;
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Starts listening for speech on Windows using System.Speech.Recognition
  /// or triggers Windows Dictation. Returns a stream or completion callback with transcribed text.
  Future<String?> listenOnce({Duration timeout = const Duration(seconds: 7)}) async {
    if (!Platform.isWindows) return null;
    if (_isListening) {
      stopListening();
      return null;
    }

    _isListening = true;

    try {
      // PowerShell script using System.Speech.Recognition
      const script = r'''
Add-Type -AssemblyName System.Speech
try {
  $engine = New-Object System.Speech.Recognition.SpeechRecognitionEngine
  $engine.SetInputToDefaultAudioDevice()
  $grammar = New-Object System.Speech.Recognition.DictationGrammar
  $engine.LoadGrammar($grammar)
  $result = $engine.Recognize([TimeSpan]::FromSeconds(6))
  if ($result -and $result.Text) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::Out.Write($result.Text)
  }
} catch {
  # Audio device unavailable or no input
}
''';

      final processFuture = Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', script],
      ).timeout(timeout, onTimeout: () {
        return ProcessResult(0, -1, '', 'timeout');
      });

      final res = await processFuture;
      _isListening = false;

      if (res.exitCode == 0) {
        final text = res.stdout.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    } catch (e) {
      debugPrint('Voice recognition error: $e');
    } finally {
      _isListening = false;
    }

    return null;
  }

  void stopListening() {
    _isListening = false;
    try {
      _activeProcess?.kill();
    } catch (_) {}
    _activeProcess = null;
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:uuid/uuid.dart';

import '../../data/providers/data_providers.dart';
import '../../domain/models/note.dart';
import '../../domain/models/tag.dart';

const _uuid = Uuid();

class NoteEditorState {
  final Note note;
  final EditorState editorState;
  final int wordCount;
  final int charCount;
  final int readingTimeMinutes;
  final bool isSaving;
  final DateTime? lastSavedAt;
  
  NoteEditorState({
    required this.note,
    required this.editorState,
    this.wordCount = 0,
    this.charCount = 0,
    this.readingTimeMinutes = 1,
    this.isSaving = false,
    this.lastSavedAt,
  });

  NoteEditorState copyWith({
    Note? note,
    EditorState? editorState,
    int? wordCount,
    int? charCount,
    int? readingTimeMinutes,
    bool? isSaving,
    DateTime? lastSavedAt,
  }) {
    return NoteEditorState(
      note: note ?? this.note,
      editorState: editorState ?? this.editorState,
      wordCount: wordCount ?? this.wordCount,
      charCount: charCount ?? this.charCount,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      isSaving: isSaving ?? this.isSaving,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }
}

class NoteEditorController extends AutoDisposeFamilyAsyncNotifier<NoteEditorState, String> {
  Timer? _debounceTimer;
  StreamSubscription<dynamic>? _docSubscription;
  String _currentTitle = '';

  @override
  Future<NoteEditorState> build(String arg) async {
    final noteId = arg;
    final repo = ref.watch(noteRepositoryProvider);
    
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _docSubscription?.cancel();
    });

    Note note;
    EditorState editorState;

    if (noteId == 'new') {
      note = Note(
        id: _uuid.v4(),
        title: '',
        preview: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      editorState = EditorState.blank();
    } else {
      final existingNote = await repo.getNoteById(noteId);
      if (existingNote == null) {
        throw Exception("Note not found: $noteId");
      }
      note = existingNote;

      if (note.content.isNotEmpty) {
        try {
          final jsonMap = jsonDecode(note.content) as Map<String, dynamic>;
          editorState = EditorState(document: Document.fromJson(jsonMap));
        } catch (_) {
          editorState = EditorState.blank();
        }
      } else {
        editorState = EditorState.blank();
      }
    }

    _currentTitle = note.title;

    // Listen to document transactions and cancel old subscription
    _docSubscription?.cancel();
    _docSubscription = editorState.transactionStream.listen((_) {
      onDocumentChanged();
    });

    final (wordCount, charCount, readingTime) = _calculateMetrics(editorState);

    return NoteEditorState(
      note: note,
      editorState: editorState,
      wordCount: wordCount,
      charCount: charCount,
      readingTimeMinutes: readingTime,
      isSaving: false,
      lastSavedAt: note.updatedAt,
    );
  }

  (int, int, int) _calculateMetrics(EditorState editorState) {
    int totalChars = 0;
    int totalWords = 0;

    for (final node in editorState.document.root.children) {
      if (node.delta != null) {
        final text = node.delta!.toPlainText().trim();
        if (text.isNotEmpty) {
          totalChars += text.length;
          final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
          totalWords += words.length;
        }
      }
    }

    final readingTime = (totalWords / 200).ceil().clamp(1, 9999);
    return (totalWords, totalChars, readingTime);
  }

  void updateTitle(String newTitle) {
    _currentTitle = newTitle;
    if (state.hasValue) {
      final current = state.value!;
      state = AsyncData(current.copyWith(
        note: current.note.copyWith(title: newTitle),
        isSaving: true,
      ));
    }
    _scheduleSave();
  }
  
  void onDocumentChanged() {
    if (state.hasValue) {
      final current = state.value!;
      final (words, chars, readingTime) = _calculateMetrics(current.editorState);
      state = AsyncData(current.copyWith(
        wordCount: words,
        charCount: chars,
        readingTimeMinutes: readingTime,
        isSaving: true,
      ));
    }
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      saveImmediately();
    });
  }

  Future<void> saveImmediately() async {
    _debounceTimer?.cancel();
    if (!state.hasValue) return;
    final currentState = state.value!;
    
    // Extract preview text
    String text = '';
    for (final node in currentState.editorState.document.root.children) {
      if (node.delta != null) {
        text += '${node.delta!.toPlainText()} ';
      }
    }
    
    final preview = text.length > 120 ? '${text.substring(0, 120)}...' : text;
    final documentJson = jsonEncode(currentState.editorState.document.toJson());
    final now = DateTime.now();
    
    final noteToSave = currentState.note.copyWith(
      title: _currentTitle,
      preview: preview.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim(),
      content: documentJson,
      updatedAt: now,
    );
    
    final repo = ref.read(noteRepositoryProvider);
    await repo.saveNote(noteToSave);

    if (state.hasValue) {
      state = AsyncData(currentState.copyWith(
        note: noteToSave,
        isSaving: false,
        lastSavedAt: now,
      ));
    }
  }

  Future<void> addTag(Tag tag) async {
    if (!state.hasValue) return;
    final current = state.value!;
    if (current.note.tags.any((t) => t.id == tag.id)) return;

    final repo = ref.read(noteRepositoryProvider);
    await repo.addTagToNote(current.note.id, tag.id);

    final updatedTags = [...current.note.tags, tag];
    final updatedNote = current.note.copyWith(tags: updatedTags);
    state = AsyncData(current.copyWith(note: updatedNote));
  }

  Future<void> removeTag(String tagId) async {
    if (!state.hasValue) return;
    final current = state.value!;

    final repo = ref.read(noteRepositoryProvider);
    await repo.removeTagFromNote(current.note.id, tagId);

    final updatedTags = current.note.tags.where((t) => t.id != tagId).toList();
    final updatedNote = current.note.copyWith(tags: updatedTags);
    state = AsyncData(current.copyWith(note: updatedNote));
  }

  Future<void> toggleFavorite() async {
    if (!state.hasValue) return;
    final current = state.value!;
    final newFav = !current.note.isFavorite;

    final repo = ref.read(noteRepositoryProvider);
    await repo.toggleFavorite(current.note.id);

    state = AsyncData(current.copyWith(
      note: current.note.copyWith(isFavorite: newFav),
    ));
  }
}

final noteEditorControllerProvider = 
  AsyncNotifierProvider.autoDispose.family<NoteEditorController, NoteEditorState, String>(
    NoteEditorController.new
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/note_repository.dart';
import '../local/database/app_database.dart';
import '../repositories/local_note_repository.dart';
import '../../domain/models/note.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repository Provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalNoteRepository(db);
});

// Stream Providers for UI
final allNotesProvider = StreamProvider((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchAllNotes();
});

final inboxNotesProvider = StreamProvider((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchInboxNotes();
});

final folderNotesProvider = StreamProvider.family<List<Note>, String>((ref, folderId) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchNotesByFolder(folderId);
});

final tagNotesProvider = StreamProvider.family<List<Note>, String>((ref, tagId) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchNotesByTag(tagId);
});

final favoriteNotesProvider = StreamProvider((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchFavoriteNotes();
});

final archivedNotesProvider = StreamProvider((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchArchivedNotes();
});

final trashedNotesProvider = StreamProvider((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchTrashedNotes();
});

final searchNotesProvider = StreamProvider.family<List<Note>, String>((ref, query) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.searchNotes(query);
});

final allFoldersProvider = StreamProvider((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchAllFolders();
});

final allTagsProvider = StreamProvider((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchAllTags();
});

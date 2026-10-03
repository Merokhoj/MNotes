import '../models/note.dart';
import '../models/folder.dart';
import '../models/tag.dart';

abstract class NoteRepository {
  // Notes
  Stream<List<Note>> watchAllNotes();
  Stream<List<Note>> watchInboxNotes(); // no folder, not archived, not trashed
  Stream<List<Note>> watchNotesByFolder(String folderId);
  Stream<List<Note>> watchNotesByTag(String tagId);
  Stream<List<Note>> watchFavoriteNotes();
  Stream<List<Note>> watchArchivedNotes();
  Stream<List<Note>> watchTrashedNotes();
  Stream<List<Note>> searchNotes(String query);
  
  Future<Note?> getNoteById(String id);
  Future<void> saveNote(Note note);
  Future<void> toggleFavorite(String id);
  Future<void> moveToTrash(String id);
  Future<void> restoreFromTrash(String id);
  Future<void> deleteNotePermanently(String id);
  Future<void> moveNoteToFolder(String noteId, String? folderId);
  Future<void> batchMoveToTrash(List<String> ids);
  Future<void> batchRestoreFromTrash(List<String> ids);
  Future<void> batchDeletePermanently(List<String> ids);
  Future<void> batchMoveNoteToFolder(List<String> ids, String? folderId);
  
  // Folders
  Stream<List<Folder>> watchAllFolders();
  Future<void> saveFolder(Folder folder);
  Future<void> deleteFolder(String id);
  
  // Tags
  Stream<List<Tag>> watchAllTags();
  Future<void> saveTag(Tag tag);
  Future<void> deleteTag(String id);
  
  // Note-Tag associations
  Future<void> addTagToNote(String noteId, String tagId);
  Future<void> removeTagFromNote(String noteId, String tagId);
}

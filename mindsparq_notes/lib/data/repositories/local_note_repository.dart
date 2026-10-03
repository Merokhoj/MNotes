import 'package:drift/drift.dart';
import '../../domain/models/note.dart';
import '../../domain/models/folder.dart';
import '../../domain/models/tag.dart';
import '../../domain/repositories/note_repository.dart';
import '../local/database/app_database.dart';

class LocalNoteRepository implements NoteRepository {
  final AppDatabase _db;

  LocalNoteRepository(this._db);

  // ── Mappers ───────────────────────────────────────────────────────────────
  
  Folder _mapFolder(FolderEntry entry) {
    return Folder(
      id: entry.id,
      name: entry.name,
      colorValue: entry.colorValue,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
  
  Tag _mapTag(TagEntry entry) {
    return Tag(
      id: entry.id,
      name: entry.name,
      colorValue: entry.colorValue,
    );
  }
  
  Note _mapNote(NoteEntry entry, List<TagEntry> tagEntries) {
    return Note(
      id: entry.id,
      title: entry.title,
      preview: entry.preview,
      content: entry.content,
      folderId: entry.folderId,
      isFavorite: entry.isFavorite,
      isArchived: entry.isArchived,
      isTrashed: entry.isTrashed,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      syncedAt: entry.syncedAt,
      tags: tagEntries.map(_mapTag).toList(),
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  // ── Notes ─────────────────────────────────────────────────────────────────

  Stream<List<Note>> _watchNotesWithQuery(SimpleSelectStatement<$NotesTable, NoteEntry> query) {
    final notesStream = query.watch();
    
    return notesStream.asyncMap((noteEntries) async {
      if (noteEntries.isEmpty) return <Note>[];

      final noteIds = noteEntries.map((e) => e.id).toList();

      // Batch query: Fetch all tags for all returned notes in a single query
      final tagsQuery = _db.select(_db.tags).join([
        innerJoin(
          _db.noteTags,
          _db.noteTags.tagId.equalsExp(_db.tags.id),
        ),
      ])..where(_db.noteTags.noteId.isIn(noteIds));

      final rows = await tagsQuery.get();
      final tagsByNoteId = <String, List<TagEntry>>{};
      for (final row in rows) {
        final noteTag = row.readTable(_db.noteTags);
        final tag = row.readTable(_db.tags);
        tagsByNoteId.putIfAbsent(noteTag.noteId, () => []).add(tag);
      }

      return noteEntries.map((entry) {
        final noteTags = tagsByNoteId[entry.id] ?? const [];
        return _mapNote(entry, noteTags);
      }).toList();
    });
  }

  @override
  Stream<List<Note>> watchAllNotes() {
    final q = _db.select(_db.notes)
      ..where((t) => t.isTrashed.equals(false) & t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);
    return _watchNotesWithQuery(q);
  }

  @override
  Stream<List<Note>> watchInboxNotes() {
    final q = _db.select(_db.notes)
      ..where((t) => t.folderId.isNull() & t.isTrashed.equals(false) & t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);
    return _watchNotesWithQuery(q);
  }

  @override
  Stream<List<Note>> watchNotesByFolder(String folderId) {
    final q = _db.select(_db.notes)
      ..where((t) => t.folderId.equals(folderId) & t.isTrashed.equals(false) & t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);
    return _watchNotesWithQuery(q);
  }

  @override
  Stream<List<Note>> watchNotesByTag(String tagId) {
    final noteIdsWithTag = _db.selectOnly(_db.noteTags)
      ..addColumns([_db.noteTags.noteId])
      ..where(_db.noteTags.tagId.equals(tagId));

    final q = _db.select(_db.notes)
      ..where((t) => t.id.isInQuery(noteIdsWithTag) & t.isTrashed.equals(false) & t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);
    return _watchNotesWithQuery(q);
  }

  @override
  Stream<List<Note>> watchFavoriteNotes() {
    final q = _db.select(_db.notes)
      ..where((t) => t.isFavorite.equals(true) & t.isTrashed.equals(false) & t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);
    return _watchNotesWithQuery(q);
  }

  @override
  Stream<List<Note>> watchArchivedNotes() {
    final q = _db.select(_db.notes)
      ..where((t) => t.isArchived.equals(true) & t.isTrashed.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);
    return _watchNotesWithQuery(q);
  }

  @override
  Stream<List<Note>> watchTrashedNotes() {
    final q = _db.select(_db.notes)
      ..where((t) => t.isTrashed.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);
    return _watchNotesWithQuery(q);
  }

  @override
  Stream<List<Note>> searchNotes(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return watchAllNotes();
    }
    final pattern = '%$trimmed%';
    final q = _db.select(_db.notes)
      ..where((t) =>
          (t.title.lower().like(pattern) | t.preview.lower().like(pattern)) &
          t.isTrashed.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);
    return _watchNotesWithQuery(q);
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final entry = await (_db.select(_db.notes)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (entry == null) return null;
    
    final tagsQuery = _db.select(_db.tags).join([
      innerJoin(
        _db.noteTags,
        _db.noteTags.tagId.equalsExp(_db.tags.id),
      ),
    ])..where(_db.noteTags.noteId.equals(id));
    
    final tagsResult = await tagsQuery.get();
    final tagEntries = tagsResult.map((row) => row.readTable(_db.tags)).toList();
    
    return _mapNote(entry, tagEntries);
  }

  @override
  Future<void> saveNote(Note note) async {
    await _db.transaction(() async {
      await _db.into(_db.notes).insert(
        NotesCompanion.insert(
          id: note.id,
          title: Value(note.title),
          preview: Value(note.preview),
          content: Value(note.content),
          folderId: Value(note.folderId),
          isFavorite: Value(note.isFavorite),
          isArchived: Value(note.isArchived),
          isTrashed: Value(note.isTrashed),
          createdAt: Value(note.createdAt),
          updatedAt: Value(note.updatedAt),
          syncedAt: Value(note.syncedAt),
        ),
        mode: InsertMode.insertOrReplace,
      );
      
      // Update tags
      await (_db.delete(_db.noteTags)..where((t) => t.noteId.equals(note.id))).go();
      for (final tag in note.tags) {
        // Ensure tag exists
        await saveTag(tag);
        // Link to note
        await _db.into(_db.noteTags).insert(
          NoteTagEntry(noteId: note.id, tagId: tag.id),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final entry = await (_db.select(_db.notes)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (entry == null) return;
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isFavorite: Value(!entry.isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> moveToTrash(String id) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isTrashed: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> restoreFromTrash(String id) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isTrashed: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteNotePermanently(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.noteTags)..where((t) => t.noteId.equals(id))).go();
      await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
    });
  }

  // Alias for backward compatibility
  Future<void> deletePermanently(String id) => deleteNotePermanently(id);

  @override
  Future<void> moveNoteToFolder(String noteId, String? folderId) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(noteId))).write(
      NotesCompanion(
        folderId: Value(folderId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> batchMoveToTrash(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.notes)..where((t) => t.id.isIn(ids))).write(
      NotesCompanion(
        isTrashed: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> batchRestoreFromTrash(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.notes)..where((t) => t.id.isIn(ids))).write(
      NotesCompanion(
        isTrashed: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> batchDeletePermanently(List<String> ids) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      await (_db.delete(_db.noteTags)..where((t) => t.noteId.isIn(ids))).go();
      await (_db.delete(_db.notes)..where((t) => t.id.isIn(ids))).go();
    });
  }

  @override
  Future<void> batchMoveNoteToFolder(List<String> ids, String? folderId) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.notes)..where((t) => t.id.isIn(ids))).write(
      NotesCompanion(
        folderId: Value(folderId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── Folders ───────────────────────────────────────────────────────────────

  @override
  Stream<List<Folder>> watchAllFolders() {
    return (_db.select(_db.folders)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch().map((entries) {
      return entries.map(_mapFolder).toList();
    });
  }

  @override
  Future<void> saveFolder(Folder folder) async {
    await _db.into(_db.folders).insert(
      FoldersCompanion.insert(
        id: folder.id,
        name: folder.name,
        colorValue: Value(folder.colorValue),
        createdAt: Value(folder.createdAt),
        updatedAt: Value(folder.updatedAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> deleteFolder(String id) async {
    // Delete folder and move notes to inbox
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((t) => t.folderId.equals(id))).write(
        const NotesCompanion(folderId: Value(null)),
      );
      await (_db.delete(_db.folders)..where((t) => t.id.equals(id))).go();
    });
  }

  // ── Tags ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<Tag>> watchAllTags() {
    return (_db.select(_db.tags)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch().map((entries) {
      return entries.map(_mapTag).toList();
    });
  }

  @override
  Future<void> saveTag(Tag tag) async {
    await _db.into(_db.tags).insert(
      TagsCompanion.insert(
        id: tag.id,
        name: tag.name,
        colorValue: Value(tag.colorValue),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> deleteTag(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.noteTags)..where((t) => t.tagId.equals(id))).go();
      await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<void> addTagToNote(String noteId, String tagId) async {
    await _db.into(_db.noteTags).insert(
      NoteTagEntry(noteId: noteId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  @override
  Future<void> removeTagFromNote(String noteId, String tagId) async {
    await (_db.delete(_db.noteTags)..where((t) => t.noteId.equals(noteId) & t.tagId.equals(tagId))).go();
  }
}

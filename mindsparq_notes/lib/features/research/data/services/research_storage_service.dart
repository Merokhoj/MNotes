import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/research_metadata.dart';

final researchServiceProvider = Provider<ResearchStorageService>((ref) {
  return ResearchStorageService();
});

final researchMetadataStateProvider = StateNotifierProvider.family<ResearchMetadataNotifier, AsyncValue<ResearchMetadata>, String>((ref, noteId) {
  final service = ref.watch(researchServiceProvider);
  return ResearchMetadataNotifier(service, noteId);
});

class ResearchMetadataNotifier extends StateNotifier<AsyncValue<ResearchMetadata>> {
  final ResearchStorageService _service;
  final String noteId;

  ResearchMetadataNotifier(this._service, this.noteId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final meta = await _service.getMetadata(noteId);
      state = AsyncValue.data(meta);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMetadata(ResearchMetadata updated) async {
    state = AsyncValue.data(updated);
    await _service.saveMetadata(updated);
  }

  Future<void> toggleResearchMode() async {
    state.whenData((current) async {
      final updated = current.copyWith(isResearchMode: !current.isResearchMode);
      await updateMetadata(updated);
    });
  }
}

class ResearchStorageService {
  Future<File> _getFile(String noteId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'mindsparq', 'research'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'research_$noteId.json'));
  }

  Future<ResearchMetadata> getMetadata(String noteId) async {
    try {
      final file = await _getFile(noteId);
      if (!await file.exists()) {
        return ResearchMetadata(noteId: noteId);
      }
      final str = await file.readAsString();
      final map = jsonDecode(str) as Map<String, dynamic>;
      return ResearchMetadata.fromJson(map);
    } catch (_) {
      return ResearchMetadata(noteId: noteId);
    }
  }

  Future<void> saveMetadata(ResearchMetadata metadata) async {
    try {
      final file = await _getFile(metadata.noteId);
      final str = jsonEncode(metadata.toJson());
      await file.writeAsString(str);
    } catch (_) {}
  }
}

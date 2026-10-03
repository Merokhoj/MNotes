import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/models/note_attachment.dart';

const _uuid = Uuid();

final attachmentServiceProvider = Provider<AttachmentStorageService>((ref) {
  return AttachmentStorageService();
});

final noteAttachmentsProvider = FutureProvider.family<List<NoteAttachment>, String>((ref, noteId) async {
  final service = ref.watch(attachmentServiceProvider);
  return service.getAttachments(noteId);
});

class AttachmentStorageService {
  Future<Directory> _getAttachmentsDir(String noteId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'mindsparq', 'attachments', noteId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _getMetadataFile(String noteId) async {
    final dir = await _getAttachmentsDir(noteId);
    return File(p.join(dir.path, 'manifest.json'));
  }

  Future<List<NoteAttachment>> getAttachments(String noteId) async {
    try {
      final file = await _getMetadataFile(noteId);
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);
      return list.map((item) => NoteAttachment.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<NoteAttachment> addAttachment({
    required String noteId,
    required String sourcePath,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourcePath');
    }

    final originalName = p.basename(sourcePath);
    final ext = p.extension(sourcePath);
    final id = _uuid.v4();
    final targetDir = await _getAttachmentsDir(noteId);
    final targetPath = p.join(targetDir.path, '${id}_$originalName');

    // Copy to app attachments sandbox
    await sourceFile.copy(targetPath);
    final targetFile = File(targetPath);
    final size = await targetFile.length();

    final attachment = NoteAttachment(
      id: id,
      noteId: noteId,
      fileName: originalName,
      filePath: targetPath,
      fileType: AttachmentType.fromExtension(ext),
      fileSizeBytes: size,
      createdAt: DateTime.now(),
    );

    final current = await getAttachments(noteId);
    final updated = [...current, attachment];
    await _saveManifest(noteId, updated);

    return attachment;
  }

  Future<void> deleteAttachment(String noteId, String attachmentId) async {
    final current = await getAttachments(noteId);
    final target = current.firstWhere((a) => a.id == attachmentId, orElse: () => current.first);
    
    // Delete file
    try {
      final f = File(target.filePath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}

    final updated = current.where((a) => a.id != attachmentId).toList();
    await _saveManifest(noteId, updated);
  }

  Future<void> _saveManifest(String noteId, List<NoteAttachment> list) async {
    final file = await _getMetadataFile(noteId);
    final jsonStr = jsonEncode(list.map((a) => a.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  Future<void> openAttachment(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', filePath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath]);
    }
  }

  /// Launches the native Windows file picker dialog or returns null if canceled
  Future<String?> pickNativeFilePath({bool imagesOnly = false}) async {
    if (!Platform.isWindows) return null;

    try {
      final filter = imagesOnly
          ? 'Images (*.png;*.jpg;*.jpeg;*.webp;*.gif;*.bmp)|*.png;*.jpg;*.jpeg;*.webp;*.gif;*.bmp|All Files (*.*)|*.*'
          : 'All Files (*.*)|*.*|Documents (*.pdf;*.docx;*.txt)|*.pdf;*.docx;*.txt|Images (*.png;*.jpg;*.webp)|*.png;*.jpg;*.webp';

      final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.Filter = '$filter'
\$dialog.Title = 'Select File to Attach'
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write(\$dialog.FileName)
}
''';

      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', script],
      );

      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty && await File(path).exists()) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }
}

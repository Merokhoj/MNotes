enum AttachmentType {
  image,
  pdf,
  document,
  other;

  static AttachmentType fromExtension(String ext) {
    final lower = ext.toLowerCase().replaceAll('.', '');
    if (['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'svg'].contains(lower)) {
      return AttachmentType.image;
    }
    if (lower == 'pdf') {
      return AttachmentType.pdf;
    }
    if (['doc', 'docx', 'txt', 'rtf', 'odt', 'csv', 'xlsx', 'pptx'].contains(lower)) {
      return AttachmentType.document;
    }
    return AttachmentType.other;
  }
}

class NoteAttachment {
  final String id;
  final String noteId;
  final String fileName;
  final String filePath;
  final AttachmentType fileType;
  final int fileSizeBytes;
  final DateTime createdAt;

  const NoteAttachment({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteId': noteId,
        'fileName': fileName,
        'filePath': filePath,
        'fileType': fileType.name,
        'fileSizeBytes': fileSizeBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteAttachment.fromJson(Map<String, dynamic> json) {
    return NoteAttachment(
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileType: AttachmentType.values.firstWhere(
        (e) => e.name == json['fileType'],
        orElse: () => AttachmentType.other,
      ),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

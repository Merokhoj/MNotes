import 'package:freezed_annotation/freezed_annotation.dart';
import 'tag.dart';

part 'note.freezed.dart';

@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required String title,
    required String preview,
    required String content, // AppFlowy document JSON
    String? folderId,
    @Default([]) List<Tag> tags,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isTrashed,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? syncedAt,
  }) = _Note;
}

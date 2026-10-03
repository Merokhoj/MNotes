import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';

@freezed
class Folder with _$Folder {
  const factory Folder({
    required String id,
    required String name,
    int? colorValue,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Folder;
}

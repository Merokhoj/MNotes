import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

void main() {
  test('verify editor builders and shortcuts', () {
    expect(standardBlockComponentBuilderMap, isNotEmpty);
    expect(standardCommandShortcutEvents, isNotEmpty);
  });
}

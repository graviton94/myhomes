import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('confidence decides how a suggestion is used', () {
    expect(suggestLevel(0.95), SuggestLevel.auto);
    expect(suggestLevel(0.7), SuggestLevel.auto);
    expect(suggestLevel(0.69), SuggestLevel.chips);
    expect(suggestLevel(0.4), SuggestLevel.chips);
    expect(suggestLevel(0.39), SuggestLevel.ignore);
  });
}

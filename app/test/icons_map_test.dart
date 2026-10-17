import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/widgets/app_icons.dart';
import 'package:homefairy_core/homefairy_core.dart';

void main() {
  test('every core icon key has a drawn icon', () {
    expect(iconKeys.where((k) => !appIcons.containsKey(k) && !isPictureIcon(k)), isEmpty);
    expect(appIcons.keys.where((k) => !iconKeys.contains(k)), isEmpty);
  });
}

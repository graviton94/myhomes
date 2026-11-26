import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/widgets/app_icons.dart';
import 'package:homefairy/widgets/hf_pictos.g.dart';
import 'package:homefairy/widgets/icon_chooser.dart';
import 'package:homefairy_core/homefairy_core.dart';

void main() {
  // Every ordered pictogram has its drawing, and a plain name gets it.
  test('ordered pictograms are drawn and found by name', () {
    expect(hfPictos.keys.toSet(), pictogramNames.keys.toSet());
    expect(iconFor('p0125'), hfPictos['p0125']);
    expect(effectiveIcon(null, '김치냉장고'), isNotNull);
    expect(pictogramNames[effectiveIcon(null, '김치냉장고')!], '김치냉장고');
  });
}

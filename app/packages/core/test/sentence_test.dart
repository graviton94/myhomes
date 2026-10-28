import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  List<String> p(String s) => [for (final i in parseItemSentence(s)) '$i'];

  group('parseItemSentence', () {
    test('commas, 랑 and counts', () {
      expect(p('가위, 박스테이프랑 AA 건전지 4개, 줄자'), ['가위×1', '박스테이프×1', 'AA 건전지×4', '줄자×1']);
    });

    test('이랑 after a final consonant, 랑 after a vowel, 하고', () {
      expect(p('책이랑 고양이랑 연필하고 지우개'), ['책×1', '고양이×1', '연필×1', '지우개×1']);
    });

    test('names that only look like joiners stay whole', () {
      expect(p('사과, 과자'), ['사과×1', '과자×1']);
      expect(p('호랑'), ['호랑×1']);
    });

    test('units, ×N and native numbers', () {
      expect(p('물 2병, 마스크 x10, 휴지 세 롤, 양말 두 켤레'), ['물×2', '마스크×10', '휴지×3', '양말×2']);
    });

    test('a bare number belongs to the name', () {
      expect(p('아이폰 15, 두부'), ['아이폰 15×1', '두부×1']);
    });

    test('line breaks, 및, and English', () {
      expect(p('tape and scissors\nbattery 4 pcs 및 줄자'), ['tape×1', 'scissors×1', 'battery×4', '줄자×1']);
    });

    test('the same name twice adds up', () {
      expect(p('건전지 2개, 건전지 3개'), ['건전지×5']);
    });

    test('empty bits are dropped', () {
      expect(p(' , ,랑 '), isEmpty);
    });
  });

  group('addItemsFromSentence', () {
    late Ctx ctx;
    late HomeData d;
    late String box;

    setUp(() {
      var n = 0;
      ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 10, 28));
      final s = addSpace(const HomeData(), ctx, '거실');
      final b = addContainer(s.data, ctx, spaceId: s.value.id, name: 'TV장');
      d = addItem(b.data, ctx, containerId: b.value.id, name: 'AA 건전지', qty: 8).data;
      box = b.value.id;
    });

    test('new names are added, a known name joins its stack', () {
      final r = addItemsFromSentence(d, ctx, box, parseItemSentence('가위, aa건전지 4개'));
      final items = r.data.itemsIn(box).toList();
      expect(items.map((i) => '${i.name}×${i.qty}'), containsAll(['AA 건전지×12', '가위×1']));
      expect(items.length, 2);
      expect(r.value.length, 2);
    });

    test('recent places are the last spots things went into', () {
      final s = addSpace(d, ctx, '주방');
      final pantry = addContainer(s.data, ctx, spaceId: s.value.id, name: '팬트리');
      final after = addItem(pantry.data, ctx, containerId: pantry.value.id, name: '라면').data;
      expect(recentPlaces(after), [pantry.value.id, box]);
    });

    test('new items get a guessed icon', () {
      final r = addItemsFromSentence(d, ctx, box, parseItemSentence('가위'));
      expect(r.value.single.icon, isNotNull);
    });
  });
}

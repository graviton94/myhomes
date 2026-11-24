import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  var n = 0;
  final ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 11, 24));
  late HomeData d;
  late String fridge, tv, livingDrawer, bedDrawer, shoes, shelfEn;
  setUp(() {
    final k = addSpace(const HomeData(), ctx, '주방');
    var r = addContainer(k.data, ctx, spaceId: k.value.id, name: '냉장고');
    fridge = r.value.id;
    final l = addSpace(r.data, ctx, '거실');
    r = addContainer(l.data, ctx, spaceId: l.value.id, name: 'TV장');
    tv = r.value.id;
    r = addContainer(r.data, ctx, spaceId: l.value.id, name: '서랍');
    livingDrawer = r.value.id;
    final b = addSpace(r.data, ctx, '안방');
    r = addContainer(b.data, ctx, spaceId: b.value.id, name: '서랍');
    bedDrawer = r.value.id;
    final e = addSpace(r.data, ctx, '현관');
    r = addContainer(e.data, ctx, spaceId: e.value.id, name: '신발장');
    shoes = r.value.id;
    final h = addSpace(r.data, ctx, 'Hall');
    r = addContainer(h.data, ctx, spaceId: h.value.id, name: 'Shelf');
    shelfEn = r.value.id;
    d = r.data;
  });

  test('place first, then the things', () {
    final p = readPutSentence(d, '냉장고에 우유 2개랑 계란');
    expect(p.placeId, fridge);
    expect(p.items, [const ParsedItem('우유', 2), const ParsedItem('계란', 1)]);
  });

  test('things first, a place word and a put verb at the end', () {
    final p = readPutSentence(d, '건전지 4개 신발장 위에 뒀어');
    expect(p.placeId, shoes);
    expect(p.items, [const ParsedItem('건전지', 4)]);
  });

  test('a room name picks between spots with the same name', () {
    expect(readPutSentence(d, '안방 서랍에 여권 넣었어').placeId, bedDrawer);
    expect(readPutSentence(d, '거실 서랍에다 가위').placeId, livingDrawer);
    expect(readPutSentence(d, 'TV장 안에 리모컨').placeId, tv);
  });

  test('English: "put … in/on the …"', () {
    final p = readPutSentence(d, 'I put batteries and tape on the shelf');
    expect(p.placeId, shelfEn);
    expect(p.items.map((i) => i.name), ['batteries', 'tape']);
    expect(readPutSentence(d, 'I put 3 candles on the shelf').items, [const ParsedItem('candles', 3)]);
  });

  test('no known place: the things only', () {
    final p = readPutSentence(d, '우유 2개');
    expect(p.placeId, isNull);
    expect(p.items, [const ParsedItem('우유', 2)]);
    // A name inside a word is not a place ("서랍장" is not "서랍").
    expect(readPutSentence(d, '서랍장에 양말').placeId, isNull);
  });

  test('put sentences and questions are told apart', () {
    expect(isPutSentence('건전지 신발장에 뒀어'), isTrue);
    expect(isPutSentence('냉장고에 우유 넣었어'), isTrue);
    expect(isPutSentence('I put the keys in the drawer'), isTrue);
    expect(isPutSentence('건전지 어디 뒀어?'), isFalse);
    expect(isPutSentence('가위 어디 있어'), isFalse);
    expect(isPutSentence('where did I put the keys'), isFalse);
    expect(isPutSentence('가위'), isFalse);
  });
}

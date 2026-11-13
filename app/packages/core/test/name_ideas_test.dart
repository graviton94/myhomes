import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('before typing: the usual names for the place, minus what is there', () {
    final usual = roomStorageIdeas['living']!.$1;
    expect(nameIdeas(typed: '', usual: usual, skip: ['TV장']).take(3), ['거실장', '소파 옆', '수납장']);
  });

  test('typing searches my names first, then the usual ones, then the word list', () {
    final ideas = nameIdeas(typed: '건', mine: ['AA 건전지', '건조대'], usual: storageItemIdeas['drawer']!.$1, pool: thingWords(ko: true));
    expect(ideas.first, '건조대'); // starts with it, mine
    expect(ideas, contains('건전지')); // the usual drawer list
    expect(ideas, contains('AA 건전지')); // mine, the word is inside
  });

  test('initials find names, and nothing comes twice or equals what was typed', () {
    final ideas = nameIdeas(typed: 'ㅊㅅ', pool: thingWords(ko: true));
    expect(ideas, contains('칫솔'));
    expect(nameIdeas(typed: '우유', mine: ['우유', '우유'], usual: ['우유 ']), isEmpty);
  });

  test('the word list holds things, not rooms or furniture', () {
    final words = thingWords(ko: true);
    expect(words.length, greaterThan(500));
    expect(words, isNot(contains('거실')));
    expect(words, isNot(contains('서랍장')));
    expect(thingWords(ko: false), contains('scissors'));
  });

  test('my names: things at home count most, then history and the shopping list', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'n${n++}', now: () => DateTime(2026, 11, 13));
    final a = addSpace(const HomeData(), ctx, '거실');
    final b = addContainer(a.data, ctx, spaceId: a.value.id, name: 'TV장');
    var d = addItem(b.data, ctx, containerId: b.value.id, name: '가위').data;
    d = addToBuy(d, ctx, '두부');
    expect(myThingNames(d).first, '가위');
    expect(myThingNames(d), contains('두부'));
  });
}

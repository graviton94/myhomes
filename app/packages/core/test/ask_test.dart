import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('what the question wants, and the thing it names', () {
    final cases = {
      '우유 사야 해': (AskIntent.buy, '우유'),
      '두부 좀 사 와 줘': (AskIntent.buy, '두부'),
      '키친타월 장보기에 넣어줘': (AskIntent.buy, '키친타월'),
      '휴지 다 썼어': (AskIntent.usedUp, '휴지'),
      '건전지 떨어졌어': (AskIntent.usedUp, '건전지'),
      '건전지 몇 개 있어?': (AskIntent.howMany, '건전지'),
      '쌀 얼마나 남았어': (AskIntent.howMany, '쌀'),
      '가위 어디 있어?': (AskIntent.where, '가위'),
      '열 날 때 먹는 약': (AskIntent.where, '열 날 때 먹는 약'),
      'where is the tape': (AskIntent.where, 'tape'),
      'how many eggs are left': (AskIntent.howMany, 'eggs'),
      'we ran out of milk': (AskIntent.usedUp, 'milk'),
      'milk ran out': (AskIntent.usedUp, 'milk'),
      'need to buy rice': (AskIntent.buy, 'rice'),
      'add tofu to the shopping list': (AskIntent.buy, 'tofu'),
      'how many batteries do we have?': (AskIntent.howMany, 'batteries'),
      '우유': (AskIntent.where, '우유'),
    };
    for (final e in cases.entries) {
      final a = askOf(e.key);
      expect((a.intent, a.term), e.value, reason: e.key);
    }
  });
}

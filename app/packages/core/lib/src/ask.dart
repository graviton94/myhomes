/// The search box as a question to the fairy: what someone wants ("우유 사야
/// 해", "휴지 다 썼어", "건전지 몇 개 있어?") and which thing they mean. The
/// intent is read here by rules; only which thing a description means ("열 날
/// 때 먹는 약") goes to the decision model.
library;

/// What a question asks the fairy to do about a thing.
enum AskIntent {
  /// Where is it? (the default)
  where,

  /// How many are there?
  howMany,

  /// Put it on the shopping list.
  buy,

  /// It ran out: record it as used up.
  usedUp,
}

final _intents = <AskIntent, RegExp>{
  AskIntent.buy: RegExp(
    r'(\s*(을|를|도|좀))?\s*(사야\s*(해|돼|겠다|함|지|하는데)?|사\s*와\s*(줘|야)?|사다\s*(줘|주세요)?|살\s*것|장보기(에)?\s*(넣어|추가|적어)\s*(줘|주세요)?|buy|need to buy|add\s+(it\s+)?to\s+(the\s+)?shopping(\s+list)?|get\s+more)\s*[.!?]*$',
  ),
  AskIntent.usedUp: RegExp(
    r'(\s*(을|를|이|가|도))?\s*(다\s*(썼어|썼다|썼음|씀|먹었어|먹었다|먹음|떨어졌어)|떨어졌어|떨어짐|없어|없어졌어|used\s+up|ran\s+out|is\s+finished|finished)\s*[.!?]*$',
  ),
  AskIntent.howMany: RegExp(
    r'(\s*(은|는|이|가))?\s*(몇\s*(개|통|병|봉|팩|장|롤)\s*(있어|남았어|있지|남았지|있나요|남았나요)?|얼마나\s*(있어|남았어|있지|남았지)|how\s+many(\s+(is|are)\s+(left|there))?|how\s+much)\s*[.!?]*$',
  ),
};

/// English puts the wish first ("how many eggs", "buy rice").
final _leading = <AskIntent, RegExp>{
  AskIntent.howMany: RegExp(r'^how\s+(many|much)\s+(of\s+)?(the\s+|our\s+|my\s+)?'),
  AskIntent.buy: RegExp(r'^((we\s+|i\s+)?need\s+to\s+buy|buy|get\s+more|add)\s+(some\s+)?(the\s+)?'),
  AskIntent.usedUp: RegExp(r'^(we\s+|i\s+)?(ran\s+out\s+of|used\s+up|finished)\s+(the\s+|our\s+|my\s+)?'),
};

final _tails = RegExp(r'\s+((are|is)\s+(left|there)|do\s+we\s+have|left|to\s+(the\s+)?shopping(\s+list)?)\s*[.!?]*$');

final _where = [
  RegExp(r"^(where(\s+is|\s+are|’s|'s)?|find|look\s+for)\s+(the\s+|my\s+)?"),
  RegExp(r'\s*(은|는|이|가)?\s*(어디\s*(에)?\s*(있어|있지|있나요|있어요|뒀더라|뒀어|있니)?|어딨어|찾아\s*(줘|주세요)?)\s*[.!?]*$'),
  RegExp(r'[?？!.]+$'),
];

/// The intent of [question] and the words that name the thing.
({AskIntent intent, String term}) askOf(String question) {
  var q = question.trim().toLowerCase();
  var intent = AskIntent.where;
  for (final e in _leading.entries) {
    if (e.value.hasMatch(q)) {
      intent = e.key;
      q = q.replaceAll(e.value, '').replaceAll(_tails, '');
      break;
    }
  }
  if (intent == AskIntent.where) {
    for (final e in _intents.entries) {
      if (e.value.hasMatch(q)) {
        intent = e.key;
        q = q.replaceAll(e.value, '');
        break;
      }
    }
  }
  for (final p in _where) {
    q = q.replaceAll(p, '');
  }
  return (intent: intent, term: q.trim());
}

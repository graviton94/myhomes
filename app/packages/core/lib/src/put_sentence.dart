/// Putting things away in one sentence, by voice or keyboard (user request):
/// "냉장고에 우유 2개랑 계란 넣었어" is where (the fridge) and what (milk ×2,
/// eggs). The place is matched against the home's own storage names, so it
/// is read on the phone; nothing goes to a model.
library;

import 'model.dart';
import 'sentence.dart';

/// Where and what, read from one sentence.
class PutSentence {
  const PutSentence({required this.placeId, required this.items, required this.rest});

  /// The storage spot named in the sentence; null when none was.
  final String? placeId;
  final List<ParsedItem> items;

  /// The sentence without the place and the verb: what the items came from.
  final String rest;
}

// "…에 넣었어", "…에 뒀어", "…에 넣어 둠": put words at the end.
final _koPut = RegExp(
  r'\s*(을|를|도)?\s*(넣었어요?|넣었다|넣었음|넣음|넣어\s*(뒀어요?|놨어요?|둠|줘|주세요)?|뒀어요?|두었어요?|둠|놨어요?|놓았어요?|놔\s*(뒀어요?|둠)|보관했어요?|보관함|정리했어요?|챙겨\s*(뒀어요?|놨어요?))\s*[.!~]*$',
);
final _enPut = RegExp(r'^(i\s+)?(just\s+)?(put|placed|stored|left|added|keep|kept)\s+', caseSensitive: false);

// After a place name: "냉장고에", "TV장 위에", "서랍 안에다".
const _koAfter = ['안에다가', '안에다', '안에', '위에다', '위에', '밑에', '아래에', '속에', '옆에', '뒤에', '앞에', '에다가', '에다', '에'];
final _enBefore = RegExp(r'(?:^|\s)(in|on|into|onto|under|inside|in\s+the|on\s+the|into\s+the|under\s+the|inside\s+the|to\s+the|at\s+the)\s+$', caseSensitive: false);

/// Whether [text] says something was put away ("…에 넣었어", "I put … in …"),
/// rather than asking where it is.
bool isPutSentence(String text) {
  final t = text.trim();
  if (t.isEmpty || t.endsWith('?') || RegExp(r'어디|where', caseSensitive: false).hasMatch(t)) return false;
  return _koPut.hasMatch(t) || _enPut.hasMatch(t);
}

/// Reads where and what from [text]. The longest storage name in the home
/// that is followed by a place word ("냉장고에") or led by one ("in the
/// fridge") is the place; a room name before it ("거실 서랍에") picks between
/// spots with the same name.
PutSentence readPutSentence(HomeData d, String text) {
  var t = text.trim().replaceFirst(_koPut, '').replaceFirst(_enPut, '').trim();
  final lower = t.toLowerCase();
  ({int start, int end, String id, int score})? best;
  for (final c in d.containers) {
    final room = d.space(c.spaceId)?.name;
    final names = <(String, int)>[
      (c.name, 0),
      if (room != null) ('$room ${c.name}', 1),
      if (room != null) ('${room}의 ${c.name}', 1),
      if (room != null) ('$room ${c.name}'.replaceAll(' ', ''), 1),
    ];
    for (final (name, bonus) in names) {
      final n = name.toLowerCase();
      if (n.isEmpty) continue;
      var from = 0;
      while (true) {
        final at = lower.indexOf(n, from);
        if (at < 0) break;
        from = at + 1;
        if (at > 0 && !RegExp(r'\s').hasMatch(lower[at - 1]) && !_enBefore.hasMatch(lower.substring(0, at))) continue;
        var end = at + n.length;
        final after = lower.substring(end).replaceFirst(RegExp(r'^\s*'), '');
        final word = _koAfter.where(after.startsWith).firstOrNull;
        final led = _enBefore.firstMatch(lower.substring(0, at));
        if (word == null && led == null) continue;
        var start = at;
        if (word != null) end = lower.length - after.length + word.length;
        if (led != null) start = led.start;
        final score = n.length * 2 + bonus;
        if (best == null || score > best.score) best = (start: start, end: end, id: c.id, score: score);
      }
    }
  }
  if (best != null) t = '${t.substring(0, best.start)} ${t.substring(best.end)}';
  final rest = t.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'^[\s,]+|[\s,.!]+$'), '').trim();
  return PutSentence(placeId: best?.id, items: parseItemSentence(rest), rest: rest);
}

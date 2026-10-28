/// "One place, one sentence": turns "가위, 박스테이프랑 AA 건전지 4개" into
/// names with quantities, and adds them to a storage spot in one change.
library;

import 'icons.dart';
import 'model.dart';
import 'ops.dart';

class ParsedItem {
  const ParsedItem(this.name, this.qty);

  final String name;
  final int qty;

  @override
  bool operator ==(Object other) => other is ParsedItem && other.name == name && other.qty == qty;

  @override
  int get hashCode => Object.hash(name, qty);

  @override
  String toString() => '$name×$qty';
}

// Commas, list marks and line breaks always separate names.
final _separators = RegExp(r'[,，、;\n]+|\s+(?:및|그리고|and|&|\+)\s+', caseSensitive: false);

// Counting words: "4개", "AA 건전지 2팩". A bare number ("아이폰 15") stays part of the name.
const _units = '개|병|팩|장|권|박스|상자|봉|봉지|통|켤레|벌|쌍|롤|캔|알|줄|묶음|세트|자루|ea|pcs|pc';
final _digitQty = RegExp('\\s*(\\d{1,4})\\s*(?:$_units)\$', caseSensitive: false);
final _timesQty = RegExp(r'\s*[x×*]\s*(\d{1,4})$', caseSensitive: false);
final _nativeQty = RegExp('\\s+(한|하나|두|둘|세|셋|네|넷|다섯|여섯|일곱|여덟|아홉|열)\\s*(?:$_units)\$');
const _native = {'한': 1, '하나': 1, '두': 2, '둘': 2, '세': 3, '셋': 3, '네': 4, '넷': 4, '다섯': 5, '여섯': 6, '일곱': 7, '여덟': 8, '아홉': 9, '열': 10};

bool _hasFinalConsonant(String ch) {
  final c = ch.codeUnitAt(0);
  return c >= 0xAC00 && c <= 0xD7A3 && (c - 0xAC00) % 28 != 0;
}

/// Splits a word ending in "랑" / "이랑" / "하고" into the name part, or
/// returns null when the word is not joined that way.
// Common names that end in 이, so "고양이랑" is 고양이 + 랑, not 고양 + 이랑.
const _endsInI = ['고양이', '종이', '걸이', '깎이', '아이', '오이', '놀이', '먹이', '살이', '받이', '털이', '꽂이', '덮개이'];

String? _stripJoiner(String word) {
  if (word.length > 2 && word.endsWith('하고')) return word.substring(0, word.length - 2);
  final base = word.length > 1 ? word.substring(0, word.length - 1) : '';
  if (word.length > 2 &&
      word.endsWith('이랑') &&
      _hasFinalConsonant(word[word.length - 3]) &&
      !_endsInI.any(base.endsWith)) {
    return word.substring(0, word.length - 2); // 책이랑 -> 책
  }
  if (word.length > 1 && word.endsWith('랑')) return word.substring(0, word.length - 1); // 고양이랑 -> 고양이
  return null;
}

ParsedItem? _item(String raw) {
  var name = raw.trim();
  var qty = 1;
  for (final re in [_digitQty, _timesQty]) {
    final m = re.firstMatch(name);
    if (m != null && m.start > 0) {
      qty = int.parse(m.group(1)!);
      name = name.substring(0, m.start);
      break;
    }
  }
  final n = _nativeQty.firstMatch(name);
  if (qty == 1 && n != null && n.start > 0) {
    qty = _native[n.group(1)]!;
    name = name.substring(0, n.start);
  }
  name = name.trim();
  if (name.isEmpty) return null;
  return ParsedItem(name, qty < 1 ? 1 : qty);
}

/// Names and quantities in [text], in order. The same name twice is counted once.
List<ParsedItem> parseItemSentence(String text) {
  final parts = <String>[];
  final segments = text.split(_separators);
  for (final (si, segment) in segments.indexed) {
    var current = <String>[];
    final words = segment.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    for (final (wi, word) in words.indexed) {
      if (const {'랑', '이랑', '하고'}.contains(word)) {
        if (current.isNotEmpty) parts.add(current.join(' '));
        current = [];
        continue;
      }
      // Only a word with something after it can be "X랑": a lone "호랑" stays.
      final last = wi == words.length - 1 && si == segments.length - 1;
      final head = last ? null : _stripJoiner(word);
      if (head == null) {
        current.add(word);
      } else {
        parts.add([...current, head].join(' '));
        current = [];
      }
    }
    if (current.isNotEmpty) parts.add(current.join(' '));
  }
  final out = <String, ParsedItem>{};
  for (final p in parts) {
    final item = _item(p);
    if (item == null) continue;
    final key = _key(item.name);
    final had = out[key];
    out[key] = had == null ? item : ParsedItem(had.name, had.qty + item.qty);
  }
  return out.values.toList();
}

String _key(String name) => name.toLowerCase().replaceAll(RegExp(r'\s+'), '');

/// The undated item in [containerId] with [name], which a new one joins.
Item? sameNameIn(HomeData d, String containerId, String name) =>
    d.itemsIn(containerId).where((i) => i.expiresOn == null && _key(i.name) == _key(name)).firstOrNull;

/// Adds every parsed item to [containerId] as one change (one undo). Names
/// already there without a date add to that stack; new names get a category
/// and icon from [guess] (defaults to the on-phone rules).
Result<List<Item>> addItemsFromSentence(
  HomeData d,
  Ctx ctx,
  String containerId,
  List<ParsedItem> items, {
  ({ItemCategory category, String? icon}) Function(String name)? guess,
}) {
  var data = d;
  final out = <Item>[];
  for (final p in items) {
    final have = sameNameIn(data, containerId, p.name);
    if (have != null) {
      data = adjustQty(data, ctx, have.id, p.qty);
      out.add(data.item(have.id)!);
      continue;
    }
    final g = guess?.call(p.name) ?? (category: guessCategory(p.name) ?? ItemCategory.other, icon: iconsFromName(p.name).firstOrNull);
    final r = addItem(data, ctx, containerId: containerId, name: p.name, qty: p.qty, category: g.category, icon: g.icon);
    data = r.data;
    out.add(r.value);
  }
  return Result(data, out);
}

/// Storage spots things were last put into, newest first, for the place chips.
List<String> recentPlaces(HomeData d, {int limit = 3}) {
  final out = <String>[];
  for (final e in d.log) {
    final id = e.toContainerId;
    if (e.type != LogType.add || id == null || out.contains(id) || d.container(id) == null) continue;
    out.add(id);
    if (out.length == limit) break;
  }
  return out;
}

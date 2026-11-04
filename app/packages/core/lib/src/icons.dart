/// Icon keys for spaces, storage spots and items, and suggestions from a name.
///
/// Keys are plain strings so the data file stays free of Flutter; the app maps
/// each key to a drawn icon.
library;

import 'model.dart';
import 'words.dart';

/// Picker groups in display order. Every key appears exactly once.
const Map<String, List<String>> iconGroups = {
  'rooms': [
    'home', 'living', 'kitchen', 'dining', 'bedroom', 'kids', 'bathroom', 'laundry', 'entrance', //
    'balcony', 'study', 'office', 'storeroom', 'garage', 'garden', 'car', 'school', 'store', 'family_home',
  ],
  'furniture': [
    'drawer', 'shelf', 'cabinet', 'wardrobe', 'fridge', 'freezer', 'box', 'basket', 'bag', 'desk', //
    'table', 'bed', 'tv', 'safe', 'sink', 'first_aid_box',
  ],
  'food': [
    'drink', 'water', 'coffee', 'tea', 'wine', 'beer', 'liquor', 'egg', 'rice', 'noodles', 'bread', //
    'cookie', 'cake', 'icecream', 'candy', 'chocolate', 'snack', 'vegetable', 'fruit', 'fish', 'meat', //
    'cheese', 'soup', 'can', 'sauce', 'oil', 'spice',
  ],
  'household': [
    'cleaning', 'soap', 'sanitizer', 'tissue', 'laundry_soap', 'trash', 'wrap', 'toothbrush', 'toothpaste', //
    'cosmetics', 'linens', 'hanger', 'sewing', 'vacuum', 'mosquito', 'dehumidifier', 'lightbulb', //
    'battery', 'plug', 'cable', 'umbrella', 'shower', 'fan', 'candle',
  ],
  'tools': [
    'scissors', 'tape', 'ruler', 'wrench', 'screw', 'hammer', 'toolbox', 'saw', 'paint', 'ladder', //
    'flashlight', 'key', 'lock', 'pin', 'plumbing', 'electric',
  ],
  'health': ['pill', 'syrup', 'bandage', 'ointment', 'eye_drops', 'syringe', 'thermometer', 'mask', 'vitamin', 'heart'],
  'clothes': [
    'top', 'tshirt', 'shirt', 'pants', 'shorts', 'underwear', 'dress', 'skirt', 'socks', 'coat', //
    'shoes', 'hat', 'glasses', 'handbag', 'backpack', 'watch', 'jewelry', 'iron',
  ],
  'devices': [
    'phone', 'tablet', 'laptop', 'monitor', 'headphones', 'camera', 'game', 'speaker', 'remote', //
    'printer', 'router', 'keyboard', 'mouse', 'usb', 'memory_card',
  ],
  'papers': ['document', 'book', 'notebook', 'pen', 'mail', 'photo', 'receipt', 'id_card', 'card', 'money', 'ticket', 'gift'],
  'hobby': [
    'ball', 'tennis', 'golf', 'fitness', 'bike', 'tent', 'fishing', 'music', 'art', 'plant', //
    'suitcase', 'beach', 'christmas', 'party', 'star', 'heart_fav', 'other',
  ],
  'kids': ['baby', 'diaper', 'baby_bottle', 'stroller', 'toy', 'puzzle'],
  'pets': ['pet', 'dog', 'cat', 'hamster', 'bird', 'aquarium', 'pet_food'],
  'family': ['dad', 'mom', 'boy', 'girl', 'grandpa', 'grandma', 'family', 'person'],
};

/// Every icon key, in picker order.
final List<String> iconKeys = [for (final g in iconGroups.values) ...g];

/// What a name is for, so suggestions start from the right kind of icon.
enum IconKind { space, outside, storage, item }

/// One dictionary term, compiled from [iconTerms].
class _Term {
  _Term(this.text, this.keys, {required this.whole, this.category});
  final String text;
  final List<String> keys;

  /// Must be a whole word (`=` terms).
  final bool whole;

  /// Overrides the category of the first key ("보조배터리" is a device).
  final ItemCategory? category;

  bool get _ascii => text.codeUnits.every((c) => c < 0x80);
}

final List<_Term> _terms = () {
  final byText = <String, _Term>{};
  for (final e in iconTerms.entries) {
    for (var raw in e.value.split('|')) {
      raw = raw.trim().toLowerCase();
      if (raw.isEmpty) continue;
      ItemCategory? cat;
      final at = raw.indexOf('@');
      if (at > 0) {
        cat = ItemCategory.values.byName(raw.substring(at + 1));
        raw = raw.substring(0, at);
      }
      final whole = raw.startsWith('=');
      final text = whole ? raw.substring(1) : raw;
      final t = byText[text];
      if (t == null) {
        byText[text] = _Term(text, [e.key], whole: whole, category: cat);
      } else if (!t.keys.contains(e.key)) {
        t.keys.add(e.key);
      }
    }
  }
  return byText.values.toList()..sort((a, b) => b.text.length.compareTo(a.text.length));
}();

bool _isLetter(int c) =>
    (c >= 0x61 && c <= 0x7a) || (c >= 0x41 && c <= 0x5a) || (c >= 0xac00 && c <= 0xd7a3) || (c >= 0x3131 && c <= 0x318e);

/// Where [t] may match in [n] at [i].
bool _fits(String n, _Term t, int i) {
  final end = i + t.text.length;
  final before = i == 0 || !_isLetter(n.codeUnitAt(i - 1));
  final after = end == n.length || !_isLetter(n.codeUnitAt(end));
  if (t.whole) return before && after;
  if (t._ascii) return before;
  // One Korean letter: only at the end of a word ("감기약", not "약속").
  if (t.text.length == 1) return after;
  return true;
}

/// Dictionary hits in [name]: longest terms claim their letters first, then
/// the hits are ordered right to left, since a Korean name ends with what the
/// thing is ("냉동 새우" is shrimp, "고양이 모래" is litter).
List<({_Term term, int start})> _hits(String name) {
  final n = name.trim().toLowerCase();
  if (n.isEmpty) return const [];
  final taken = List<bool>.filled(n.length, false);
  final hits = <({_Term term, int start})>[];
  for (final t in _terms) {
    var i = n.indexOf(t.text);
    while (i >= 0) {
      final end = i + t.text.length;
      if (_fits(n, t, i) && !taken.sublist(i, end).contains(true)) {
        for (var k = i; k < end; k++) {
          taken[k] = true;
        }
        hits.add((term: t, start: i));
      }
      i = n.indexOf(t.text, i + 1);
    }
  }
  hits.sort((a, b) {
    final byEnd = (b.start + b.term.text.length).compareTo(a.start + a.term.text.length);
    return byEnd != 0 ? byEnd : b.term.text.length.compareTo(a.term.text.length);
  });
  return hits;
}

const Map<IconKind, List<String>> _defaults = {
  IconKind.space: ['home', 'living', 'kitchen', 'bedroom', 'bathroom', 'entrance'],
  IconKind.outside: ['car', 'office', 'person', 'family_home', 'school', 'suitcase'],
  IconKind.storage: ['drawer', 'shelf', 'box', 'cabinet', 'basket', 'wardrobe'],
  IconKind.item: [],
};

const Map<ItemCategory, List<String>> _categoryDefaults = {
  ItemCategory.food: ['drink', 'egg', 'can', 'snack', 'vegetable', 'rice'],
  ItemCategory.household: ['cleaning', 'tissue', 'battery', 'lightbulb', 'soap', 'trash'],
  ItemCategory.tools: ['toolbox', 'scissors', 'tape', 'wrench', 'flashlight', 'key'],
  ItemCategory.medicine: ['pill', 'bandage', 'syrup', 'thermometer', 'mask', 'vitamin'],
  ItemCategory.clothes: ['tshirt', 'pants', 'coat', 'socks', 'shoes', 'hat'],
  ItemCategory.electronics: ['phone', 'laptop', 'tablet', 'headphones', 'camera', 'game'],
  ItemCategory.papers: ['document', 'book', 'notebook', 'pen', 'card', 'money'],
  ItemCategory.hobby: ['ball', 'fitness', 'bike', 'tent', 'music', 'art'],
  ItemCategory.kids: ['toy', 'puzzle', 'baby', 'diaper', 'baby_bottle', 'stroller'],
  ItemCategory.pets: ['pet', 'dog', 'cat', 'pet_food', 'bird', 'aquarium'],
  ItemCategory.other: ['box', 'gift', 'bag', 'photo', 'star', 'other'],
};

/// Icons whose words appear in [name], best match first. Empty when nothing
/// in the name is recognised.
List<String> iconsFromName(String name) {
  final out = <String>[];
  for (final h in _hits(name)) {
    for (final k in h.term.keys) {
      if (!out.contains(k)) out.add(k);
    }
  }
  return out;
}

/// Up to [limit] icons to offer for [name]: name matches first, then sensible
/// defaults for the kind (and the item's category).
List<String> suggestIcons(String name, IconKind kind, {ItemCategory? category, int limit = 6}) {
  final out = [...iconsFromName(name)];
  final fill = [...?_defaults[kind], if (kind == IconKind.item) ...?_categoryDefaults[category ?? ItemCategory.other]];
  for (final k in fill) {
    if (out.length >= limit) break;
    if (!out.contains(k)) out.add(k);
  }
  return out.take(limit).toList();
}

const Map<String, ItemCategory> _groupCategory = {
  'food': ItemCategory.food,
  'household': ItemCategory.household,
  'tools': ItemCategory.tools,
  'health': ItemCategory.medicine,
  'clothes': ItemCategory.clothes,
  'devices': ItemCategory.electronics,
  'papers': ItemCategory.papers,
  'hobby': ItemCategory.hobby,
  'kids': ItemCategory.kids,
  'pets': ItemCategory.pets,
};

/// Keys whose category differs from their picker group.
const Map<String, ItemCategory> _keyCategory = {
  'first_aid_box': ItemCategory.medicine,
  'tv': ItemCategory.electronics,
  'iron': ItemCategory.household,
  'gift': ItemCategory.other,
  'star': ItemCategory.other,
  'heart_fav': ItemCategory.other,
  'other': ItemCategory.other,
};

/// The item category an icon belongs to (food icons -> food, and so on).
ItemCategory categoryOfIcon(String key) {
  final own = _keyCategory[key];
  if (own != null) return own;
  for (final e in iconGroups.entries) {
    if (e.value.contains(key)) return _groupCategory[e.key] ?? ItemCategory.other;
  }
  return ItemCategory.other;
}

/// Best guess from the name alone, or null when no word is recognised.
ItemCategory? guessCategory(String name) {
  final hits = _hits(name);
  if (hits.isEmpty) return null;
  final t = hits.first.term;
  return t.category ?? categoryOfIcon(t.keys.first);
}

/// Icons for a search typed in the icon picker ("우산", "rain", "약"):
/// whole-word hits first, then words that start with it, then words that
/// contain it, then icon names. Empty for an empty query.
List<String> searchIcons(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final ranked = <(int, String)>[];
  for (final t in _terms) {
    final rank = t.text == q ? 0 : (t.text.startsWith(q) ? 1 : (t.text.contains(q) ? 2 : -1));
    if (rank >= 0) {
      for (final k in t.keys) {
        ranked.add((rank, k));
      }
    }
  }
  for (final k in iconKeys) {
    if (k.replaceAll('_', ' ').contains(q)) ranked.add((3, k));
  }
  // Names the dictionary knows ("냉동 새우") also count.
  for (final k in iconsFromName(q)) {
    ranked.add((0, k));
  }
  ranked.sort((a, b) => a.$1.compareTo(b.$1));
  final out = <String>[];
  for (final (_, k) in ranked) {
    if (!out.contains(k)) out.add(k);
  }
  return out;
}

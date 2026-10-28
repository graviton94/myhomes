/// Search helpers that understand Korean initial consonants (초성).
///
/// A query made only of initial consonants ("ㄱㅇ") matches names whose
/// syllables start with them ("가위"). Everything else is a case-insensitive
/// substring match, so English names work the same way.
library;

const int _syllableStart = 0xAC00;
const int _syllableEnd = 0xD7A3;

const List<String> _initials = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'];

final Set<int> _initialCodes = _initials.map((s) => s.codeUnitAt(0)).toSet();

/// Replaces each Hangul syllable with its initial consonant; other characters
/// are kept. "건전지 AA" -> "ㄱㅈㅈ AA".
String initialsOf(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= _syllableStart && rune <= _syllableEnd) {
      out.write(_initials[(rune - _syllableStart) ~/ 588]);
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

bool _isInitialsOnly(String query) {
  var hasInitial = false;
  for (final rune in query.runes) {
    if (rune == 0x20) continue;
    if (!_initialCodes.contains(rune)) return false;
    hasInitial = true;
  }
  return hasInitial;
}

String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');

/// Whether [name] matches the search [query].
bool matchesQuery(String name, String query) {
  final q = _normalize(query);
  if (q.isEmpty) return true;
  final n = _normalize(name);
  if (n.contains(q)) return true;
  if (_isInitialsOnly(q)) return initialsOf(n).contains(q);
  return false;
}

/// Word joiner: an invisible mark that forbids a line break where it sits.
const wordJoiner = '⁠';

bool _isHangul(int r) => (r >= 0xAC00 && r <= 0xD7A3) || (r >= 0x1100 && r <= 0x11FF) || (r >= 0x3130 && r <= 0x318F);

/// Lets Korean wrap only between words, as Korean is written: screen text
/// otherwise breaks between any two syllables ("있어 / 야 해요"). Joins
/// every pair of touching characters where one is Hangul; spaces still break.
String keepWords(String s) {
  final out = StringBuffer();
  int? prev;
  for (final r in s.runes) {
    if (prev != null && !_breakable(prev) && !_breakable(r) && (_isHangul(prev) || _isHangul(r))) out.write(wordJoiner);
    out.writeCharCode(r);
    prev = r;
  }
  return out.toString();
}

bool _breakable(int r) => r == 0x20 || r == 0x0A || r == 0x2060 || r == 0x200B;

/// A name as stored: trimmed, without the invisible marks [keepWords] adds
/// (screen text can be copied into names, e.g. "상자 3" or room names).
String cleanText(String s) => s.replaceAll(wordJoiner, '').trim();

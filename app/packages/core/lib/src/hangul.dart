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

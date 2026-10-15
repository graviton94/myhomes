/// MES-style location codes: space prefix, container letter + number, and an
/// optional chain of child numbers. Examples: `LIV`, `LIV-A1`, `LIV-A1-2`.
///
/// Codes are generated once and stored, so renaming a space does not change
/// the codes printed or remembered by the family.
library;

final RegExp _letters = RegExp(r'[A-Za-z]');

/// Three-letter prefix for a space. Uses the first three Latin letters of
/// [name] when it has them ("Living room" -> "LIV"); otherwise `SP` plus a
/// number ("거실" -> "SP1"). Avoids prefixes already in [taken].
String spacePrefix(String name, Set<String> taken) {
  final latin = _letters.allMatches(name).map((m) => m[0]!).join().toUpperCase();
  if (latin.length >= 3) {
    final base = latin.substring(0, 3);
    if (!taken.contains(base)) return base;
    for (var i = 2;; i++) {
      final candidate = '${base.substring(0, 2)}$i';
      if (!taken.contains(candidate)) return candidate;
    }
  }
  for (var i = 1;; i++) {
    final candidate = 'SP$i';
    if (!taken.contains(candidate)) return candidate;
  }
}

/// Code for the [index]-th (0-based) top-level container in a space:
/// A1..A9, B1..B9, ... so codes stay short and easy to say aloud.
String containerCode(String spacePrefix, int index) {
  if (index < 0) throw RangeError.value(index, 'index');
  final letter = String.fromCharCode('A'.codeUnitAt(0) + index ~/ 9);
  final number = index % 9 + 1;
  return '$spacePrefix-$letter$number';
}

/// Code for the [index]-th (0-based) child inside [parentCode]: `LIV-A1-1`.
String childCode(String parentCode, int index) {
  if (index < 0) throw RangeError.value(index, 'index');
  return '$parentCode-${index + 1}';
}

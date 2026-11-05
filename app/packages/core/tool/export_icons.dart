// Writes the icon groups to functions/icons.json so the server picks from the
// same icons the app draws.   dart run tool/export_icons.dart [--check]
import 'dart:convert';
import 'dart:io';

import 'package:homefairy_core/homefairy_core.dart';

void main(List<String> args) {
  final files = {
    File('../../../functions/icons.json'): iconGroups,
    // Names for each icon, for questions about photos ("사진에 가위가 있다").
    File('../../../functions/icon_labels.json'): {
      for (final k in iconKeys) k: {'ko': iconLabel(k), 'en': iconLabel(k, ko: false)},
    },
  };
  if (args.contains('--check')) {
    for (final e in files.entries) {
      final json = '${const JsonEncoder.withIndent('  ').convert(e.value)}\n';
      if (!e.key.existsSync() || e.key.readAsStringSync() != json) {
        stderr.writeln('${e.key.path} is out of date. Run: dart run tool/export_icons.dart');
        exit(1);
      }
    }
    stdout.writeln('functions/icons.json is up to date.');
    return;
  }
  for (final e in files.entries) {
    e.key.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(e.value)}\n');
  }
  stdout.writeln('Wrote ${iconKeys.length} icons in ${iconGroups.length} groups.');
}

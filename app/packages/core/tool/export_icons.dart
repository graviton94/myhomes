// Writes the icon groups to functions/icons.json so the server picks from the
// same icons the app draws.   dart run tool/export_icons.dart [--check]
import 'dart:convert';
import 'dart:io';

import 'package:homefairy_core/homefairy_core.dart';

void main(List<String> args) {
  final file = File('../../../functions/icons.json');
  final json = '${const JsonEncoder.withIndent('  ').convert(iconGroups)}\n';
  if (args.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != json) {
      stderr.writeln('functions/icons.json is out of date. Run: dart run tool/export_icons.dart');
      exit(1);
    }
    stdout.writeln('functions/icons.json is up to date.');
    return;
  }
  file.writeAsStringSync(json);
  stdout.writeln('Wrote ${iconKeys.length} icons in ${iconGroups.length} groups.');
}

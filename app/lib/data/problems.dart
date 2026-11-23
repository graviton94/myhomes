// Failures the app catches and carries on from (a sign-in that did not go
// through, a family change that was not saved, a purchase not given) also
// go to Crashlytics as non-fatal reports, so they can be seen and fixed.
// Only where it happened and the error's kind or code are sent: never
// names, things, search words or server messages.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Turned on in main() for release builds with Firebase.
abstract final class Problems {
  static bool enabled = false;
}

/// What kind of failure, without any text that could hold someone's data.
String problemCode(Object e) => switch (e) {
  FirebaseFunctionsException() => 'functions/${e.code}',
  FirebaseException() => '${e.plugin}/${e.code}',
  PlatformException() => 'platform/${e.code}',
  _ => e.runtimeType.toString(),
};

class AppProblem implements Exception {
  const AppProblem(this.where, this.code);

  final String where;
  final String code;

  @override
  String toString() => 'AppProblem($where: $code)';
}

/// Logs a caught failure; in release builds it also reaches Crashlytics.
void reportProblem(String where, Object e, [StackTrace? stack]) {
  final code = problemCode(e);
  debugPrint('$where: $code');
  if (!Problems.enabled) return;
  FirebaseCrashlytics.instance.recordError(AppProblem(where, code), stack, reason: where, fatal: false).catchError((Object _) {});
}

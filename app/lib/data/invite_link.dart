import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings.dart';

/// Invite links (user request): the family invite is shared as a Play Store
/// link carrying the code, so whoever installs from it is asked to join
/// right after signing in, without typing the code.
abstract final class InviteLink {
  static const store = 'https://play.google.com/store/apps/details?id=io.github.graviton94.homefairy';

  /// The store link that carries [code] to the new phone.
  static String of(String code) => '$store&referrer=${Uri.encodeQueryComponent('invite=$code')}';

  /// The code in a Play install referrer ("invite=482913"), or null.
  static String? codeIn(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;
    final code = Uri.splitQueryString(referrer)['invite'] ?? '';
    return RegExp(r'^\d{6}$').hasMatch(code) ? code : null;
  }
}

/// Reads the install referrer once per install; overridden in tests.
abstract class ReferrerSource {
  Future<String?> get();
}

class NoReferrer implements ReferrerSource {
  const NoReferrer();
  @override
  Future<String?> get() async => null;
}

class PlayReferrer implements ReferrerSource {
  static const _channel = MethodChannel('homefairy/referrer');
  @override
  Future<String?> get() async {
    try {
      return await _channel.invokeMethod<String>('get').timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('referrer: ${e.runtimeType}');
      return null;
    }
  }
}

final referrerSourceProvider = Provider<ReferrerSource>((ref) => const NoReferrer());

/// The invite code that came with this install, until it is used or turned down.
class PendingInvite extends Notifier<String?> {
  static const _key = 'invite.pending';
  static const _read = 'invite.referrerRead';

  @override
  String? build() => ref.read(prefsProvider).getString(_key);

  /// Looks at the install referrer the first time the app starts.
  Future<void> load() async {
    final prefs = ref.read(prefsProvider);
    if (prefs.getBool(_read) ?? false) return;
    final code = InviteLink.codeIn(await ref.read(referrerSourceProvider).get());
    await prefs.setBool(_read, true);
    if (code != null) {
      await prefs.setString(_key, code);
      state = code;
    }
  }

  Future<void> clear() async {
    await ref.read(prefsProvider).remove(_key);
    state = null;
  }
}

final pendingInviteProvider = NotifierProvider<PendingInvite, String?>(PendingInvite.new);

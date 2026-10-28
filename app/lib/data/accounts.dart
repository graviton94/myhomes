import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

enum LoginProvider { kakao, naver, google }

/// Who is signed in. Guests (anonymous Firebase users or no Firebase at all)
/// have no account.
class Account {
  const Account(this.provider, this.name, [this.photoUrl, this.uid = '']);

  final LoginProvider provider;
  final String? name;
  final String? photoUrl;

  /// Firebase uid; the member id in a shared home.
  final String uid;
}

/// Thrown when a sign-in fails for a reason other than the person cancelling.
class LoginFailed implements Exception {
  const LoginFailed(this.reason);

  final String reason;

  @override
  String toString() => 'LoginFailed($reason)';
}

/// Login settings passed at build time; empty in local builds and tests.
abstract final class LoginConfig {
  static const kakaoKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  // The Naver keys go into Android resources (build.gradle.kts); this only says they are there.
  static const naverOn = bool.fromEnvironment('NAVER_ON');
}

abstract class Accounts {
  /// Providers this build can sign in with.
  Set<LoginProvider> get providers;

  Stream<Account?> get changes;

  /// Signs in. Returns null when the person cancels; throws [LoginFailed].
  Future<Account?> signIn(LoginProvider provider);

  /// Back to a guest. Things saved on the phone stay.
  Future<void> signOut();
}

class NoAccounts implements Accounts {
  const NoAccounts();

  @override
  Set<LoginProvider> get providers => const {};

  @override
  Stream<Account?> get changes => Stream.value(null);

  @override
  Future<Account?> signIn(LoginProvider provider) async => null;

  @override
  Future<void> signOut() async {}
}

/// Google through Firebase Auth; Kakao and Naver through their SDKs, whose
/// access token the `login` Cloud Function checks with the provider and
/// trades for a Firebase custom token (uid `kakao:<id>` / `naver:<id>`).
class FirebaseAccounts implements Accounts {
  FirebaseAccounts() {
    if (LoginConfig.kakaoKey.isNotEmpty) {
      kakao.KakaoSdk.init(nativeAppKey: LoginConfig.kakaoKey);
    }
  }

  final _auth = FirebaseAuth.instance;
  Future<void>? _googleReady;

  @override
  Set<LoginProvider> get providers => {
    if (LoginConfig.kakaoKey.isNotEmpty) LoginProvider.kakao,
    if (LoginConfig.naverOn) LoginProvider.naver,
    if (LoginConfig.googleWebClientId.isNotEmpty) LoginProvider.google,
  };

  static Account? accountOf(User? u) {
    if (u == null || u.isAnonymous) return null;
    if (u.uid.startsWith('kakao:')) {
      return Account(LoginProvider.kakao, u.displayName, u.photoURL, u.uid);
    }
    if (u.uid.startsWith('naver:')) {
      return Account(LoginProvider.naver, u.displayName, u.photoURL, u.uid);
    }
    if (u.providerData.any((p) => p.providerId == 'google.com')) {
      return Account(LoginProvider.google, u.displayName ?? u.email, u.photoURL, u.uid);
    }
    return null;
  }

  @override
  Stream<Account?> get changes => _auth.userChanges().map(accountOf);

  @override
  Future<Account?> signIn(LoginProvider provider) async {
    try {
      final user = switch (provider) {
        LoginProvider.google => await _google(),
        LoginProvider.kakao => await _custom('kakao', await _kakaoToken()),
        LoginProvider.naver => await _custom('naver', await _naverToken()),
      };
      return accountOf(user);
    } on _Cancelled {
      return null;
    } on LoginFailed {
      rethrow;
    } catch (e) {
      // Short reason for the message: which step said no, and its code.
      final reason = switch (e) {
        FirebaseFunctionsException() => 'server ${e.code}',
        FirebaseAuthException() => 'auth ${e.code}',
        PlatformException() => '${e.code}${e.message == null ? '' : ': ${e.message}'}',
        _ => e.runtimeType.toString(),
      };
      debugPrint('login failed: $provider $reason');
      throw LoginFailed('${provider.name} $reason');
    }
  }

  Future<User?> _google() async {
    final g = GoogleSignIn.instance;
    await (_googleReady ??= g.initialize(serverClientId: LoginConfig.googleWebClientId));
    final GoogleSignInAccount account;
    try {
      account = await g.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const _Cancelled();
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const LoginFailed('no id token');
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    // Keep the guest's uid when possible, so today's suggestion count carries over.
    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      try {
        return (await current.linkWithCredential(credential)).user;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use') rethrow;
        return (await _auth.signInWithCredential(e.credential ?? credential)).user;
      }
    }
    return (await _auth.signInWithCredential(credential)).user;
  }

  Future<String> _kakaoToken() async {
    try {
      final api = kakao.UserApi.instance;
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          return (await api.loginWithKakaoTalk()).accessToken;
        } catch (e) {
          // Backed out inside KakaoTalk: stop. Anything else (e.g. not linked to an account): try the web login.
          if (e is PlatformException && e.code == 'CANCELED') {
            throw const _Cancelled();
          }
          if (e is kakao.KakaoClientException && e.reason == kakao.ClientErrorCause.cancelled) {
            throw const _Cancelled();
          }
        }
      }
      return (await api.loginWithKakaoAccount()).accessToken;
    } on kakao.KakaoClientException catch (e) {
      if (e.reason == kakao.ClientErrorCause.cancelled) {
        throw const _Cancelled();
      }
      rethrow;
    } on kakao.KakaoAuthException catch (e) {
      if (e.error == kakao.AuthErrorCause.accessDenied) {
        throw const _Cancelled();
      }
      rethrow;
    }
  }

  Future<String> _naverToken() async {
    final r = await FlutterNaverLogin.logIn();
    if (r.status == NaverLoginStatus.loggedOut) throw const _Cancelled();
    if (r.status != NaverLoginStatus.loggedIn) {
      throw LoginFailed('naver: ${r.errorMessage ?? r.status.name}');
    }
    final token = await FlutterNaverLogin.getCurrentAccessToken();
    if (token.accessToken.isEmpty) throw const LoginFailed('naver token');
    return token.accessToken;
  }

  Future<User?> _custom(String provider, String accessToken) async {
    final fn = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('login');
    final r = await fn.call<Object?>({'provider': provider, 'token': accessToken});
    final token = r.data is Map ? (r.data as Map)['token'] : null;
    if (token is! String) throw const LoginFailed('no custom token');
    final user = (await _auth.signInWithCustomToken(token)).user;
    // The server set the display name after the token was made; fetch it.
    await user?.reload();
    return _auth.currentUser;
  }

  @override
  Future<void> signOut() async {
    final account = accountOf(_auth.currentUser);
    try {
      switch (account?.provider) {
        case LoginProvider.kakao:
          await kakao.UserApi.instance.logout();
        case LoginProvider.naver:
          await FlutterNaverLogin.logOut();
        case LoginProvider.google:
          await (_googleReady ??= GoogleSignIn.instance.initialize(serverClientId: LoginConfig.googleWebClientId));
          await GoogleSignIn.instance.signOut();
        case null:
          break;
      }
    } catch (e) {
      debugPrint('provider sign-out: ${e.runtimeType}');
    }
    await _auth.signOut();
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}

/// Set in main() once Firebase is ready; [NoAccounts] in tests.
final accountsProvider = Provider<Accounts>((ref) => const NoAccounts());

final accountProvider = StreamProvider<Account?>((ref) => ref.watch(accountsProvider).changes);

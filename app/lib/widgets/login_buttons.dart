import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/accounts.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import 'sheets.dart';

/// Kakao, Naver and Google buttons, drawn to each provider's guide. A provider this build has no keys for
/// says sign-in opens soon.
class LoginButtons extends ConsumerStatefulWidget {
  const LoginButtons({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  ConsumerState<LoginButtons> createState() => _LoginButtonsState();
}

class _LoginButtonsState extends ConsumerState<LoginButtons> {
  LoginProvider? _busy;

  Future<void> _signIn(LoginProvider provider) async {
    final l = AppLocalizations.of(context);
    final accounts = ref.read(accountsProvider);
    if (!accounts.providers.contains(provider)) {
      showMessage(context, l.loginSoon);
      return;
    }
    setState(() => _busy = provider);
    try {
      final account = await accounts.signIn(provider);
      if (!mounted || account == null) return;
      final name = account.name;
      if (name != null && name.isNotEmpty) {
        showMessage(context, l.loginWelcome(name));
      }
      widget.onSignedIn();
    } on LoginFailed catch (e) {
      if (mounted) showMessage(context, l.loginFailedWhy(e.reason));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Colors, symbols and labels follow each provider's login button guide
    // (official files in design/login/official/).
    Widget button(
      LoginProvider p, {
      required String label,
      required Widget logo,
      required Color bg,
      required Color fg,
      Color? border,
    }) => SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: border == null ? null : BorderSide(color: border),
          textStyle: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: _busy == null ? () => _signIn(p) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 20,
              child: _busy == p
                  ? CircularProgressIndicator(strokeWidth: 2.5, color: fg)
                  : logo,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          LoginProvider.kakao,
          label: l.loginKakao,
          logo: SvgPicture.asset('assets/login/kakao_symbol.svg'),
          bg: const Color(0xFFFEE500),
          fg: const Color(0xD9000000),
        ),
        const SizedBox(height: AppSpace.sm + 2),
        button(
          LoginProvider.naver,
          label: l.loginNaver,
          logo: Padding(
            padding: const EdgeInsets.all(2),
            child: Image.asset('assets/login/naver_n.png'),
          ),
          bg: const Color(0xFF03C75A),
          fg: Colors.white,
        ),
        const SizedBox(height: AppSpace.sm + 2),
        button(
          LoginProvider.google,
          label: l.loginGoogle,
          logo: Image.asset('assets/login/google_g.png'),
          bg: Colors.white,
          fg: const Color(0xFF1F1F1F),
          border: const Color(0xFF747775),
        ),
      ],
    );
  }
}

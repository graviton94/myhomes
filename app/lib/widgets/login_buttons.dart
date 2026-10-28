import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accounts.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import 'sheets.dart';

/// Kakao, Naver and Google buttons. A provider this build has no keys for
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
    } on LoginFailed {
      if (mounted) showMessage(context, l.loginFailed);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);

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
          side: border == null ? null : BorderSide(color: border),
        ),
        onPressed: _busy == null ? () => _signIn(p) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_busy == p)
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
              )
            else
              logo,
            const SizedBox(width: 10),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );

    Widget mark(
      String letter,
      Color bg,
      Color fg, {
      bool round = true,
      Color? border,
    }) => Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(5),
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
      child: Text(
        letter,
        style: AppType.label.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
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
          logo: mark('K', const Color(0xD9000000), const Color(0xFFFEE500)),
          bg: const Color(0xFFFEE500),
          fg: const Color(0xD9000000),
        ),
        const SizedBox(height: AppSpace.sm + 2),
        button(
          LoginProvider.naver,
          label: l.loginNaver,
          logo: mark('N', Colors.white, const Color(0xFF03C75A), round: false),
          bg: const Color(0xFF03C75A),
          fg: Colors.white,
        ),
        const SizedBox(height: AppSpace.sm + 2),
        button(
          LoginProvider.google,
          label: l.loginGoogle,
          logo: mark(
            'G',
            Colors.transparent,
            const Color(0xFF4285F4),
            border: c.border,
          ),
          bg: c.card,
          fg: c.fg,
          border: c.border,
        ),
      ],
    );
  }
}

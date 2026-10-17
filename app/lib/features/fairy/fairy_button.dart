import 'package:flutter/material.dart';

import '../../design/theme.dart';
import '../../l10n/app_localizations.dart';
import 'fairy_chat_sheet.dart';

/// Round House Fairy button (bottom right). Opens the chat sheet.
/// [badge] shows how many things the fairy wants to mention.
class FairyButton extends StatelessWidget {
  const FairyButton({super.key, this.badge = 0});

  final int badge;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: badge > 0 ? l.askFairyWithBadge(badge) : l.askFairy,
      child: SizedBox(
        width: 68,
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: c.primarySoft,
              shape: CircleBorder(side: BorderSide(color: c.primary, width: 2)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showFairyChat(context),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: OverflowBox(
                    maxWidth: 104,
                    maxHeight: 120,
                    alignment: const Alignment(0.05, -0.15),
                    child: Image.asset(
                      dark ? 'assets/fairy/hello_dark.webp' : 'assets/fairy/hello.webp',
                      width: 104,
                      height: 120,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: ExcludeSemantics(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.danger,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: c.bg, width: 2),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

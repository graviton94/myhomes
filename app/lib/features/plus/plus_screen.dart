import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/accounts.dart';
import '../../data/shop.dart';
import '../../data/smart_suggest.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fairy_growth.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/sheets.dart';

/// "요정 가루 더 받기": Plus (every month) and a pouch of dust (once), sold
/// by Google Play. A guest is asked to sign in first: what is bought is
/// kept with the account.
class PlusScreen extends ConsumerStatefulWidget {
  const PlusScreen({super.key});

  @override
  ConsumerState<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends ConsumerState<PlusScreen> {
  StreamSubscription<ShopResult>? _results;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _results = ref.read(shopProvider).results.listen((r) {
      if (!mounted) return;
      setState(() => _busy = false);
      final l = AppLocalizations.of(context);
      if (r == ShopResult.done) {
        ref.invalidate(creditsProvider);
        showMessage(context, l.plusDone);
      } else if (r == ShopResult.failed) {
        showMessage(context, l.plusFailed);
      }
    });
  }

  @override
  void dispose() {
    _results?.cancel();
    super.dispose();
  }

  Future<void> _buy(String id) async {
    setState(() => _busy = true);
    await ref.read(shopProvider).buy(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final account = ref.watch(accountProvider).value;
    final dust = dustLeft(ref.watch(creditsProvider).value);
    final products = ref.watch(shopProductsProvider).value;
    String? priceOf(String id) => products?.where((p) => p.id == id).firstOrNull?.price;
    final plusPrice = priceOf(ShopIds.plus), packPrice = priceOf(ShopIds.dust);
    final muted = AppType.caption.copyWith(color: c.mutedFg);

    Widget card({required String keyName, required String title, required String body, String? price, required Widget action, Widget? foot}) => Container(
      key: ValueKey(keyName),
      margin: const EdgeInsets.only(top: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const DoodleDust(size: 22),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: OneLine([title], style: t.titleMedium)),
              if (price != null) Text(price, style: AppType.label.copyWith(color: c.primaryInk)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          FitText(body, style: AppType.body),
          const SizedBox(height: AppSpace.md),
          action,
          if (foot != null) ...[const SizedBox(height: AppSpace.sm), foot],
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: OneLine([l.plusTitle], style: t.titleLarge, minScale: 0.8)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
        children: [
          FitText(l.plusLead, style: muted),
          if (account == null) ...[
            const SizedBox(height: AppSpace.lg),
            FitText(l.plusGuest, style: AppType.body),
            const SizedBox(height: AppSpace.md),
            FilledButton(key: const ValueKey('plus-login'), onPressed: () => context.push('/login'), child: Text(l.signIn)),
          ] else ...[
            if (products != null && products.isEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Container(
                key: const ValueKey('plus-soon'),
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: FitText(l.plusSoon, style: AppType.caption.copyWith(color: c.accentInk)),
              ),
            ],
            card(
              keyName: 'plus-card',
              title: l.plusName,
              body: l.plusBody,
              price: plusPrice == null ? null : l.plusPrice(plusPrice),
              action: dust?.plus == true
                  ? OutlinedButton(
                      key: const ValueKey('plus-manage'),
                      onPressed: () => launchUrl(
                        Uri.parse('https://play.google.com/store/account/subscriptions?sku=${ShopIds.plus}&package=io.github.graviton94.homefairy'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: OneLine([l.plusManage]),
                    )
                  : FilledButton(
                      key: const ValueKey('plus-buy'),
                      onPressed: _busy || plusPrice == null ? null : () => _buy(ShopIds.plus),
                      child: OneLine([l.plusBuy]),
                    ),
              foot: dust?.plus == true ? OneLine([l.plusActive], style: AppType.label.copyWith(color: c.secondaryInk)) : FitText(l.plusTerms, style: muted),
            ),
            card(
              keyName: 'pack-card',
              title: l.packName,
              body: l.packBody,
              action: FilledButton.tonal(
                key: const ValueKey('pack-buy'),
                onPressed: _busy || packPrice == null ? null : () => _buy(ShopIds.dust),
                child: OneLine([packPrice == null ? l.packName : l.packBuy(packPrice)]),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            TextButton(
              key: const ValueKey('plus-restore'),
              onPressed: _busy
                  ? null
                  : () {
                      setState(() => _busy = true);
                      ref.read(shopProvider).restore().whenComplete(() {
                        // Nothing to bring back sends no result: stop waiting after a moment.
                        Future<void>.delayed(const Duration(seconds: 4), () {
                          if (mounted && _busy) setState(() => _busy = false);
                        });
                      });
                    },
              child: Text(l.plusRestore),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          const DustCard(showMore: false),
        ],
      ),
    );
  }
}

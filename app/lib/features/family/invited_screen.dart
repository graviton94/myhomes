import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../data/household.dart';
import '../../data/invite_link.dart';
import '../../data/usage_stats.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/fairy.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/layers.dart';
import '../../widgets/sheets.dart';
import 'family_screen.dart' show problemText;

/// Installed from a family invite link (user request): right after signing
/// in, join the family home instead of making a new one. A home already on
/// this phone is merged in or kept apart, as the person chooses.
class InvitedScreen extends ConsumerStatefulWidget {
  const InvitedScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<InvitedScreen> createState() => _InvitedScreenState();
}

class _InvitedScreenState extends ConsumerState<InvitedScreen> {
  bool _busy = false;

  Future<void> _join() async {
    final l = AppLocalizations.of(context);
    final home = ref.read(homeProvider.notifier);
    final phone = await home.phoneData();
    if (!mounted) return;
    var merge = false;
    if (phone.spaces.isNotEmpty || phone.items.isNotEmpty) {
      final choice = await askQuestion<bool>(
        context,
        title: l.invitedPhoneTitle,
        detail: l.invitedPhoneBody(phone.spaces.length, phone.items.length),
        answers: [
          Answer(true, l.invitedMerge, note: l.invitedMergeNote),
          Answer(false, l.invitedKeep, note: l.invitedKeepNote),
        ],
      );
      if (choice == null || !mounted) return;
      merge = choice;
    }
    setState(() => _busy = true);
    try {
      await ref.read(householdsProvider).join(widget.code);
      noteUsage(ref, UsageCount.join);
      // The family home takes over; then the phone's home goes in, if asked.
      final joined = await ref.read(householdProvider.future).timeout(const Duration(seconds: 15));
      if (joined != null) {
        if (merge) {
          await ref.read(homeProvider.future);
          await home.apply<int>((d, ctx) => mergeHome(d, phone, ctx));
        }
        await ref.read(settingsProvider.notifier).setMergedInto(joined.id);
      }
      await ref.read(pendingInviteProvider.notifier).clear();
      if (mounted) context.go('/');
    } on HouseholdFailed catch (e) {
      if (mounted) showMessage(context, problemText(l, e.problem));
    } catch (_) {
      if (mounted) showMessage(context, l.familyProblemOffline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ownHome() async {
    await ref.read(pendingInviteProvider.notifier).clear();
    if (!mounted) return;
    final empty = (await ref.read(homeProvider.notifier).phoneData()).spaces.isEmpty;
    if (!mounted) return;
    context.go('/');
    if (empty) WidgetsBinding.instance.addPostFrameCallback((_) => GoRouter.of(context).push('/house/setup'));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final code = '${widget.code.substring(0, 3)} ${widget.code.substring(3)}';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Fairy(FairyPose.hello, height: 150),
              const SizedBox(height: AppSpace.lg),
              OneLine([l.invitedTitle], style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.sm),
              FitText(l.invitedBody(code), style: t.bodyMedium?.copyWith(color: c.mutedFg), textAlign: TextAlign.center),
              const Spacer(),
              FilledButton(key: const ValueKey('invited-join'), onPressed: _busy ? null : _join, child: Text(l.invitedJoin)),
              const SizedBox(height: AppSpace.sm),
              TextButton(key: const ValueKey('invited-own'), onPressed: _busy ? null : _ownHome, child: Text(l.invitedOwn)),
              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),
      ),
    );
  }
}

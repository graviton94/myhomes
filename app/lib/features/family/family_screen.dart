import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/accounts.dart';
import '../../data/home_store.dart';
import '../../data/household.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/sheets.dart';
import '../../widgets/fit_text.dart';

/// Family tab: sign in, make our home or join one with a code, see who is
/// in it, invite someone, leave.
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  bool _busy = false;
  ({String code, DateTime expires})? _invite;

  Households get _households => ref.read(householdsProvider);

  /// Runs a server step with a spinner and a plain message when it fails.
  Future<bool> _run(Future<void> Function() step) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await step();
      return true;
    } on HouseholdFailed catch (e) {
      if (mounted) showMessage(context, problemText(l, e.problem));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final l = AppLocalizations.of(context);
    final phone = await ref.read(homeProvider.notifier).phoneData();
    if (!mounted) return;
    var upload = false;
    if (phone.spaces.isNotEmpty || phone.items.isNotEmpty) {
      final choice = await showModalBottomSheet<bool>(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.familyUploadTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpace.sm),
                FitText(l.familyUploadBody(phone.spaces.length, phone.items.length)),
                const SizedBox(height: AppSpace.lg),
                FilledButton(
                  key: const ValueKey('family-upload-yes'),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l.familyUploadYes),
                ),
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.familyUploadNo)),
              ],
            ),
          ),
        ),
      );
      if (choice == null) return;
      upload = choice;
    }
    if (await _run(() => _households.create(l.familyDefaultName, upload: upload ? phone : null))) _markUploaded = upload;
  }

  /// Set after making our home with this phone's things, so the merge card stays away.
  bool _markUploaded = false;

  Future<void> _merge(Household home, HomeData phone) async {
    final l = AppLocalizations.of(context);
    final ok = await confirm(
      context,
      title: l.familyMergeTitle,
      body: l.familyMergeBody(phone.spaces.length, phone.items.length),
      action: l.familyMergeAction,
    );
    if (!ok || !mounted) return;
    final count = await ref.read(homeProvider.notifier).apply<int>((d, ctx) => mergeHome(d, phone, ctx));
    await ref.read(settingsProvider.notifier).setMergedInto(home.id);
    if (mounted) {
      setState(() {});
      showMessage(context, l.familyMerged(count ?? 0));
    }
  }

  Future<void> _join() async {
    final l = AppLocalizations.of(context);
    final code = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _JoinScreen()));
    if (code == null || !mounted) return;
    final inHome = ref.read(householdProvider).value != null;
    if (inHome) {
      final ok = await confirm(context, title: l.familyAlreadyTitle, body: l.familyAlreadyBody, action: l.familyAlreadyAction);
      if (!ok) return;
    }
    await _run(() => _households.join(code, leaveCurrent: inHome));
  }

  Future<void> _makeInvite() async {
    ({String code, DateTime expires})? got;
    if (await _run(() async => got = await _households.invite())) setState(() => _invite = got);
  }

  Future<void> _leave() async {
    final l = AppLocalizations.of(context);
    final ok = await confirm(context, title: l.familyLeave, body: l.familyLeaveBody, action: l.familyLeaveAction);
    if (!ok) return;
    if (await _run(_households.leave)) setState(() => _invite = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final account = ref.watch(accountProvider).value;
    final home = ref.watch(householdProvider).value;

    final Widget body;
    if (account == null) {
      body = _center(
        EmptyState(
          pose: FairyPose.hello,
          title: l.familyGuestTitle,
          body: l.familyGuestBody,
          action: FilledButton(
            key: const ValueKey('family-sign-in'),
            onPressed: () async {
              final ok = await confirm(context, title: l.leaveGuest, body: l.leaveGuestBody, action: l.signIn);
              if (ok) await ref.read(settingsProvider.notifier).leaveGuest();
            },
            child: Text(l.signIn),
          ),
        ),
      );
    } else if (home == null) {
      body = _center(
        EmptyState(
          pose: FairyPose.hello,
          title: l.familyGuestTitle,
          body: l.familyAloneBody,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(key: const ValueKey('family-create'), onPressed: _busy ? null : _create, child: Text(l.familyCreate)),
              const SizedBox(height: AppSpace.sm),
              FilledButton.tonal(key: const ValueKey('family-join'), onPressed: _busy ? null : _join, child: Text(l.familyJoin)),
            ],
          ),
        ),
      );
    } else {
      body = _members(l, home, account.uid);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.navFamily)),
      body: Stack(
        children: [
          Positioned.fill(child: body),
          if (_busy) const Positioned(left: 0, right: 0, top: 0, child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Widget _center(Widget child) => Center(child: SingleChildScrollView(child: child));

  Widget _members(AppLocalizations l, Household home, String me) {
    final c = HfColors.of(context);
    final settings = ref.read(settingsProvider.notifier);
    if (_markUploaded) {
      _markUploaded = false;
      settings.setMergedInto(home.id);
    }
    final phone = settings.mergedInto(home.id) ? null : ref.watch(phoneDataProvider).value;
    final t = Theme.of(context).textTheme;
    final invite = _invite;
    final time = invite == null ? '' : DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(invite.expires);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.xl),
      children: [
        Text(l.familyHeader(home.name.isEmpty ? l.familyDefaultName : home.name, home.members.length, home.limit), style: t.titleMedium),
        const SizedBox(height: AppSpace.sm),
        for (final m in home.members)
          Card(
            child: ListTile(
              key: ValueKey('member-${m.uid}'),
              leading: CircleAvatar(
                backgroundColor: m.uid == me ? c.primarySoft : c.secondarySoft,
                foregroundImage: m.photoUrl == null ? null : NetworkImage(m.photoUrl!),
                child: Text(
                  memberInitial(l, m),
                  style: TextStyle(color: m.uid == me ? c.primaryInk : c.secondaryInk, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(m.uid == me ? '${memberName(l, m)} (${l.familyMe})' : memberName(l, m)),
              subtitle: m.uid == home.owner ? Text(l.familyOwner) : null,
            ),
          ),
        if (phone != null && (phone.spaces.isNotEmpty || phone.items.isNotEmpty)) ...[
          const SizedBox(height: AppSpace.md),
          Card(
            key: const ValueKey('family-merge'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.familyMergeTitle, style: t.titleSmall),
                  const SizedBox(height: AppSpace.xs),
                  FitText(l.familyMergeBody(phone.spaces.length, phone.items.length), style: t.bodySmall?.copyWith(color: c.mutedFg)),
                  const SizedBox(height: AppSpace.sm),
                  FilledButton.tonal(onPressed: _busy ? null : () => _merge(home, phone), child: Text(l.familyMergeAction)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        Text(l.familyInviteSection, style: t.titleSmall),
        const SizedBox(height: AppSpace.sm),
        if (home.full)
          Text(l.familyFull, style: t.bodyMedium?.copyWith(color: c.mutedFg))
        else if (invite == null)
          FilledButton.tonal(key: const ValueKey('family-invite'), onPressed: _busy ? null : _makeInvite, child: Text(l.familyInviteMake))
        else ...[
          Material(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: invite.code));
                if (mounted) showMessage(context, l.familyCopied);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                child: Text(
                  '${invite.code.substring(0, 3)} ${invite.code.substring(3)}',
                  key: const ValueKey('invite-code'),
                  textAlign: TextAlign.center,
                  style: AppType.display.copyWith(fontSize: 36, letterSpacing: 6, color: c.primaryInk),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            l.familyInviteValid(time),
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: c.mutedFg),
          ),
          const SizedBox(height: AppSpace.sm),
          FilledButton.icon(
            onPressed: () => SharePlus.instance.share(ShareParams(text: l.familyInviteMessage(invite.code))),
            icon: const Icon(Icons.send_rounded),
            label: Text(l.familyInviteSend),
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        TextButton(
          key: const ValueKey('family-leave'),
          onPressed: _busy ? null : _leave,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: Text(l.familyLeave),
        ),
      ],
    );
  }
}

/// What is saved on this phone itself (not the shared home), for merging.
final phoneDataProvider = FutureProvider.autoDispose<HomeData>((ref) => ref.read(homeProvider.notifier).phoneData());

String memberName(AppLocalizations l, Member m) => m.name?.isNotEmpty == true ? m.name! : l.familySomeone;

String memberInitial(AppLocalizations l, Member m) => memberName(l, m).characters.first;

String problemText(AppLocalizations l, HouseholdProblem p) => switch (p) {
  HouseholdProblem.full => l.familyProblemFull,
  HouseholdProblem.notFound => l.familyProblemNotFound,
  HouseholdProblem.offline => l.familyProblemOffline,
  HouseholdProblem.alreadyInHome => l.familyAlreadyBody,
  HouseholdProblem.other => l.familyProblemOther,
};

/// Full screen, so the keyboard has room (CLAUDE.md).
class _JoinScreen extends StatefulWidget {
  const _JoinScreen();

  @override
  State<_JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<_JoinScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _digits => _code.text.replaceAll(RegExp(r'\D'), '');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ok = _digits.length == 6;
    return Scaffold(
      appBar: AppBar(title: Text(l.familyJoin)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          FitText(l.familyJoinBody),
          const SizedBox(height: AppSpace.lg),
          TextField(
            key: const ValueKey('join-code'),
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 7,
            style: AppType.display.copyWith(fontSize: 32, letterSpacing: 6),
            decoration: InputDecoration(hintText: l.familyJoinHint, counterText: ''),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => ok ? Navigator.pop(context, _digits) : null,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: FilledButton(
            key: const ValueKey('join-go'),
            onPressed: ok ? () => Navigator.pop(context, _digits) : null,
            child: Text(l.familyJoinGo),
          ),
        ),
      ),
    );
  }
}

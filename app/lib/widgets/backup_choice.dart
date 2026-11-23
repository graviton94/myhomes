import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';

import '../data/account_backup.dart';
import '../l10n/app_localizations.dart';
import 'layers.dart';

/// "어느 집을 쓸까요?": the phone and the signed-in account each have a home.
Future<BackupChoice?> askWhichHome(BuildContext context, BackupInfo info, HomeData phone) {
  if (!context.mounted) return Future.value();
  final l = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  return askQuestion<BackupChoice>(
    context,
    title: l.backupChooseTitle,
    detail: l.backupChooseBody,
    answers: [
      Answer(BackupChoice.account, l.backupChooseAccount, note: l.backupChooseAccountNote(info.rooms, info.items, DateFormat.Md(locale).format(info.savedAt))),
      Answer(
        BackupChoice.phone,
        l.backupChoosePhone,
        note: l.backupChoosePhoneNote(phone.spaces.length, phone.items.length),
        shortNote: l.backupChooseCounts(phone.spaces.length, phone.items.length),
      ),
      Answer(BackupChoice.both, l.backupChooseBoth, note: l.backupChooseBothNote),
    ],
  );
}

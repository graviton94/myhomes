import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/header_line.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/open_item.dart';
import '../../widgets/sheets.dart';

/// Warranties and valuables: things with a warranty or a price, warranties
/// ending soonest first, the total, and a PDF list for moving house, an
/// insurance claim or after-sales.
class ValuablesScreen extends ConsumerWidget {
  const ValuablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final d = ref.watch(homeProvider).requireValue;
    final list = valuables(d);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final money = NumberFormat.decimalPattern(locale);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.valuablesTitle),
        actions: [
          if (list.isNotEmpty)
            IconButton(
              key: const ValueKey('valuables-share'),
              tooltip: l.reportShare,
              onPressed: () => _share(context, d, list),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          const SettingsButton(),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(pose: FairyPose.carry, title: l.valuablesTitle, body: l.valuablesEmpty),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
                  child: Text(l.valuablesTotal(money.format(valuablesTotal(d))), style: t.titleMedium?.copyWith(color: c.primaryInk)),
                ),
                for (final i in list)
                  ListTile(
                    leading: ItemThumb(category: i.category, photoPath: i.photoPath, iconKey: i.icon),
                    title: Text(i.qty > 1 ? '${i.name} ×${i.qty}' : i.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      [pathText(d.pathOf(i.containerId)), if (i.price != null) l.won(money.format(i.price))].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: i.warrantyUntil == null ? null : DdayBadge(expiryStatus(today: today, expiresOn: i.warrantyUntil!)),
                    onTap: () => openItem(context, d, i),
                  ),
              ],
            ),
    );
  }

  /// The list as an A4 PDF (with the app's Korean font so names print).
  Future<void> _share(BuildContext context, HomeData d, List<Item> list) async {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final money = NumberFormat.decimalPattern(locale);
    final date = DateFormat.yMMMd(locale);
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansKR-Bold.ttf'));
    final doc =
        pw.Document(
          title: l.valuablesTitle,
          theme: pw.ThemeData.withFont(base: font, bold: bold),
        )..addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) => [
              pw.Text(l.valuablesTitle, style: pw.TextStyle(font: bold, fontSize: 18)),
              pw.SizedBox(height: 4),
              pw.Text('${date.format(DateTime.now())} · ${l.valuablesTotal(money.format(valuablesTotal(d)))}'),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: [l.itemName, l.place, l.warrantyUntil, l.price],
                data: [
                  for (final i in list)
                    [
                      i.qty > 1 ? '${i.name} ×${i.qty}' : i.name,
                      pathText(d.pathOf(i.containerId)),
                      i.warrantyUntil == null ? '' : date.format(i.warrantyUntil!),
                      i.price == null ? '' : l.won(money.format(i.price)),
                    ],
                ],
                headerStyle: pw.TextStyle(font: bold),
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/homefairy-valuables.pdf');
    await file.writeAsBytes(await doc.save());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        title: l.valuablesTitle,
      ),
    );
  }
}

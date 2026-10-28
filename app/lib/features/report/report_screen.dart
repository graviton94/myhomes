import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/home_store.dart';
import '../../data/household.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fairy.dart';
import '../../widgets/header_line.dart';
import '../family/family_screen.dart';

/// One month at home: put in, used, thrown away, what was used most, who
/// changed things. "Share as PDF" turns the page into an A4 PDF on the phone
/// (no server), drawn the same way as on screen.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, this.month});

  /// The month to open; this month when null.
  final DateTime? month;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late DateTime _month = DateTime((widget.month ?? DateTime.now()).year, (widget.month ?? DateTime.now()).month);
  final _page = GlobalKey();
  Future<MonthReport>? _report;
  bool _sharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _report ??= _load();
  }

  Future<MonthReport> _load() async {
    final log = await ref.read(homeProvider.notifier).monthLog(_month.year, _month.month);
    return monthReport(log, _month.year, _month.month);
  }

  void _go(int months) => setState(() {
    _month = DateTime(_month.year, _month.month + months);
    _report = _load();
  });

  Future<void> _share(String title) async {
    setState(() => _sharing = true);
    try {
      final boundary = _page.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      final doc = pw.Document(title: title)
        ..addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain)),
          ),
        );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/homefairy-${DateFormat('yyyy-MM').format(_month)}.pdf');
      await file.writeAsBytes(await doc.save());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          title: title,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthName = DateFormat.yMMMM(locale).format(_month);
    final title = l.reportTitle(monthName);
    final now = DateTime.now();
    final isThisMonth = _month.year == now.year && _month.month == now.month;
    return Scaffold(
      appBar: AppBar(title: Text(l.reportOpen), actions: const [SettingsButton()]),
      body: FutureBuilder<MonthReport>(
        future: _report,
        builder: (context, snap) {
          final r = snap.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(tooltip: l.reportPrev, onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left_rounded)),
                    Expanded(
                      child: Text(monthName, textAlign: TextAlign.center, style: AppType.label),
                    ),
                    IconButton(
                      tooltip: l.reportNext,
                      onPressed: isThisMonth ? null : () => _go(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                RepaintBoundary(
                  key: _page,
                  child: r == null ? const SizedBox(height: 240) : _ReportPage(title: title, report: r),
                ),
                const SizedBox(height: AppSpace.lg),
                FilledButton.icon(
                  key: const ValueKey('report-share'),
                  onPressed: r == null || r.isEmpty || _sharing ? null : () => _share(title),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l.reportShare),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportPage extends ConsumerWidget {
  const _ReportPage({required this.title, required this.report});

  final String title;
  final MonthReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final home = ref.watch(householdProvider).value;
    final r = report;
    final most = r.topUsed.isEmpty ? 1 : r.topUsed.first.$2;
    final mostThrown = r.thrownOut.isEmpty ? 1 : r.thrownOut.first.$2;
    final members = r.byMember.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final mostChanges = members.isEmpty ? 1 : members.first.value;

    Widget section(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm),
      child: Text(text, style: t.titleSmall),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppType.display.copyWith(fontSize: 24))),
                const Fairy(FairyPose.cheer, height: 64),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (r.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
                child: Text(
                  l.reportEmpty,
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: c.mutedFg),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _Stat(value: r.added, label: l.reportAdded, color: c.secondaryInk),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: _Stat(value: r.used, label: l.reportUsed, color: c.accentInk),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: _Stat(value: r.discarded, label: l.reportDiscarded, color: c.primaryInk),
                  ),
                ],
              ),
              if (r.topUsed.isNotEmpty) ...[
                section(l.reportTopUsed),
                for (final (name, qty) in r.topUsed) _BarRow(label: name, value: qty, max: most, fill: Doodle.honey, text: '$qty'),
              ],
              if (r.thrownOut.isNotEmpty) ...[
                section(l.reportThrownOut),
                for (final (name, qty) in r.thrownOut)
                  _BarRow(label: name, value: qty, max: mostThrown, fill: Doodle.persimmonLight, text: '$qty'),
              ],
              if (members.length > 1 || (members.isNotEmpty && home != null)) ...[
                section(l.reportByMember),
                for (final m in members)
                  _BarRow(
                    label: home?.member(m.key) == null ? l.familySomeone : memberName(l, home!.member(m.key)!),
                    value: m.value,
                    max: mostChanges,
                    fill: Doodle.cheek,
                    text: l.reportTimes(m.value),
                  ),
              ],
            ],
            const SizedBox(height: AppSpace.lg),
            Text(
              l.reportFooter(DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(DateTime.now())),
              textAlign: TextAlign.right,
              style: AppType.caption.copyWith(color: c.mutedFg),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        children: [
          Text('$value', style: AppType.display.copyWith(fontSize: 28, color: color)),
          Text(label, style: AppType.caption.copyWith(color: c.mutedFg)),
        ],
      ),
    );
  }
}

/// A name, a crayon bar sized to [value] / [max], and the number.
class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max, required this.fill, required this.text});

  final String label;
  final int value;
  final int max;
  final Color fill;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption.copyWith(color: c.fg),
            ),
          ),
          Expanded(
            child: SizedBox(height: 16, child: CustomPaint(painter: _BarPainter(value / (max == 0 ? 1 : max), fill, label.hashCode))),
          ),
          SizedBox(
            width: 52,
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: AppType.caption.copyWith(color: c.mutedFg),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.share, this.fill, this.seed);

  final double share;
  final Color fill;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width * share.clamp(0.04, 1.0)) - 2;
    final bar = Path()..addRRect(RRect.fromLTRBR(1, 2, w, size.height - 2, const Radius.circular(5)));
    canvas.drawPath(bar, Paint()..color = fill);
    Doodle.hatch(canvas, bar, Doodle.ink.withValues(alpha: 0.12), gap: 3.5, width: 0.8);
    Doodle.crayon(canvas, bar, Doodle.line(Doodle.ink, 1.3), wobble: 0.5, step: 2, seed: seed);
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.share != share || old.fill != fill;
}

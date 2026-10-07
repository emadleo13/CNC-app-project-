import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/net/edge_functions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/quota_dialog.dart';
import '../domain/ai_review.dart';
import '../domain/cnc_dialect.dart';
import '../domain/gcode_line.dart';
import '../domain/gcode_rule_text.dart';
import '../parsers/gcode_parser.dart';
import 'gcode_syntax.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/saved_analysis.dart';

Color _severityColor(LineSeverity s) => switch (s) {
      LineSeverity.error   => AppColors.errorRed,
      LineSeverity.warning => AppColors.warningYellow,
      LineSeverity.ok      => AppColors.textMuted,
    };

IconData _severityIcon(LineSeverity s) =>
    s == LineSeverity.error ? Icons.error_outline : Icons.warning_amber_outlined;

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? analysisData;

  const AnalysisResultScreen({super.key, this.analysisData});

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late final List<GcodeLine> _lines;
  bool _showOnlyIssues = false;

  // AI review state
  AiReview? _review;
  bool _reviewing = false;
  String? _reviewError;

  String get _gcode => widget.analysisData?['gcode'] as String? ?? '';

  CncDialect get _dialect =>
      widget.analysisData?['dialect'] as CncDialect? ?? CncDialect.haas;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final raw = widget.analysisData?['lines'];
    // Parsed in a background isolate by the input screen; parse here only
    // when opened without it.
    _lines = raw is List<GcodeLine> ? raw : GcodeParser.parse(_gcode, _dialect);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory() async {
    final s      = ref.read(appStringsProvider);
    final firstLine = _gcode.trim().split('\n').first.trim();
    final label  = firstLine.isEmpty
        ? 'Untitled'
        : firstLine.substring(0, firstLine.length.clamp(0, 40));
    final a = SavedAnalysis(
      label:        label,
      dialectName:  _dialect.displayName,
      lineCount:    _lines.length,
      errorCount:   _lines.where((l) => l.severity == LineSeverity.error).length,
      warningCount: _lines.where((l) => l.severity == LineSeverity.warning).length,
      savedAt:      DateTime.now(),
    );
    await ref.read(analysesProvider.notifier).save(a);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.historySaved),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _runAiReview() async {
    final s = ref.read(appStringsProvider);
    final locale = ref.read(localeProvider);
    setState(() { _reviewing = true; _reviewError = null; });
    try {
      final data = await invokeEdgeFunction(
        'analyze-gcode',
        body: {
          'gcode':    _gcode,
          'dialect':  _dialect.name,
          'language': locale,
          // English text so the model reads the app's findings reliably.
          'localFindings': [
            for (final l in _lines)
              for (final i in l.issues)
                'L${l.lineNumber}: ${GcodeRuleText.of(i, 'en').message}',
          ],
        },
        timeout: const Duration(seconds: 120),
      );
      if (!mounted) return;
      setState(() { _review = AiReview.fromJson(data); _reviewing = false; });
    } on EdgeFunctionError catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewing = false;
        _reviewError = e.kind == EdgeErrorKind.quotaExceeded ? null : e.message(s);
      });
      if (e.kind == EdgeErrorKind.quotaExceeded) showQuotaDialog(context, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s        = ref.watch(appStringsProvider);
    final lines      = _lines;
    final errorCount   = lines.where((l) => l.severity == LineSeverity.error).length;
    final warningCount = lines.where((l) => l.severity == LineSeverity.warning).length;
    final displayed    = _showOnlyIssues ? lines.where((l) => l.hasIssue).toList() : lines;

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.gcodeTitle} — ${_dialect.shortName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
            tooltip: s.historySave,
            onPressed: _saveToHistory,
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: s.gcodeCopyTooltip,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _gcode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.gcodeCopied), duration: const Duration(seconds: 1)),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.gcodeViewTab),
            Tab(text: s.gcodeSummaryTab),
          ],
          indicatorColor: AppColors.primary,
          labelColor:     AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              // Wraps onto a second line on narrow screens.
              Expanded(
                child: Wrap(spacing: 10, runSpacing: 4, children: [
                  _StatChip(
                    icon:  Icons.format_list_numbered,
                    label: '${lines.length} ${s.gcodeLines}',
                    color: AppColors.textSecondary,
                  ),
                  if (errorCount > 0) _StatChip(
                    icon:  Icons.error_outline,
                    label: '$errorCount ${s.gcodeErrors}',
                    color: AppColors.errorRed,
                  ),
                  if (warningCount > 0) _StatChip(
                    icon:  Icons.warning_amber_outlined,
                    label: '$warningCount ${s.gcodeWarnings}',
                    color: AppColors.warningYellow,
                  ),
                ]),
              ),
              if (errorCount + warningCount > 0) ...[
                Text(s.gcodeIssuesOnly, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                Switch(
                  value:     _showOnlyIssues,
                  onChanged: (v) => setState(() => _showOnlyIssues = v),
                  activeThumbColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _GcodeListView(lines: displayed),
                _SummaryView(
                  lines:       lines,
                  dialect:     _dialect,
                  review:      _review,
                  reviewing:   _reviewing,
                  reviewError: _reviewError,
                  onReview:    _runAiReview,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GcodeListView extends ConsumerWidget {
  final List<GcodeLine> lines;
  const _GcodeListView({required this.lines});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final locale = ref.watch(localeProvider);
    // The app's direction, kept for the explanations inside the code list.
    final textDirection = Directionality.of(context);
    if (lines.isEmpty) {
      return Center(child: Text(s.gcodeNoIssues, style: const TextStyle(color: AppColors.successGreen)));
    }
    // Code lines keep left-to-right layout even in Persian/Arabic.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        itemCount: lines.length,
        itemBuilder: (context, i) => _GcodeLineTile(
          line: lines[i],
          locale: locale,
          textDirection: textDirection,
        ),
      ),
    );
  }
}

class _GcodeLineTile extends StatefulWidget {
  final GcodeLine line;
  final String locale;
  final TextDirection textDirection;
  const _GcodeLineTile({required this.line, required this.locale, required this.textDirection});

  @override
  State<_GcodeLineTile> createState() => _GcodeLineTileState();
}

class _GcodeLineTileState extends State<_GcodeLineTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final color = _severityColor(line.severity);
    return GestureDetector(
      onTap: line.hasIssue ? () => setState(() => _expanded = !_expanded) : null,
      child: Container(
        color: !line.hasIssue
            ? Colors.transparent
            : color.withValues(alpha: line.severity == LineSeverity.error ? 0.08 : 0.06),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line number
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${line.lineNumber}',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: color),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Severity indicator
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 8, top: 2),
                    decoration: BoxDecoration(
                      color: line.hasIssue ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Code
                  Expanded(child: _ColorizedCode(line: line)),
                  if (line.hasIssue)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
            // What is wrong and how to fix it, in the app's language.
            if (_expanded && line.hasIssue)
              Directionality(
                textDirection: widget.textDirection,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: BorderDirectional(start: BorderSide(color: color, width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, issue) in line.issues.indexed) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _IssueText(issue: issue, locale: widget.locale),
                      ],
                    ],
                  ),
                ),
              ),
            if (widget.line.lineNumber < 10000)
              const Divider(height: 1, color: Color(0x0FFFFFFF)),
          ],
        ),
      ),
    );
  }
}

/// A finding's message and, under it, the fix.
class _IssueText extends StatelessWidget {
  final LineIssue issue;
  final String locale;
  const _IssueText({required this.issue, required this.locale});

  @override
  Widget build(BuildContext context) {
    final t = GcodeRuleText.of(issue, locale);
    final color = _severityColor(issue.severity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(_severityIcon(issue.severity), size: 14, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(t.message, style: const TextStyle(fontSize: 12.5))),
        ]),
        if (t.fix.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.lightbulb_outline, size: 14, color: AppColors.infoBlue),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(t.fix,
              style: const TextStyle(fontSize: 12, color: AppColors.infoBlue, height: 1.4))),
          ]),
        ],
      ],
    );
  }
}

class _ColorizedCode extends StatelessWidget {
  final GcodeLine line;
  const _ColorizedCode({required this.line});

  static const _base = TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13);

  @override
  Widget build(BuildContext context) {
    final text = line.original;
    if (text.trim().isEmpty) return const SizedBox(height: 18);
    return RichText(
      text: TextSpan(style: _base, children: buildGcodeSpans(text, _base)),
    );
  }
}

class _SummaryView extends ConsumerWidget {
  final List<GcodeLine> lines;
  final CncDialect dialect;
  final AiReview? review;
  final bool reviewing;
  final String? reviewError;
  final VoidCallback onReview;
  const _SummaryView({
    required this.lines,
    required this.dialect,
    required this.review,
    required this.reviewing,
    required this.reviewError,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s        = ref.watch(appStringsProvider);
    final locale   = ref.watch(localeProvider);
    final errors   = [
      for (final l in lines)
        for (final i in l.issues)
          if (i.severity == LineSeverity.error) (l.lineNumber, i),
    ];
    final warnings = [
      for (final l in lines)
        for (final i in l.issues)
          if (i.severity == LineSeverity.warning) (l.lineNumber, i),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AiReviewCard(
          review: review, reviewing: reviewing, error: reviewError, onReview: onReview,
        ),
        const SizedBox(height: 12),
        _SummarySection(
          title: s.gcodeStatController,
          color: AppColors.infoBlue,
          icon:  Icons.settings_outlined,
          content: dialect.displayName,
        ),
        const SizedBox(height: 12),
        _SummarySection(
          title: s.gcodeStatStats,
          color: AppColors.textSecondary,
          icon:  Icons.bar_chart,
          content: '${lines.length} ${s.gcodeLines}\n${errors.length} ${s.gcodeErrors} · ${warnings.length} ${s.gcodeWarnings}',
        ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IssueList(title: s.gcodeStatErrors, color: AppColors.errorRed,
              icon: Icons.error_outline, items: errors, locale: locale),
        ],
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IssueList(title: s.gcodeStatWarnings, color: AppColors.warningYellow,
              icon: Icons.warning_amber_outlined, items: warnings, locale: locale),
        ],
        if (errors.isEmpty && warnings.isEmpty) ...[
          const SizedBox(height: 24),
          Center(child: Column(children: [
            const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 48),
            const SizedBox(height: 8),
            Text(s.gcodeNoIssues, style: const TextStyle(color: AppColors.successGreen, fontSize: 16)),
          ])),
        ],
      ],
    );
  }
}

/// "Review with AI" button, then the AI's summary, findings and suggestions.
class _AiReviewCard extends ConsumerWidget {
  final AiReview? review;
  final bool reviewing;
  final String? error;
  final VoidCallback onReview;
  const _AiReviewCard({required this.review, required this.reviewing,
      required this.error, required this.onReview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final r = review;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(s.gcodeAiTitle,
                style: const TextStyle(fontSize: 11, color: AppColors.primary, letterSpacing: 1.0))),
            ]),
            const SizedBox(height: 10),
            if (reviewing)
              Row(children: [
                const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: Text(s.gcodeAiRunning,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ])
            else if (r == null) ...[
              if (error != null) ...[
                Text(error!, style: const TextStyle(fontSize: 12.5, color: AppColors.errorRed)),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(error == null ? s.gcodeAiButton : s.commonRetry),
                ),
              ),
            ] else ...[
              if (r.summary.isNotEmpty)
                Text(r.summary, style: const TextStyle(fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 10),
              if (r.findings.isEmpty)
                Text(s.gcodeAiNoFindings,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.successGreen))
              else
                for (final f in r.findings) _AiFindingTile(finding: f),
              if (r.suggestions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(s.gcodeAiSuggestions,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                for (final tip in r.suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('• ', style: TextStyle(color: AppColors.infoBlue)),
                      Expanded(child: Text(tip, style: const TextStyle(fontSize: 12.5, height: 1.4))),
                    ]),
                  ),
              ],
            ],
            const SizedBox(height: 10),
            Text(s.gcodeAiDisclaimer,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _AiFindingTile extends ConsumerWidget {
  final AiFinding finding;
  const _AiFindingTile({required this.finding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final color = _severityColor(finding.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(_severityIcon(finding.severity), size: 14, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(finding.line != null ? 'L${finding.line}' : s.gcodeAiProgram,
            textDirection: TextDirection.ltr,
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(finding.issue, style: const TextStyle(fontSize: 12.5, height: 1.4)),
          if (finding.suggestion.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(finding.suggestion,
              style: const TextStyle(fontSize: 12, color: AppColors.infoBlue, height: 1.4)),
          ],
        ])),
      ]),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final String content;
  const _SummarySection({required this.title, required this.color, required this.icon, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 11, color: color, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(content, style: const TextStyle(fontSize: 14)),
          ])),
        ]),
      ),
    );
  }
}

/// Findings of one severity: "L12  message". Long programs can have many,
/// so the list is capped and says how many more there are.
class _IssueList extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<(int, LineIssue)> items;
  final String locale;
  const _IssueList({required this.title, required this.color, required this.icon,
      required this.items, required this.locale});

  static const _maxShown = 100;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(_maxShown);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 11, color: color, letterSpacing: 1.0)),
            ]),
            const SizedBox(height: 10),
            for (final (line, issue) in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('L$line', textDirection: TextDirection.ltr, style: TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 11, color: color, fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: Text(GcodeRuleText.of(issue, locale).message,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  )),
                ]),
              ),
            if (items.length > _maxShown)
              Text('+${items.length - _maxShown}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/cnc_dialect.dart';
import '../domain/gcode_line.dart';
import '../parsers/gcode_parser.dart';
import 'gcode_syntax.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/saved_analysis.dart';

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
  bool _showOnlyIssues = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<GcodeLine> get _lines {
    final raw = widget.analysisData?['lines'];
    if (raw is List<GcodeLine>) return raw;
    final gcode   = widget.analysisData?['gcode']   as String?   ?? '';
    final dialect = widget.analysisData?['dialect']  as CncDialect? ?? CncDialect.haas;
    return GcodeParser.parse(gcode, dialect);
  }

  CncDialect get _dialect =>
      widget.analysisData?['dialect'] as CncDialect? ?? CncDialect.haas;

  Future<void> _saveToHistory() async {
    final s      = ref.read(appStringsProvider);
    final lines  = _lines;
    final gcode  = widget.analysisData?['gcode'] as String? ?? '';
    final firstLine = gcode.trim().split('\n').first.trim();
    final label  = firstLine.isEmpty
        ? 'Untitled'
        : firstLine.substring(0, firstLine.length.clamp(0, 40));
    final a = SavedAnalysis(
      label:        label,
      dialectName:  _dialect.displayName,
      lineCount:    lines.length,
      errorCount:   lines.where((l) => l.severity == LineSeverity.error).length,
      warningCount: lines.where((l) => l.severity == LineSeverity.warning).length,
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

  @override
  Widget build(BuildContext context) {
    final s        = ref.watch(appStringsProvider);
    final lines      = _lines;
    final errorCount   = lines.where((l) => l.severity == LineSeverity.error).length;
    final warningCount = lines.where((l) => l.severity == LineSeverity.warning).length;
    final displayed    = _showOnlyIssues ? lines.where((l) => l.hasIssue).toList() : lines;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis — ${_dialect.shortName}'),
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
              final code = widget.analysisData?['gcode'] as String? ?? '';
              Clipboard.setData(ClipboardData(text: code));
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
              _StatChip(
                icon:  Icons.format_list_numbered,
                label: '${lines.length} ${s.gcodeLines}',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              if (errorCount > 0) _StatChip(
                icon:  Icons.error_outline,
                label: '$errorCount ${s.gcodeErrors}',
                color: AppColors.errorRed,
              ),
              if (errorCount > 0) const SizedBox(width: 8),
              if (warningCount > 0) _StatChip(
                icon:  Icons.warning_amber_outlined,
                label: '$warningCount ${s.gcodeWarnings}',
                color: AppColors.warningYellow,
              ),
              const Spacer(),
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
                _SummaryView(lines: lines, dialect: _dialect),
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
    if (lines.isEmpty) {
      return Center(child: Text(s.gcodeNoIssues, style: const TextStyle(color: AppColors.successGreen)));
    }
    return ListView.builder(
      itemCount: lines.length,
      itemBuilder: (context, i) => _GcodeLineTile(line: lines[i]),
    );
  }
}

class _GcodeLineTile extends StatefulWidget {
  final GcodeLine line;
  const _GcodeLineTile({required this.line});

  @override
  State<_GcodeLineTile> createState() => _GcodeLineTileState();
}

class _GcodeLineTileState extends State<_GcodeLineTile> {
  bool _expanded = false;

  Color get _bgColor {
    if (!widget.line.hasIssue) return Colors.transparent;
    return widget.line.severity == LineSeverity.error
        ? AppColors.errorRed.withValues(alpha: 0.08)
        : AppColors.warningYellow.withValues(alpha: 0.06);
  }

  Color get _lineNumColor {
    if (widget.line.severity == LineSeverity.error)   return AppColors.errorRed;
    if (widget.line.severity == LineSeverity.warning) return AppColors.warningYellow;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return GestureDetector(
      onTap: line.hasIssue || line.explanation != null
          ? () => setState(() => _expanded = !_expanded)
          : null,
      child: Container(
        color: _bgColor,
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
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono', fontSize: 11,
                        color: _lineNumColor,
                      ),
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
                      color: line.severity == LineSeverity.error
                          ? AppColors.errorRed
                          : line.severity == LineSeverity.warning
                              ? AppColors.warningYellow
                              : Colors.transparent,
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
            // Expanded issue detail
            if (_expanded && line.hasIssue) Container(
              margin: const EdgeInsets.fromLTRB(64, 0, 12, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
                border: Border(left: BorderSide(
                  color: line.severity == LineSeverity.error ? AppColors.errorRed : AppColors.warningYellow,
                  width: 2,
                )),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (line.issue != null) ...[
                    Row(children: [
                      Icon(
                        line.severity == LineSeverity.error ? Icons.error_outline : Icons.warning_amber_outlined,
                        size: 13,
                        color: line.severity == LineSeverity.error ? AppColors.errorRed : AppColors.warningYellow,
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(line.issue!, style: const TextStyle(fontSize: 12))),
                    ]),
                  ],
                  if (line.suggestion != null) ...[
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.lightbulb_outline, size: 13, color: AppColors.infoBlue),
                      const SizedBox(width: 4),
                      Expanded(child: Text(line.suggestion!,
                        style: const TextStyle(fontSize: 12, color: AppColors.infoBlue))),
                    ]),
                  ],
                  if (line.explanation != null) ...[
                    const SizedBox(height: 6),
                    Text(line.explanation!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ],
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
  const _SummaryView({required this.lines, required this.dialect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s        = ref.watch(appStringsProvider);
    final errors   = lines.where((l) => l.severity == LineSeverity.error).toList();
    final warnings = lines.where((l) => l.severity == LineSeverity.warning).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
          _IssueList(title: s.gcodeStatErrors, color: AppColors.errorRed, icon: Icons.error_outline, lines: errors),
        ],
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IssueList(title: s.gcodeStatWarnings, color: AppColors.warningYellow, icon: Icons.warning_amber_outlined, lines: warnings),
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 11, color: color, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(content, style: const TextStyle(fontSize: 14)),
          ]),
        ]),
      ),
    );
  }
}

class _IssueList extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<GcodeLine> lines;
  const _IssueList({required this.title, required this.color, required this.icon, required this.lines});

  @override
  Widget build(BuildContext context) {
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
            ...lines.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('L${l.lineNumber}:', style: TextStyle(
                  fontFamily: 'JetBrainsMono', fontSize: 11, color: color, fontWeight: FontWeight.bold,
                )),
                const SizedBox(width: 8),
                Expanded(child: Text(l.issue ?? l.original,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                )),
              ]),
            )),
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
    return Row(children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ]);
  }
}

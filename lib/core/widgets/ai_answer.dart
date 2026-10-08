import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

/// An AI answer rendered as Markdown (the server sends Markdown when the
/// request says `format: "markdown"`).
///
/// - The reading direction follows the answer, not the app: an English
///   answer in the Persian app reads left to right, and a Persian one right
///   to left.
/// - Code blocks are always left to right, monospace, scroll sideways and
///   have their own copy button: G-code must never be reordered.
/// - Images are never loaded (a model could name any URL); only http(s)
///   links open, in the browser.
class AiAnswer extends StatelessWidget {
  final String text;

  /// Called after a code block was copied.
  final VoidCallback? onCodeCopied;

  const AiAnswer(this.text, {super.key, this.onCodeCopied});

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 14,
      height: 1.55,
      color: AppColors.textPrimary,
    );
    final sheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: base,
      listBullet: base,
      h1: base.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
      h2: base.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      h3: base.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      h4: base.copyWith(fontWeight: FontWeight.w700),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      code: const TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 12.5,
        color: AppColors.gcodeG,
        backgroundColor: AppColors.surfaceAlt,
      ),
      blockquote: base.copyWith(color: AppColors.textSecondary),
      blockquoteDecoration: const BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: AppColors.border, width: 3),
        ),
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      codeblockPadding: EdgeInsets.zero,
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      tableBorder: TableBorder.all(color: AppColors.border),
      tableColumnWidth: const IntrinsicColumnWidth(),
    );

    final direction = answerDirection(text) ?? Directionality.of(context);
    return Directionality(
      textDirection: direction,
      child: MarkdownBody(
        data: bidiSafe(text, rtl: direction == TextDirection.rtl),
        selectable: true,
        // Models break lines without Markdown list syntax; keep the breaks.
        softLineBreak: true,
        styleSheet: sheet,
        builders: {'pre': _CodeBlockBuilder(onCodeCopied)},
        imageBuilder: (uri, title, alt) => alt == null || alt.isEmpty
            ? const SizedBox.shrink()
            : Text(alt, style: base.copyWith(color: AppColors.textSecondary)),
        onTapLink: (text, href, title) {
          final uri = href == null ? null : Uri.tryParse(href);
          if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}

/// Plain AI or user text in a [Text]: reads in its own direction, with
/// number ranges kept in order (see [bidiSafe]). For text that is not
/// Markdown, such as the G-code review findings.
class AiText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const AiText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final direction = answerDirection(text);
    final rtl = (direction ?? Directionality.of(context)) == TextDirection.rtl;
    return Text(
      bidiSafe(text, rtl: rtl),
      textDirection: direction,
      style: style,
    );
  }
}

final _arabicScript = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
);
final _latin = RegExp(r'[A-Za-z\u00C0-\u024F]');
final _fence = RegExp(r'```[\s\S]*?(?:```|$)');

/// Right to left when Arabic-script letters make up at least a third of the
/// prose (Persian answers are full of Latin terms such as G43 or Vc), left to
/// right when there are letters but fewer, null when there are none.
TextDirection? answerDirection(String text) {
  final prose = text.replaceAll(_fence, ' ');
  final arabic = _arabicScript.allMatches(prose).length;
  final latin = _latin.allMatches(prose).length;
  if (arabic == 0 && latin == 0) return null;
  return arabic * 2 >= latin && arabic > 0
      ? TextDirection.rtl
      : TextDirection.ltr;
}

/// Keeps left-to-right pieces in order inside right-to-left text, by
/// wrapping them in a left-to-right isolate (invisible; only what is shown
/// changes, copying uses the original text):
/// - inline code, so "`Z-2.`" keeps its point at the end;
/// - in right-to-left answers, numbers joined by - – × x or /: after a
///   Persian word the bidi algorithm treats digits as Arabic numbers and
///   showed "0.3-0.5 mm" as "0.5-0.3 mm".
/// Code blocks are not touched.
String bidiSafe(String text, {required bool rtl}) {
  final out = StringBuffer();
  var last = 0;
  for (final m in _fence.allMatches(text)) {
    out.write(_isolateProse(text.substring(last, m.start), rtl));
    out.write(m.group(0));
    last = m.end;
  }
  out.write(_isolateProse(text.substring(last), rtl));
  return out.toString();
}

const _lri = '\u2066';
const _pdi = '\u2069';
final _inlineCode = RegExp(r'`([^`\n]+)`');
final _numberRun = RegExp(
  r'[0-9\u0660-\u0669\u06F0-\u06F9][0-9\u0660-\u0669\u06F0-\u06F9.,\u066B]*'
  r'(?:[ \u00A0]?[-\u2013\u00D7x/][ \u00A0]?[0-9\u0660-\u0669\u06F0-\u06F9][0-9\u0660-\u0669\u06F0-\u06F9.,\u066B]*)+',
);

String _isolateProse(String prose, bool rtl) {
  final out = StringBuffer();
  var last = 0;
  for (final m in _inlineCode.allMatches(prose)) {
    out.write(_isolateNumbers(prose.substring(last, m.start), rtl));
    out.write('`$_lri${m[1]}$_pdi`');
    last = m.end;
  }
  out.write(_isolateNumbers(prose.substring(last), rtl));
  return out.toString();
}

String _isolateNumbers(String text, bool rtl) =>
    rtl ? text.replaceAllMapped(_numberRun, (m) => '$_lri${m[0]}$_pdi') : text;

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final VoidCallback? onCopied;
  _CodeBlockBuilder(this.onCopied);

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent.replaceFirst(RegExp(r'\n$'), '');
    return CodeBlock(code: code, onCopied: onCopied);
  }
}

/// A block of code (usually G-code): left to right, monospace, scrolls
/// sideways, with a copy button for the code alone.
class CodeBlock extends StatelessWidget {
  final String code;
  final VoidCallback? onCopied;
  const CodeBlock({super.key, required this.code, this.onCopied});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.copy_outlined, size: 16),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
              tooltip: MaterialLocalizations.of(context).copyButtonLabel,
              onPressed: () {
                HapticFeedback.selectionClick();
                Clipboard.setData(ClipboardData(text: code));
                onCopied?.call();
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

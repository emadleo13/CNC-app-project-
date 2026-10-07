import '../domain/gcode_line.dart';
import 'block.dart';

// Pre-compiled once: parse() runs for every line of a possibly huge program.
final RegExp _reNewline = RegExp(r'\r?\n');

const _motionCodes = {'G0', 'G1', 'G2', 'G3'};
const _cuttingMotion = {'G1', 'G2', 'G3'};
const _arcCodes = {'G2', 'G3'};

/// Rule checker shared by every dialect. Two passes:
/// 1. [checkBlock], per line, things visible on the line alone.
/// 2. [_checkProgram], which walks the program with the modal state
///    (spindle, feed, canned cycle, compensation, units, work offset).
///
/// Each state finding is reported once per situation, at the line where it
/// first matters, so one missing M03 does not paint every line red. After a
/// subprogram call or a jump the state is unknown, so state findings stop.
abstract class BaseParser {
  BlockReader get reader;

  /// Display name used in messages, e.g. "Haas".
  String get dialectName;

  /// G codes this control knows. Null: no unknown-code check.
  Set<String>? get knownGCodes;

  /// Canned drilling cycles in G-code form (Haas/Fanuc) for this kind of
  /// machine. On lathes G73/G74/G76 mean other cycles. Empty for Sinumerik.
  Set<String> cannedCyclesFor(ProgramShape shape) => const {};

  /// Codes that end a main program (or a subprogram).
  Set<String> get programEnds;

  /// Whether the machine needs G43 H after a tool change (mills on
  /// Fanuc-type controls). Sinumerik applies the D offset itself.
  bool get usesLengthCompensation => false;

  /// Codes that select units / a work offset.
  Set<String> get unitCodes;
  Set<String> get workOffsetCodes;

  /// Whether a missing G20/G21 is worth a warning (controls where programs
  /// normally state it).
  bool get warnMissingUnits => true;

  /// Per-line checks of the dialect.
  void checkBlock(Block b, List<LineIssue> out, ProgramShape shape);

  List<GcodeLine> parse(String gcode) {
    final raw = gcode.split(_reNewline);
    final blocks = [for (var i = 0; i < raw.length; i++) reader.read(i, raw[i])];
    final issues = [for (var i = 0; i < raw.length; i++) <LineIssue>[]];
    final shape = ProgramShape.of(blocks);

    for (final b in blocks) {
      if (!b.isEmpty) checkBlock(b, issues[b.index], shape);
    }
    _checkProgram(blocks, issues, shape);

    return [
      for (var i = 0; i < raw.length; i++)
        GcodeLine(
          lineNumber: i + 1,
          original:   raw[i],
          issues:     issues[i],
          tokens:     blocks[i].tokens,
        ),
    ];
  }

  // ── shared per-line checks ─────────────────────────────────────────────────

  /// Unknown G codes, several motion modes in one block, and F0.
  void checkCommon(Block b, List<LineIssue> out) {
    final known = knownGCodes;
    if (known != null) {
      for (final g in b.gCodes) {
        if (!known.contains(g)) {
          out.add(LineIssue(LineSeverity.warning, 'unknown_g', {'code': g, 'dialect': dialectName}));
        }
      }
    }
    final motions = b.gCodes.where(_motionCodes.contains).toSet();
    if (motions.length > 1) {
      out.add(LineIssue(LineSeverity.error, 'motion_conflict', {'codes': motions.join(' ')}));
    }
    if (b.number('F') == 0) {
      out.add(const LineIssue(LineSeverity.error, 'feed_zero'));
    }
  }

  // ── program walk ───────────────────────────────────────────────────────────

  void _checkProgram(List<Block> blocks, List<List<LineIssue>> issues, ProgramShape shape) {
    final cannedCycles = cannedCyclesFor(shape);
    String? motion;           // modal group 01, or 'cycle'
    var absolute = true;      // G90 is the usual power-on state
    var spindleOn = false;
    var feedSet = false;
    var unitsSet = false;
    var offsetSet = false;
    var cycleActive = false;
    var compActive = false;
    var lengthComp = false;
    String? pendingTool;      // last T word
    String? currentTool;      // tool loaded by the last M6
    var needLengthComp = false;
    var uncertain = false;    // after a call or a jump the state is unknown
    final once = <String>{};

    void add(int line, LineIssue issue) => issues[line].add(issue);
    void addOnce(int line, LineIssue issue) {
      if (once.add(issue.rule)) add(line, issue);
    }

    for (final b in blocks) {
      if (b.isEmpty) continue;
      final line = b.index;

      // Machine-coordinate and home moves are not part-program motion.
      final homeOrMachine = b.hasAnyG(const ['G28', 'G30', 'G53']);

      // Modal codes that apply to this block's own motion.
      if (b.hasG('G90')) absolute = true;
      if (b.hasG('G91')) absolute = false;
      if (b.hasAnyG(unitCodes)) unitsSet = true;
      if (b.hasAnyG(workOffsetCodes)) offsetSet = true;
      if (b.has('F') && b.number('F') != 0) feedSet = true;

      // Tool change.
      if (b.has('T')) pendingTool = b.words['T'] ?? '?';
      if (b.hasM('M6')) {
        if (cycleActive) add(line, const LineIssue(LineSeverity.warning, 'cycle_active'));
        if (compActive) add(line, const LineIssue(LineSeverity.warning, 'comp_active'));
        if (!b.has('T') && pendingTool == null && shape.isMill) {
          add(line, const LineIssue(LineSeverity.error, 'm6_no_tool'));
        }
        currentTool = pendingTool;
        spindleOn = false;        // a tool change stops the spindle
        lengthComp = false;
        needLengthComp = usesLengthCompensation && shape.isMill;
        cycleActive = false;
        compActive = false;
        once.remove('spindle_off_cut'); // a new tool needs its own M03
        once.remove('no_length_comp');
      }

      // Spindle words take effect with the motion on the same line.
      if (b.hasM('M3') || b.hasM('M4')) spindleOn = true;

      // Tool length compensation.
      if (b.hasG('G43') || b.hasG('G44') || b.hasG('G43.4')) {
        lengthComp = true;
        final h = b.words['H'];
        final t = currentTool;
        if (h != null && t != null && t != '?' && _int(h) != _int(t) && usesLengthCompensation) {
          add(line, LineIssue(LineSeverity.warning, 'h_mismatch', {'h': h, 't': t}));
        }
      }
      if (b.hasG('G49')) lengthComp = false;

      // Cutter compensation.
      if (b.hasG('G41') || b.hasG('G42')) compActive = true;
      if (b.hasG('G40')) compActive = false;

      // Motion mode.
      final explicitMotion = b.gCodes.where(_motionCodes.contains).toList();
      if (explicitMotion.isNotEmpty) {
        motion = explicitMotion.last;
        cycleActive = false;      // group 01 cancels a canned cycle
      }
      final startsCycle = b.hasAnyG(cannedCycles);
      if (startsCycle) {
        motion = 'cycle';
        cycleActive = true;
      }
      if (b.hasG('G80')) {
        cycleActive = false;
        if (motion == 'cycle') motion = null;
      }

      // What this block does.
      final moves = !homeOrMachine && (b.hasAxisWord || explicitMotion.isNotEmpty);
      final cycleHole = cycleActive && (startsCycle || b.hasAxisWord);
      final cutting = cycleHole ||
          (moves && motion != null && _cuttingMotion.contains(motion) &&
              (b.hasAxisWord || b.hasAnyG(_arcCodes)));

      // Arc needs a centre or a radius.
      if (moves && _arcCodes.contains(motion) && !_hasArcCentre(b)) {
        add(line, LineIssue(LineSeverity.error, 'arc_no_center', {'code': motion!}));
      }

      if (!uncertain) {
        if (moves || cycleHole) {
          if (!unitsSet && warnMissingUnits) {
            addOnce(line, const LineIssue(LineSeverity.warning, 'no_units'));
          }
          if (!offsetSet && workOffsetCodes.isNotEmpty) {
            addOnce(line, const LineIssue(LineSeverity.warning, 'no_work_offset'));
          }
        }
        if (cutting && !spindleOn) {
          addOnce(line, const LineIssue(LineSeverity.error, 'spindle_off_cut'));
        }
        if (cutting && !feedSet) {
          addOnce(line, const LineIssue(LineSeverity.error, 'no_feed'));
        }
        if (needLengthComp && !lengthComp && b.has('Z') && !homeOrMachine) {
          addOnce(line, LineIssue(LineSeverity.warning, 'no_length_comp',
              {'tool': currentTool ?? '?'}));
        }
      }

      // G28 with coordinates in absolute mode goes through that point first.
      final absoluteAxes = const ['X', 'Y', 'Z', 'A', 'B', 'C'].any(b.has);
      if (b.hasG('G28') && absolute && absoluteAxes && usesG28IntermediatePoint) {
        add(line, const LineIssue(LineSeverity.warning, 'g28_absolute'));
      }

      // Program end with modes still on.
      if (b.mCodes.any(programEnds.contains) || b.keywords.contains('RET')) {
        if (cycleActive) add(line, const LineIssue(LineSeverity.warning, 'cycle_active'));
        if (compActive) add(line, const LineIssue(LineSeverity.warning, 'comp_active'));
      }

      if (b.hasM('M5') || b.mCodes.any(programEnds.contains)) spindleOn = false;

      // Calls and jumps make the following state unknown.
      if (_leavesStraightLine(b)) uncertain = true;
    }

    // A main program must end; a subprogram ends with M99/M17/RET.
    final last = blocks.lastWhere((b) => !b.isEmpty, orElse: () => blocks.first);
    final ended = blocks.any((b) =>
        b.mCodes.any(programEnds.contains) || b.hasM('M99') || b.keywords.contains('RET'));
    if (!ended && blocks.any((b) => b.hasAxisWord)) {
      add(last.index, LineIssue(LineSeverity.warning, 'no_program_end', {'codes': programEndText}));
    }
  }

  /// How the program end is written on this control, for the message.
  String get programEndText;

  /// Fanuc-type G28 moves through the given point before homing.
  bool get usesG28IntermediatePoint => false;

  bool _hasArcCentre(Block b) =>
      const ['I', 'J', 'K', 'R'].any(b.has) ||
      const ['CR', 'AR', 'CIP', 'CT', 'TURN'].any(b.keywords.contains);

  bool _leavesStraightLine(Block b) {
    if (b.hasAnyG(const ['G65', 'G66'])) return true;
    if (b.hasAnyG(const ['M97', 'M98'])) return true;
    if (b.mCodes.any((m) => m == 'M97' || m == 'M98')) return true;
    for (final k in b.keywords) {
      if (k == 'IF' || k == 'WHILE' || k == 'CALL' || k == 'PCALL' ||
          k == 'MCALL' || k == 'REPEAT' || k == 'REPEATB' || k == 'LOOP' ||
          k == 'FOR' || k.startsWith('GOTO')) {
        return true;
      }
    }
    return false;
  }

  static int? _int(String s) => double.tryParse(s)?.round();
}

/// Facts about the whole program that change which rules apply.
class ProgramShape {
  /// Mill programs change tools with M06; lathe programs index the turret
  /// with T0101 and use X/Z only.
  final bool isMill;

  const ProgramShape({required this.isMill});

  factory ProgramShape.of(List<Block> blocks) {
    final usesM6 = blocks.any((b) => b.hasM('M6'));
    final usesY = blocks.any((b) => b.has('Y'));
    final latheTools = blocks.any((b) {
      final t = b.words['T'];
      return t != null && !t.contains('.') && t.length >= 3;
    });
    final latheModes = blocks.any((b) => b.hasAnyG(const ['G96', 'G99', 'G18']));
    final isLathe = !usesM6 && !usesY && (latheTools || latheModes);
    return ProgramShape(isMill: !isLathe);
  }
}

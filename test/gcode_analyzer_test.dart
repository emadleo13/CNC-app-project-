import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/features/gcode_analyzer/domain/cnc_dialect.dart';
import 'package:cnc_assist/features/gcode_analyzer/domain/gcode_line.dart';
import 'package:cnc_assist/features/gcode_analyzer/domain/gcode_rule_text.dart';
import 'package:cnc_assist/features/gcode_analyzer/parsers/gcode_parser.dart';
import 'package:cnc_assist/features/gcode_analyzer/parsers/haas_parser.dart';
import 'package:cnc_assist/features/gcode_analyzer/parsers/sinumerik_parser.dart';
import 'package:cnc_assist/features/gcode_analyzer/presentation/gcode_input_screen.dart';

/// Every (line number, rule) the analyzer reports for [program].
List<(int, String)> findings(String program, [CncDialect dialect = CncDialect.haas]) => [
      for (final l in GcodeParser.parse(program, dialect))
        for (final i in l.issues) (l.lineNumber, i.rule),
    ];

List<String> rulesOf(String program, [CncDialect dialect = CncDialect.haas]) =>
    findings(program, dialect).map((f) => f.$2).toList();

/// A minimal correct Haas mill header; tests append the lines under test.
const _millStart = '''
G90 G94 G17 G40 G49 G80
G21
T1 M06
S3000 M03
G54
G00 X0. Y0.
G43 Z25. H01
''';

String mill(String body) => '$_millStart$body\nG80\nG40\nM05\nM30\n';

void main() {
  group('real programs produce no findings', () {
    test('Haas mill (Fusion 360 post style)', () {
      const program = '''
%
O01001 (POCKET TEST)
(T1 D=10. CR=0. - FLAT END MILL)
G90 G94 G17 G40 G49 G80
G21
G28 G91 Z0.
G90
T1 M06
S4000 M03
G54
M08
G00 X-5. Y-5.
G43 Z25. H01
G00 Z5.
G01 Z-2. F300.
G01 X50. F800.
G02 X60. Y10. R10.
G03 X50. Y20. I-10. J0.
G01 X-5.
G00 Z25.
G187 P3 E0.01
M09
M05
G28 G91 Z0.
G90
T2 M06
S1200 M03
G154 P1
G00 X10. Y10.
G43 Z25. H02
M88
G98 G83 X10. Y10. Z-20. R2. Q3. F120.
X30. Y10.
G80
G00 Z25.
M89
M05
G28 G91 Z0.
G90
M30
%
''';
      expect(findings(program), isEmpty);
    });

    test('Haas lathe with G71/G70 and G28 U0 W0', () {
      const program = '''
%
O02001 (LATHE TEST)
G18 G21 G40 G80 G99
G50 S2500
G28 U0.
G28 W0.
T0101 (OD TURN)
G54
G96 S200 M03
G00 X55. Z5. M08
G01 Z0. F0.2
G01 X-1.6
G00 X52. Z2.
G71 U2. R0.5
G71 P100 Q200 U0.5 W0.1 F0.25
N100 G00 X20.
G01 Z-10. F0.15
G02 X30. Z-15. R5.
G01 X50.
N200 Z-40.
G70 P100 Q200
G00 X100. Z50. M09
G28 U0. W0.
M05
M30
%
''';
      expect(findings(program), isEmpty);
    });

    test('Sinumerik with frames, CR=, I=AC() and CYCLE83', () {
      const program = '''
; SINUMERIK TEST (parentheses in a comment)
G17 G90 G54 G71 G64
T="MILL10" D1
M6
S3000 M3
G0 X0 Y0 Z10
G1 Z-2 F200
G1 X50 F600
G2 X60 Y10 CR=10
G3 X50 Y20 I=AC(50) J=AC(10)
G1 X0
G0 Z50
T="DRILL8" D1
M6
S1500 M3
G0 X10 Y10 Z10
MCALL CYCLE83(10,0,2,-20,,-5,,3,0,0,1,0)
X10 Y10
X30 Y10
MCALL
G0 Z100
M30
''';
      expect(findings(program, CncDialect.sinumerik), isEmpty);
    });
  });

  group('per-line rules', () {
    test('unknown G-code, but not the codes Haas really has', () {
      expect(rulesOf(mill('G999')), ['unknown_g']);
      expect(rulesOf(mill('G187 P2\nG103 P1\nG154 P5')), isEmpty);
    });

    test('GOTO and other macro keywords are not G-codes', () {
      expect(rulesOf(mill('#1=5\nIF [#1 GT 3] GOTO10\nN10 G01 X1. F100.')), isEmpty);
    });

    test('two motion modes on one line', () {
      expect(rulesOf(mill('G00 G01 X10. F100.')), ['motion_conflict']);
    });

    test('F0', () {
      expect(rulesOf(mill('G01 X10. F0')), contains('feed_zero'));
    });

    test('arc without centre, also when the arc mode is modal', () {
      expect(rulesOf(mill('G01 Z-1. F100.\nG02 X10. Y10.')), ['arc_no_center']);
      expect(rulesOf(mill('G01 Z-1. F100.\nG02 X10. Y10. R5.\nX20. Y20.')), ['arc_no_center']);
      expect(rulesOf(mill('G01 Z-1. F100.\nG02 X10. Y10. R5.\nG03 X0. Y0. I-5. J0.')), isEmpty);
    });

    test('canned cycle needs Z, R and (for peck cycles) Q', () {
      expect(rulesOf(mill('G81 X0. Y0. R2. F100.')), ['cycle_no_z']);
      expect(rulesOf(mill('G81 X0. Y0. Z-5. F100.')), ['cycle_no_r']);
      expect(rulesOf(mill('G83 X0. Y0. Z-20. R2. F100.')), ['cycle_no_q']);
      expect(rulesOf(mill('G83 X0. Y0. Z-20. R2. Q3. F100.')), isEmpty);
    });

    test('M98 needs P, unless it calls a quoted file', () {
      expect(rulesOf(mill('M98')), ['m98_no_p']);
      expect(rulesOf(mill('M98 P1000')), isEmpty);
      expect(rulesOf(mill('M98 "O01000.nc"')), isEmpty);
    });

    test('cutter compensation must not start on an arc and needs D on a mill', () {
      expect(rulesOf(mill('G01 Z-1. F100.\nG41 G02 X10. Y10. R5. D1\nG40 G01 X0.')), ['comp_on_arc']);
      expect(rulesOf(mill('G01 Z-1. F100.\nG41 G01 X10. Y10.\nG40 G01 X0.')), ['comp_no_d']);
      expect(rulesOf(mill('G01 Z-1. F100.\nG41 G01 X10. Y10. D1\nG40 G01 X0.')), isEmpty);
    });

    test('decimal point reminder on generic Fanuc only', () {
      final generic = mill('G01 X10 Y5.5 F100.');
      expect(rulesOf(generic, CncDialect.generic), ['no_decimal']);
      expect(rulesOf(generic), isEmpty);
    });

    test('Sinumerik DEF type and cycle parameters', () {
      const start = 'G17 G90 G54\nT1 D1\nM6\nS1000 M3\n';
      expect(rulesOf('${start}DEF R_X\nM30', CncDialect.sinumerik), ['sin_def_type']);
      expect(rulesOf('${start}DEF REAL R_X\nM30', CncDialect.sinumerik), isEmpty);
      expect(rulesOf('${start}G0 X0 Y0 Z5\nCYCLE83\nM30', CncDialect.sinumerik), ['sin_cycle_parens']);
    });
  });

  group('program rules', () {
    test('cutting with the spindle stopped, reported once per tool', () {
      const program = '''
G90 G21 G54
T1 M06
G00 X0. Y0.
G43 Z25. H01
G01 Z-1. F100.
G01 X10.
T2 M06
G00 G43 Z25. H02
G01 Z-1. F100.
M30
''';
      final f = findings(program);
      expect(f.where((x) => x.$2 == 'spindle_off_cut').map((x) => x.$1), [5, 9]);
    });

    test('a move under modal G01 is a cutting move, even with G43 on it', () {
      // After "G01 X10." the G43 line feeds Z with the spindle stopped.
      const program = 'G90 G21 G54\nT1 M06\nS1000 M03\nG00 G43 Z25. H01\nG01 X10. F100.\nM05\nG43 Z30. H01\nM30';
      expect(findings(program), [(7, 'spindle_off_cut')]);
    });

    test('M03 on the cutting line itself counts', () {
      expect(rulesOf(mill('G01 Z-1. F100. S1000 M03')), isEmpty);
    });

    test('no feed before the first cut, reported once', () {
      const program = 'G90 G21 G54\nT1 M06\nS1000 M03\nG43 Z25. H01\nG01 Z-1.\nG01 X10.\nM30';
      expect(findings(program), [(5, 'no_feed')]);
    });

    test('units and work offset missing before the first move', () {
      const program = 'T1 M06\nS1000 M03\nG43 Z25. H01\nG01 Z-1. F100.\nM30';
      expect(rulesOf(program), ['no_units', 'no_work_offset']);
    });

    test('Z move after a tool change without G43', () {
      const program = 'G90 G21 G54\nT1 M06\nS1000 M03\nG00 X0. Y0.\nG00 Z25.\nG01 Z-1. F100.\nM30';
      expect(findings(program), [(5, 'no_length_comp')]);
    });

    test('H that does not match the tool', () {
      const program = 'G90 G21 G54\nT2 M06\nS1000 M03\nG43 Z25. H03\nG01 Z-1. F100.\nM30';
      expect(rulesOf(program), ['h_mismatch']);
    });

    test('M06 with no tool number', () {
      const program = 'G90 G21 G54\nM06\nS1000 M03\nG01 X1. F100.\nM30';
      expect(rulesOf(program), contains('m6_no_tool'));
    });

    test('canned cycle and cutter compensation left on at the end', () {
      expect(rulesOf('${_millStart}G98 G81 X0. Y0. Z-5. R2. F100.\nX10.\nM30'), ['cycle_active']);
      expect(rulesOf('${_millStart}G01 Z-1. F100.\nG41 G01 X10. D1\nM30'), ['comp_active']);
      // G00 cancels a canned cycle, so no warning here.
      expect(rulesOf('${_millStart}G98 G81 X0. Y0. Z-5. R2. F100.\nG00 Z25.\nM30'), isEmpty);
    });

    test('G28 in absolute mode', () {
      expect(rulesOf(mill('G28 Z0.')), ['g28_absolute']);
      expect(rulesOf(mill('G28 G91 Z0.\nG90')), isEmpty);
    });

    test('program without an end, but subprograms may end with M99', () {
      expect(rulesOf('$_millStart G01 Z-1. F100.'), ['no_program_end']);
      expect(rulesOf('${_millStart}G01 Z-1. F100.\nM99'), isEmpty);
    });

    test('state rules stop after a subprogram call', () {
      // The subprogram may start the spindle, so no spindle finding after M98.
      const program = 'G90 G21 G54\nT1 M06\nM98 P2000\nG43 Z25. H01\nG01 Z-1. F100.\nM30';
      expect(rulesOf(program), isEmpty);
    });
  });

  group('reader', () {
    test('Haas: code after a mid-line comment is read', () {
      final lines = GcodeParser.parse('G00 X1. (RAPID) Y2.', CncDialect.haas);
      expect(lines.first.tokens, containsAll(['X1.', 'Y2.']));
    });

    test('Sinumerik: semicolon starts a comment, parentheses are code', () {
      // F inside the comment must not count; the F after X=IC(5) must.
      expect(rulesOf('G17 G90\nT1 D1\nM6\nS1000 M3\nG1 X=IC(5) F100 ; feed (fast)\nM30',
          CncDialect.sinumerik), isEmpty);
      expect(rulesOf('G17 G90\nT1 D1\nM6\nS1000 M3\nG1 X5 ; F100\nM30',
          CncDialect.sinumerik), ['no_feed']);
    });

    test('Sinumerik M1=3 starts spindle 1', () {
      expect(rulesOf('G17 G90\nT1 D1\nM6\nM1=3 S1=1000\nG1 X5 F100\nM30',
          CncDialect.sinumerik), isEmpty);
    });
  });

  group('rule text', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    Set<String> names(String s) => placeholder.allMatches(s).map((m) => m.group(1)!).toSet();

    test('every rule has text in every language with the same placeholders', () {
      for (final locale in ['en', 'fa', 'ro', 'ar']) {
        final table = GcodeRuleText.table(locale)!;
        for (final rule in GcodeRuleText.rules) {
          final t = table[rule];
          expect(t, isNotNull, reason: '$locale is missing $rule');
          final en = GcodeRuleText.table('en')![rule]!;
          expect(names(t!.$1), names(en.$1), reason: '$locale $rule message');
          expect(names(t.$2), names(en.$2), reason: '$locale $rule fix');
        }
      }
    });

    test('every rule the parsers report has text', () {
      const everything = '''
G999
G00 G01 X1.
G01 X1. F0
G02 X1. Y1.
G81 X0. Y0. F1.
G83 X0. Y0. Z-1. R1. F1.
M98
M06
G41 G02 X1. Y1. R1.
G28 Z0.
''';
      for (final dialect in CncDialect.values) {
        for (final line in GcodeParser.parse(everything, dialect)) {
          for (final issue in line.issues) {
            expect(GcodeRuleText.rules, contains(issue.rule));
          }
        }
      }
    });

    test('placeholders are filled', () {
      const issue = LineIssue(LineSeverity.warning, 'h_mismatch', {'h': '03', 't': '2'});
      final t = GcodeRuleText.of(issue, 'fa');
      expect(t.message, contains('H03'));
      expect(t.message, contains('T2'));
      expect(t.message, isNot(contains('{')));
    });
  });

  test('the analyzer knows every code the app\'s own G-code reference lists', () {
    final ref = jsonDecode(File('assets/data/gcode_reference.json').readAsStringSync())
        as Map<String, dynamic>;
    String norm(String c) {
      final m = RegExp(r'^G0*(\d+)(\.\d+)?$').firstMatch(c)!;
      return 'G${m.group(1)}${m.group(2) ?? ''}';
    }
    final haas = HaasParser().knownGCodes!;
    final sinumerik = SinumerikParser().knownGCodes!;
    for (final e in ref['g_codes'] as List) {
      final code = norm(e['code'] as String);
      final dialects = (e['dialects'] as List).cast<String>();
      if (dialects.contains('haas')) {
        expect(haas, contains(code), reason: 'Haas reference lists $code');
      }
      if (dialects.contains('sinumerik')) {
        expect(sinumerik, contains(code), reason: 'Sinumerik reference lists $code');
      }
    }
  });

  test('G-code files in UTF-8 and in Latin-1 both open', () {
    expect(decodeProgramFile(utf8.encode('(Ø10 DRILL)\nG81')), '(Ø10 DRILL)\nG81');
    // Latin-1 bytes for "(Ø10 DRILL)": 0xD8 is not valid UTF-8 on its own.
    expect(decodeProgramFile([0x28, 0xD8, 0x31, 0x30, 0x29]), '(Ø10)');
  });
}

import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/tools/presentation/tools_hub_screen.dart';
import '../../features/feed_speed/presentation/calculator_screen.dart';
import '../../features/turning/presentation/turning_screen.dart';
import '../../features/drilling/presentation/drilling_screen.dart';
import '../../features/converters/presentation/converters_screen.dart';
import '../../features/converters/presentation/hardness_screen.dart';
import '../../features/coordinates/presentation/taper_screen.dart';
import '../../features/coordinates/presentation/arc_screen.dart';
import '../../features/coordinates/presentation/gcode_gen_screen.dart';
import '../../features/precision/presentation/true_position_screen.dart';
import '../../features/precision/presentation/part_weight_screen.dart';
import '../../features/learn/presentation/quiz_screen.dart';
import '../../features/learn/presentation/tool_wear_screen.dart';
import '../../features/gcode_analyzer/presentation/gcode_input_screen.dart';
import '../../features/gcode_analyzer/presentation/analysis_result_screen.dart';
import '../../features/knowledge_base/presentation/qa_screen.dart';
import '../../features/knowledge_base/presentation/error_reference_screen.dart';
import '../../features/knowledge_base/presentation/gcode_reference_screen.dart';
import '../../features/knowledge_base/presentation/gcode_program_library_screen.dart';
import '../../features/knowledge_base/presentation/cnc_guides_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.calculator,
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: RouteNames.calculator,
          builder: (context, state) => const ToolsHubScreen(),
          routes: [
            GoRoute(
              path: 'milling',
              builder: (context, state) => const CalculatorScreen(),
            ),
            GoRoute(
              path: 'turning',
              builder: (context, state) => const TurningScreen(),
            ),
            GoRoute(
              path: 'drilling',
              builder: (context, state) => const DrillingScreen(),
            ),
            GoRoute(
              path: 'converters',
              builder: (context, state) => const ConvertersScreen(),
            ),
            GoRoute(
              path: 'hardness',
              builder: (context, state) => const HardnessScreen(),
            ),
            GoRoute(
              path: 'taper',
              builder: (context, state) => const TaperScreen(),
            ),
            GoRoute(
              path: 'arc',
              builder: (context, state) => const ArcScreen(),
            ),
            GoRoute(
              path: 'gcode-gen',
              builder: (context, state) => const GcodeGenScreen(),
            ),
            GoRoute(
              path: 'true-position',
              builder: (context, state) => const TruePositionScreen(),
            ),
            GoRoute(
              path: 'weight',
              builder: (context, state) => const PartWeightScreen(),
            ),
            GoRoute(
              path: 'quiz',
              builder: (context, state) => const QuizScreen(),
            ),
            GoRoute(
              path: 'tool-wear',
              builder: (context, state) => const ToolWearScreen(),
            ),
          ],
        ),
        GoRoute(
          path: RouteNames.gcodeAnalyzer,
          builder: (context, state) => const GcodeInputScreen(),
          routes: [
            GoRoute(
              path: 'result',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return AnalysisResultScreen(analysisData: extra);
              },
            ),
          ],
        ),
        GoRoute(
          path: RouteNames.knowledgeBase,
          builder: (context, state) => const QaScreen(),
          routes: [
            GoRoute(
              path: 'errors',
              builder: (context, state) => const ErrorReferenceScreen(),
            ),
            GoRoute(
              path: 'gcodes',
              builder: (context, state) => const GcodeReferenceScreen(),
            ),
            GoRoute(
              path: 'programs',
              builder: (context, state) => const GcodeProgramLibraryScreen(),
            ),
            GoRoute(
              path: 'guides',
              builder: (context, state) => const CncGuidesScreen(),
            ),
          ],
        ),
        GoRoute(
          path: RouteNames.history,
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: RouteNames.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.subscription,
          builder: (context, state) => const SubscriptionScreen(),
        ),
      ],
    ),
  ],
);

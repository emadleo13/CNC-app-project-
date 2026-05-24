import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/feed_speed/presentation/calculator_screen.dart';
import '../../features/gcode_analyzer/presentation/gcode_input_screen.dart';
import '../../features/gcode_analyzer/presentation/analysis_result_screen.dart';
import '../../features/knowledge_base/presentation/qa_screen.dart';
import '../../features/knowledge_base/presentation/error_reference_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.calculator,
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: RouteNames.calculator,
          builder: (context, state) => const CalculatorScreen(),
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
      ],
    ),
  ],
);

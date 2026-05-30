import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';

/// Logical grouping of tools on the hub.
enum ToolCategory {
  milling,
  turning,
  drilling,
  coordinates,
  converters,
  reference,
  learn
}

extension ToolCategoryX on ToolCategory {
  String label(AppStrings s) => switch (this) {
        ToolCategory.milling => s.catMilling,
        ToolCategory.turning => s.catTurning,
        ToolCategory.drilling => s.catDrilling,
        ToolCategory.coordinates => s.catCoordinates,
        ToolCategory.converters => s.catConverters,
        ToolCategory.reference => s.catReference,
        ToolCategory.learn => s.catLearn,
      };
}

/// One entry on the Tools Hub: title/subtitle are resolved at build time from
/// [AppStrings] so the grid stays fully localized.
class ToolDef {
  final String id;
  final IconData icon;
  final String route;
  final ToolCategory category;
  final String Function(AppStrings) title;
  final String Function(AppStrings) subtitle;

  /// Marks a tool not yet implemented (shown but disabled with a "soon" badge).
  final bool comingSoon;

  const ToolDef({
    required this.id,
    required this.icon,
    required this.route,
    required this.category,
    required this.title,
    required this.subtitle,
    this.comingSoon = false,
  });
}

/// Single source of truth for the hub grid. Routes here must match the
/// `GoRoute` paths registered in app_router.dart.
const List<ToolDef> kTools = [
  // ── Milling ──
  ToolDef(
    id: 'milling',
    icon: Icons.rotate_right,
    route: RouteNames.calcMilling,
    category: ToolCategory.milling,
    title: _millingTitle,
    subtitle: _millingSub,
  ),
  // ── Turning ──
  ToolDef(
    id: 'turning',
    icon: Icons.album_outlined,
    route: RouteNames.calcTurning,
    category: ToolCategory.turning,
    title: _turningTitle,
    subtitle: _turningSub,
  ),
  // ── Drilling ──
  ToolDef(
    id: 'drilling',
    icon: Icons.vertical_align_bottom,
    route: RouteNames.calcDrilling,
    category: ToolCategory.drilling,
    title: _drillingTitle,
    subtitle: _drillingSub,
  ),
  // ── Coordinates ──
  ToolDef(
    id: 'taper',
    icon: Icons.show_chart,
    route: RouteNames.calcTaper,
    category: ToolCategory.coordinates,
    title: _taperTitle,
    subtitle: _taperSub,
  ),
  ToolDef(
    id: 'arc',
    icon: Icons.architecture,
    route: RouteNames.calcArc,
    category: ToolCategory.coordinates,
    title: _arcTitle,
    subtitle: _arcSub,
  ),
  ToolDef(
    id: 'gcode_gen',
    icon: Icons.precision_manufacturing_outlined,
    route: RouteNames.calcGcodeGen,
    category: ToolCategory.coordinates,
    title: _gcodeGenTitle,
    subtitle: _gcodeGenSub,
  ),
  // ── Converters ──
  ToolDef(
    id: 'converters',
    icon: Icons.swap_horiz,
    route: RouteNames.calcConverters,
    category: ToolCategory.converters,
    title: _convertersTitle,
    subtitle: _convertersSub,
  ),
  ToolDef(
    id: 'hardness',
    icon: Icons.diamond_outlined,
    route: RouteNames.calcHardness,
    category: ToolCategory.converters,
    title: _hardnessTitle,
    subtitle: _hardnessSub,
  ),
  // ── Reference ──
  ToolDef(
    id: 'true_position',
    icon: Icons.gps_fixed,
    route: RouteNames.calcTruePosition,
    category: ToolCategory.reference,
    title: _truePosTitle,
    subtitle: _truePosSub,
  ),
  ToolDef(
    id: 'weight',
    icon: Icons.scale_outlined,
    route: RouteNames.calcWeight,
    category: ToolCategory.reference,
    title: _weightTitle,
    subtitle: _weightSub,
  ),
  // ── Learn ──
  ToolDef(
    id: 'quiz',
    icon: Icons.quiz_outlined,
    route: RouteNames.calcQuiz,
    category: ToolCategory.learn,
    title: _quizTitle,
    subtitle: _quizSub,
  ),
  ToolDef(
    id: 'tool_wear',
    icon: Icons.handyman_outlined,
    route: RouteNames.calcToolWear,
    category: ToolCategory.learn,
    title: _wearTitle,
    subtitle: _wearSub,
  ),
];

// Top-level functions used as const tear-offs above.
String _millingTitle(AppStrings s) => s.toolMilling;
String _millingSub(AppStrings s) => s.toolMillingSub;
String _turningTitle(AppStrings s) => s.toolTurning;
String _turningSub(AppStrings s) => s.toolTurningSub;
String _drillingTitle(AppStrings s) => s.toolDrilling;
String _drillingSub(AppStrings s) => s.toolDrillingSub;
String _taperTitle(AppStrings s) => s.toolTaper;
String _taperSub(AppStrings s) => s.toolTaperSub;
String _arcTitle(AppStrings s) => s.toolArc;
String _arcSub(AppStrings s) => s.toolArcSub;
String _gcodeGenTitle(AppStrings s) => s.toolGcodeGen;
String _gcodeGenSub(AppStrings s) => s.toolGcodeGenSub;
String _convertersTitle(AppStrings s) => s.toolConverters;
String _convertersSub(AppStrings s) => s.toolConvertersSub;
String _hardnessTitle(AppStrings s) => s.toolHardness;
String _hardnessSub(AppStrings s) => s.toolHardnessSub;
String _truePosTitle(AppStrings s) => s.toolTruePosition;
String _truePosSub(AppStrings s) => s.toolTruePositionSub;
String _weightTitle(AppStrings s) => s.toolWeight;
String _weightSub(AppStrings s) => s.toolWeightSub;
String _quizTitle(AppStrings s) => s.toolQuiz;
String _quizSub(AppStrings s) => s.toolQuizSub;
String _wearTitle(AppStrings s) => s.toolWear;
String _wearSub(AppStrings s) => s.toolWearSub;

class RouteNames {
  RouteNames._();

  static const String home           = '/';
  static const String calculator     = '/calculator';
  // Tool hub sub-routes (children of /calculator)
  static const String calcMilling      = '/calculator/milling';
  static const String calcTurning      = '/calculator/turning';
  static const String calcDrilling     = '/calculator/drilling';
  static const String calcTaper        = '/calculator/taper';
  static const String calcArc          = '/calculator/arc';
  static const String calcGcodeGen     = '/calculator/gcode-gen';
  static const String calcConverters   = '/calculator/converters';
  static const String calcHardness     = '/calculator/hardness';
  static const String calcTruePosition = '/calculator/true-position';
  static const String calcWeight        = '/calculator/weight';
  static const String calcQuiz          = '/calculator/quiz';
  static const String calcToolWear      = '/calculator/tool-wear';
  static const String gcodeAnalyzer  = '/gcode';
  static const String gcodeResult    = '/gcode/result';
  static const String gcodeHistory   = '/gcode/history';
  static const String knowledgeBase  = '/knowledge';
  static const String errorReference  = '/knowledge/errors';
  static const String gcodeReference  = '/knowledge/gcodes';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String profile        = '/profile';
  static const String history        = '/history';
  static const String settings       = '/settings';
  static const String subscription   = '/subscription';
}

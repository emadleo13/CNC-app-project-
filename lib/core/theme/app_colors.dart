import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background layers (dark industrial theme)
  static const Color background    = Color(0xFF0E1117);
  static const Color surface       = Color(0xFF161B22);
  static const Color surfaceAlt    = Color(0xFF21262D);
  static const Color border        = Color(0xFF30363D);

  // Primary accent - steel blue
  static const Color primary       = Color(0xFF58A6FF);
  static const Color primaryDim    = Color(0xFF1F6FEB);

  // G-code syntax colors
  static const Color gcodeG        = Color(0xFF79C0FF); // G-codes: blue
  static const Color gcodeM        = Color(0xFFFF9E3D); // M-codes: orange
  static const Color gcodeAddr     = Color(0xFFE3B341); // Addresses (X,Y,Z,F,S): yellow
  static const Color gcodeValue    = Color(0xFFE6EDF3); // Numeric values: white
  static const Color gcodeComment  = Color(0xFF8B949E); // Comments: grey
  static const Color gcodeN        = Color(0xFF8B949E); // Line numbers: grey
  static const Color gcodeCycle    = Color(0xFFD2A8FF); // Sinumerik cycles: purple

  // Status colors
  static const Color errorRed      = Color(0xFFF85149);
  static const Color warningYellow = Color(0xFFE3B341);
  static const Color successGreen  = Color(0xFF3FB950);
  static const Color infoBlue      = Color(0xFF58A6FF);

  // Text
  static const Color textPrimary   = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted     = Color(0xFF484F58);

  // Offline banner
  static const Color offlineBg     = Color(0xFF3D1F00);
  static const Color offlineText   = Color(0xFFE3B341);
}

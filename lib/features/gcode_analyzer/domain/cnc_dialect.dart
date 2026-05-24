enum CncDialect { haas, sinumerik, generic }

extension CncDialectExt on CncDialect {
  String get displayName {
    switch (this) {
      case CncDialect.haas:      return 'Haas';
      case CncDialect.sinumerik: return 'Siemens Sinumerik';
      case CncDialect.generic:   return 'Generic ISO';
    }
  }

  String get shortName {
    switch (this) {
      case CncDialect.haas:      return 'HAAS';
      case CncDialect.sinumerik: return 'SINUMERIK';
      case CncDialect.generic:   return 'ISO';
    }
  }
}

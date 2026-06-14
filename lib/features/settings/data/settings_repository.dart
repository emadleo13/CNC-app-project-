import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsRepository {
  static const _storage = FlutterSecureStorage();

  static const _keyLocale  = 'locale';
  static const _keyUnits   = 'units';
  static const _keyDialect = 'dialect';
  static const _keyName    = 'user_name';

  Future<Map<String, String?>> loadAll() async {
    return {
      'locale':  await _storage.read(key: _keyLocale),
      'units':   await _storage.read(key: _keyUnits),
      'dialect': await _storage.read(key: _keyDialect),
      'name':    await _storage.read(key: _keyName),
    };
  }

  Future<void> saveLocale(String locale)   => _storage.write(key: _keyLocale,  value: locale);
  Future<void> saveUnits(String units)     => _storage.write(key: _keyUnits,   value: units);
  Future<void> saveDialect(String dialect) => _storage.write(key: _keyDialect, value: dialect);
  Future<void> saveName(String name)       => _storage.write(key: _keyName,    value: name);
}

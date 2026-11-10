import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The user's settings, kept only on this phone.
class Prefs {
  static const _storage = FlutterSecureStorage();
  static const _visibleKey = 'visible';

  /// Whether other phones can find this one in Nearby. Hidden phones still look for others.
  static bool visible = true;

  static Future<void> load() async {
    visible = await _storage.read(key: _visibleKey) != 'false';
  }

  static Future<void> setVisible(bool value) async {
    visible = value;
    await _storage.write(key: _visibleKey, value: '$value');
  }
}

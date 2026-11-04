import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// The user's anonymous ID: 8 random hex characters, created once and kept only on this phone.
class Identity {
  static const _key = 'anon_id';
  static const _storage = FlutterSecureStorage();

  static late String myId;

  static Future<void> load() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      myId = saved;
      return;
    }
    myId = const Uuid().v4().replaceAll('-', '').substring(0, 8).toUpperCase();
    await _storage.write(key: _key, value: myId);
  }
}

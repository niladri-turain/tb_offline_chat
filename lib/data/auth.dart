import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';

/// The logged-in session, kept only on this phone: access token, its expiry, user ID and mobile.
///
/// The number is never broadcast; other phones still only see the anonymous ID.
class Auth {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _expiresAtKey = 'auth_expires_at';
  static const _userIdKey = 'auth_user_id';
  static const _mobileKey = 'auth_mobile';
  static const _legacyPhoneKey = 'auth_phone';

  static const otpLength = 4;

  static String? token;
  static String tokenType = 'Bearer';
  static DateTime? expiresAt;
  static int? userId;

  /// The verified number as the server returns it, e.g. +917059238072.
  static String? mobile;

  /// True while a token is saved and hasn't expired.
  static bool get loggedIn => token != null && expiresAt != null && DateTime.now().isBefore(expiresAt!);

  static Future<void> load() async {
    final values = await _storage.readAll();
    token = values[_tokenKey];
    tokenType = values[_tokenTypeKey] ?? 'Bearer';
    expiresAt = DateTime.tryParse(values[_expiresAtKey] ?? '');
    userId = int.tryParse(values[_userIdKey] ?? '');
    mobile = values[_mobileKey];
    if (token != null && !loggedIn) await logOut();
  }

  static Future<void> saveSession(VerifyOtpResponse session) async {
    token = session.accessToken;
    tokenType = session.tokenType;
    expiresAt = DateTime.now().add(Duration(seconds: session.expiresIn));
    userId = session.user.id;
    mobile = session.user.mobile;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _tokenTypeKey, value: tokenType);
    await _storage.write(key: _expiresAtKey, value: expiresAt!.toIso8601String());
    await _storage.write(key: _userIdKey, value: '$userId');
    await _storage.write(key: _mobileKey, value: mobile);
  }

  /// Expires the token here: it is deleted from this phone. Chats and the anonymous ID stay.
  static Future<void> logOut() async {
    clearMemory();
    for (final key in [_tokenKey, _tokenTypeKey, _expiresAtKey, _userIdKey, _mobileKey, _legacyPhoneKey]) {
      await _storage.delete(key: key);
    }
  }

  /// Forgets the session in memory only, for when secure storage was already wiped.
  static void clearMemory() {
    token = null;
    tokenType = 'Bearer';
    expiresAt = null;
    userId = null;
    mobile = null;
  }
}

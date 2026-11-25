import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../data/auth.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';
import '../widgets/app_toast.dart';

/// Login state for the screens: sends and checks the OTP, shows the result as a toast.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  bool _sendingOtp = false;
  bool _verifying = false;

  bool get sendingOtp => _sendingOtp;
  bool get verifying => _verifying;
  bool get loggedIn => Auth.loggedIn;
  int? get userId => Auth.userId;
  String? get mobile => Auth.mobile;

  /// Null when it failed; the error was already shown.
  Future<SendOtpResponse?> sendOtp(String mobile) async {
    if (_sendingOtp) return null;
    _sendingOtp = true;
    notifyListeners();
    try {
      final response = await _repository.sendOtp(mobile);
      AppToast.success(response.message);
      return response;
    } on ApiException catch (e) {
      AppToast.error(e.message);
      return null;
    } finally {
      _sendingOtp = false;
      notifyListeners();
    }
  }

  /// Null when it failed; the error was already shown.
  Future<VerifyOtpResponse?> verifyOtp(String mobile, String otp) async {
    if (_verifying) return null;
    _verifying = true;
    notifyListeners();
    try {
      final session = await _repository.verifyOtp(mobile, otp);
      AppToast.success('Number verified');
      return session;
    } on ApiException catch (e) {
      final left = e.attemptsRemaining;
      AppToast.error(left == null ? e.message : '${e.message} $left ${left == 1 ? 'attempt' : 'attempts'} left.');
      return null;
    } finally {
      _verifying = false;
      notifyListeners();
    }
  }

  /// Expires the token on this phone. Chats stay.
  Future<void> logOut() async {
    await _repository.logOut();
    notifyListeners();
  }

  /// Deletes the account on the server. Returns the server's message, or null when it failed
  /// (the error was already shown). The success toast is left to the caller, to show after local data is wiped.
  Future<String?> deleteAccount() async {
    try {
      return await _repository.deleteAccount();
    } on ApiException catch (e) {
      AppToast.error(e.message);
      return null;
    }
  }

  /// After the account is deleted and the phone wiped, which already cleared secure storage.
  void sessionErased() {
    Auth.clearMemory();
    notifyListeners();
  }
}

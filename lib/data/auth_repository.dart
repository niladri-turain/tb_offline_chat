import '../core/api/api_endpoints.dart';
import '../core/api/api_service.dart';
import '../models/auth_models.dart';
import 'auth.dart';

/// Mobile-number login against the TB Chat API. Errors come out as `ApiException`.
class AuthRepository {
  AuthRepository(this._api);

  final ApiService _api;

  /// [mobile] is the 10-digit number without the country code, e.g. 7059238072.
  Future<SendOtpResponse> sendOtp(String mobile) async {
    final json = await _api.post(ApiEndpoints.sendOtp, body: {'mobile': mobile});
    return SendOtpResponse.fromJson(json);
  }

  /// Checks the code and, when it is right, saves the token, user ID and mobile on this phone.
  Future<VerifyOtpResponse> verifyOtp(String mobile, String otp) async {
    final json = await _api.post(ApiEndpoints.verifyOtp, body: {'mobile': mobile, 'otp': otp});
    final session = VerifyOtpResponse.fromJson(json);
    await Auth.saveSession(session);
    return session;
  }

  /// `DELETE /api/v1/auth/delete-account` with only the token header. Returns the server's message.
  Future<String> deleteAccount() async {
    final json = await _api.delete(ApiEndpoints.deleteAccount);
    return json['message'] as String? ?? 'Your account has been deleted successfully.';
  }

  /// There is no logout endpoint: the token is expired by deleting it from this phone.
  Future<void> logOut() => Auth.logOut();
}

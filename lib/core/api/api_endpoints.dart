/// Server address and every API path the app calls.
class ApiEndpoints {
  ApiEndpoints._();

  /// Change it here, or pass it at build time:
  /// `flutter run --dart-define=BASE_URL=https://api.example.com`
  /// (10.0.2.2 is the computer running the Android emulator.)
  static const baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://tbchat.smscannon.in/');

  // Mobile app auth
  static const sendOtp = 'api/v1/auth/send-otp';
  static const verifyOtp = 'api/v1/auth/verify-otp';
}

/// A failed API call, with the message to show the user.
///
/// The server sends errors as:
/// `{"error": {"code": "INVALID_OTP", "message": "The OTP is incorrect.", "attemptsRemaining": 4}}`
class ApiException implements Exception {
  ApiException({required this.message, this.code, this.statusCode, this.attemptsRemaining});

  final String message;

  /// Server error code such as `INVALID_OTP`, or `NETWORK_ERROR` / `TIMEOUT` / `BAD_RESPONSE` from the app.
  final String? code;

  /// HTTP status, null when the server was never reached.
  final int? statusCode;
  final int? attemptsRemaining;

  factory ApiException.fromResponse(int statusCode, Object? body) {
    final error = body is Map<String, dynamic> ? body['error'] : null;
    if (error is Map<String, dynamic>) {
      return ApiException(
        statusCode: statusCode,
        code: error['code'] as String?,
        message: error['message'] as String? ?? 'Something went wrong. Please try again.',
        attemptsRemaining: (error['attemptsRemaining'] as num?)?.toInt(),
      );
    }
    final message = body is Map<String, dynamic> ? body['message'] as String? : null;
    return ApiException(
      statusCode: statusCode,
      message: message ?? 'Something went wrong ($statusCode). Please try again.',
    );
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

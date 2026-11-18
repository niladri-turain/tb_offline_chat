/// `POST /api/v1/auth/send-otp` → 200
/// `{"message": "OTP sent successfully.", "mobile": "+917059238072", "expiresIn": 300, "resendAfter": 60}`
class SendOtpResponse {
  SendOtpResponse({required this.message, required this.mobile, required this.expiresIn, required this.resendAfter});

  final String message;
  final String mobile;

  /// Seconds until the code stops working.
  final int expiresIn;

  /// Seconds before a new code can be asked for.
  final int resendAfter;

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) => SendOtpResponse(
        message: json['message'] as String? ?? 'OTP sent successfully.',
        mobile: json['mobile'] as String? ?? '',
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 300,
        resendAfter: (json['resendAfter'] as num?)?.toInt() ?? 60,
      );
}

/// `POST /api/v1/auth/verify-otp` → 200
/// `{"accessToken": "…", "tokenType": "Bearer", "expiresIn": 86400, "isNewUser": true, "user": {…}}`
class VerifyOtpResponse {
  VerifyOtpResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.isNewUser,
    required this.user,
  });

  final String accessToken;
  final String tokenType;

  /// Seconds the token stays valid.
  final int expiresIn;
  final bool isNewUser;
  final AppUser user;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) => VerifyOtpResponse(
        accessToken: json['accessToken'] as String,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 86400,
        isNewUser: json['isNewUser'] as bool? ?? false,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// `{"id": 2, "mobile": "+917059238072", "status": "active", "registeredAt": "…", "lastLoginAt": "…"}`
class AppUser {
  AppUser({required this.id, required this.mobile, required this.status, this.registeredAt, this.lastLoginAt});

  final int id;
  final String mobile;
  final String status;
  final DateTime? registeredAt;
  final DateTime? lastLoginAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        mobile: json['mobile'] as String,
        status: json['status'] as String? ?? 'active',
        registeredAt: DateTime.tryParse(json['registeredAt'] as String? ?? ''),
        lastLoginAt: DateTime.tryParse(json['lastLoginAt'] as String? ?? ''),
      );
}

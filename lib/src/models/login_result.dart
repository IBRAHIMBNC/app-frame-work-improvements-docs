import 'package:sc_appframework/src/models/auth_account.dart';
import 'package:sc_appframework/src/models/failure.dart';
import 'package:sc_appframework/src/models/login_status_codes.dart';

/// Result class for login operations that may return special status codes
class LoginResult {
  final AuthAccount? account;
  final Failure? failure;
  final int? specialStatusCode; // 212 for password expired, 213 for 2FA required
  final String? message; // Optional message from server

  LoginResult({
    this.account,
    this.failure,
    this.specialStatusCode,
    this.message,
  });

  bool get isSuccess => account != null && failure == null && specialStatusCode == null;
  bool get isPasswordExpired => specialStatusCode == LoginStatusCodes.passwordExpired;
  bool get isTwoFactorRequired => specialStatusCode == LoginStatusCodes.twoFactorRequired;
  bool get isFailure => failure != null && specialStatusCode == null;
}

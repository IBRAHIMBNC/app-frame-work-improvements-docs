import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:sc_appframework/src/models/auth_account.dart';
import 'package:sc_appframework/src/models/auth_api_device_log.dart';
import 'package:sc_appframework/src/models/change_password_request.dart';
import 'package:sc_appframework/src/models/change_pin_request.dart';
import 'package:sc_appframework/src/models/failure.dart';
import 'package:sc_appframework/src/models/file_payload.dart';
import 'package:sc_appframework/src/models/login_pin_request.dart';
import 'package:sc_appframework/src/models/login_qr_request.dart';
import 'package:sc_appframework/src/models/login_result.dart';
import 'package:sc_appframework/src/models/login_status_codes.dart';
import 'package:sc_appframework/src/network/sc_network_api.dart';

class ScAuthService {
  final SCNetworkApi _networkApi;

  ScAuthService({SCNetworkApi? networkApi})
      : _networkApi = networkApi ?? SCNetworkApi();

  /// Login using QR code and PIN
  /// 
  /// Returns a [LoginResult] which may contain:
  /// - Success: account is set, no special status code
  /// - Password expired (212): account is set, but password needs to be changed
  /// - 2FA required (213): account is set, but 2FA needs to be set up
  /// - Failure: failure is set with error details
  Future<LoginResult> loginQr({
    required String qrCodeData,
    required String pin,
    String route = '/auth/login-qr',
  }) async {
    final request = LoginQrRequest(
      qrCodeData: qrCodeData,
      pin: pin,
    );

    final result = await _networkApi.request<AuthAccount>(
      Method.POST,
      route,
      body: jsonEncode(request.toJson()),
      serializer: (json) => AuthAccount.fromJson(json),
      responseType: ResponseType.SINGLE,
    );

    return result.fold(
      (failure) {
        // Check if this is a special status code (212 or 213)
        // These come as failures because status != 1, but they contain account data
        if (failure.internalStatusCode == LoginStatusCodes.passwordExpired ||
            failure.internalStatusCode == LoginStatusCodes.twoFactorRequired) {
          // Try to parse account from the response body (stored in errorMessage)
          AuthAccount? account;
          String? message;
          
          try {
            final responseBody = jsonDecode(failure.errorMessage ?? '{}') as Map<String, dynamic>;
            message = responseBody['message'] as String?;
            
            final accountData = responseBody['data'] ?? responseBody;
            account = AuthAccount.fromJson(accountData as Map<String, dynamic>);
          } catch (e) {
            try {
              final responseBody = jsonDecode(failure.errorMessage ?? '{}') as Map<String, dynamic>;
              account = AuthAccount.fromJson(responseBody);
            } catch (e2) {
              // Ignore parsing errors - account will remain null
            }
          }

          return LoginResult(
            account: account,
            failure: null,
            specialStatusCode: failure.internalStatusCode,
            message: message,
          );
        }

        // Regular failure
        return LoginResult(
          account: null,
          failure: failure,
          specialStatusCode: null,
        );
      },
      (account) {
        // Success case
        return LoginResult(
          account: account,
          failure: null,
          specialStatusCode: null,
        );
      },
    );
  }

  /// Login using username and PIN
  /// 
  /// Returns a [LoginResult] which may contain:
  /// - Success: account is set, no special status code
  /// - Password expired (212): account is set, but password needs to be changed
  /// - 2FA required (213): account is set, but 2FA needs to be set up
  /// - Failure: failure is set with error details
  Future<LoginResult> loginPin({
    required String username,
    required String pin,
    String route = '/auth/login-pin',
  }) async {
    final request = LoginPinRequest(
      username: username,
      pin: pin,
    );

    final result = await _networkApi.request<AuthAccount>(
      Method.POST,
      route,
      body: jsonEncode(request.toJson()),
      serializer: (json) => AuthAccount.fromJson(json),
      responseType: ResponseType.SINGLE,
    );

    return result.fold(
      (failure) {
        // Check if this is a special status code (212 or 213)
        // These come as failures because status != 1, but they contain account data
        if (failure.internalStatusCode == LoginStatusCodes.passwordExpired ||
            failure.internalStatusCode == LoginStatusCodes.twoFactorRequired) {
          // Try to parse account from the response body (stored in errorMessage)
          AuthAccount? account;
          String? message;
          
          try {
            final responseBody = jsonDecode(failure.errorMessage ?? '{}') as Map<String, dynamic>;
            message = responseBody['message'] as String?;
            
            final accountData = responseBody['data'] ?? responseBody;
            account = AuthAccount.fromJson(accountData as Map<String, dynamic>);
          } catch (e) {
            try {
              final responseBody = jsonDecode(failure.errorMessage ?? '{}') as Map<String, dynamic>;
              account = AuthAccount.fromJson(responseBody);
            } catch (e2) {
              // Ignore parsing errors - account will remain null
            }
          }

          return LoginResult(
            account: account,
            failure: null,
            specialStatusCode: failure.internalStatusCode,
            message: message,
          );
        }

        // Regular failure
        return LoginResult(
          account: null,
          failure: failure,
          specialStatusCode: null,
        );
      },
      (account) {
        // Success case
        return LoginResult(
          account: account,
          failure: null,
          specialStatusCode: null,
        );
      },
    );
  }

  /// Change password for the authenticated user
  /// 
  /// Returns [Either] with:
  /// - Right: Updated [AuthAccount] on success
  /// - Left: [Failure] on error
  Future<Either<Failure, AuthAccount>> changePassword({
    required String passwordX,
    required String passwordRepeat,
    String route = '/auth/accounts/change-password',
  }) async {
    final request = ChangePasswordRequest(
      passwordX: passwordX,
      passwordRepeat: passwordRepeat,
    );

    final result = await _networkApi.request<AuthAccount>(
      Method.POST,
      route,
      body: jsonEncode(request.toJson()),
      serializer: (json) => AuthAccount.fromJson(json),
      responseType: ResponseType.SINGLE,
    );

    return result.fold(
      (failure) => Left<Failure, AuthAccount>(failure),
      (account) => Right<Failure, AuthAccount>(account as AuthAccount),
    );
  }

  /// Change PIN for the authenticated user
  /// 
  /// Returns [Either] with:
  /// - Right: Updated [AuthAccount] on success
  /// - Left: [Failure] on error
  Future<Either<Failure, AuthAccount>> changePin({
    required String pinX,
    required String pinRepeat,
    String route = '/auth/accounts/change-pin',
  }) async {
    final request = ChangePinRequest(
      pinX: pinX,
      pinRepeat: pinRepeat,
    );

    final result = await _networkApi.request<AuthAccount>(
      Method.POST,
      route,
      body: jsonEncode(request.toJson()),
      serializer: (json) => AuthAccount.fromJson(json),
      responseType: ResponseType.SINGLE,
    );

    return result.fold(
      (failure) => Left<Failure, AuthAccount>(failure),
      (account) => Right<Failure, AuthAccount>(account as AuthAccount),
    );
  }

  /// Upload device logs
  /// 
  /// Returns [Either] with:
  /// - Right: List of [AuthApiDeviceLog] on success
  /// - Left: [Failure] on error
  Future<Either<Failure, List<AuthApiDeviceLog>>> uploadDeviceLogs({
    required List<String> logFilePaths,
    String route = '/auth/apis/device-logs/upload',
    void Function(int bytes, int totalBytes)? onProgress,
    bool deleteFilesAfterUpload = false,
  }) async {
    if (logFilePaths.isEmpty) {
      return Left<Failure, List<AuthApiDeviceLog>>(
        Failure(400, -1, 'No log files provided'),
      );
    }

    // Verify all files exist
    for (var filePath in logFilePaths) {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left<Failure, List<AuthApiDeviceLog>>(
          Failure(400, -1, 'File not found: $filePath'),
        );
      }
    }

    final filePayload = FilePayload(
      logFilePaths,
      {}, // No additional params needed
      deleteFile: deleteFilesAfterUpload,
      fieldName: 'file', // Field name for log file uploads
    );

    final result = await _networkApi.request<AuthApiDeviceLog>(
      Method.MULTIPART,
      route,
      filePayload: filePayload,
      serializer: (json) => AuthApiDeviceLog.fromJson(json),
      responseType: ResponseType.LIST,
      onProgress: onProgress,
    );

    return result.fold(
      (failure) => Left<Failure, List<AuthApiDeviceLog>>(failure),
      (logs) => Right<Failure, List<AuthApiDeviceLog>>(
        logs as List<AuthApiDeviceLog>,
      ),
    );
  }
}

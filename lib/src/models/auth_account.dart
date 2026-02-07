import 'package:sc_appframework/src/models/sc_core.dart';

class AuthAccount extends SCCore {
  final String username;
  final bool isPasswordExpired;
  final bool need2Fa;
  final bool is2FaActive;
  final String? pinX; // PIN wird nur beim Login gesetzt, nicht in Response

  AuthAccount({
    required super.id,
    required this.username,
    this.isPasswordExpired = false,
    this.need2Fa = false,
    this.is2FaActive = false,
    this.pinX,
    super.createdAt,
    super.updatedAt,
    super.order,
    super.isCache,
  });

  factory AuthAccount.fromJson(Map<String, dynamic> json) {
    return AuthAccount(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      isPasswordExpired: json['is_password_expired'] ?? false,
      need2Fa: json['need_2fa'] ?? false,
      is2FaActive: json['is_2fa_active'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      order: json['order_value'] ?? 0,
      isCache: false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'username': username,
      'is_password_expired': isPasswordExpired,
      'need_2fa': need2Fa,
      'is_2fa_active': is2FaActive,
    });
    return json;
  }
}

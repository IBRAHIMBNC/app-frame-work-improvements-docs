import 'package:sc_appframework/src/models/sc_core.dart';

class AuthApiDeviceLog extends SCCore {
  final String logFilename;

  AuthApiDeviceLog({
    required super.id,
    required this.logFilename,
    super.createdAt,
    super.updatedAt,
    super.order,
    super.isCache,
  });

  factory AuthApiDeviceLog.fromJson(Map<String, dynamic> json) {
    return AuthApiDeviceLog(
      id: json['id']?.toString() ?? '',
      logFilename: json['log_filename'] ?? '',
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
      'log_filename': logFilename,
    });
    return json;
  }
}

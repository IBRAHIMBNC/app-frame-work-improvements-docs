class AuthApi {
  final String _id;
  final int _versionCode;
  final String _versionName;
  final bool _isUpdateAvailable;
  final String _clientUrl;

  String getId() {
    return _id;
  }

  int getVersionCode() {
    return _versionCode;
  }

  String getVersionName() {
    return _versionName;
  }

  bool isUpdateAvailable() {
    return _isUpdateAvailable;
  }

  String getClientUrl() {
    return _clientUrl;
  }

  AuthApi.fromJson(Map<String, dynamic> json)
      : _id = json['app'] == null || json['app']['id'] == null
            ? ''
            : json['app']['id'].toString(),
        _versionCode =
            json['app'] == null || json['app']['version_code'] == null
                ? 0
                : json['app']['version_code'],
        _versionName =
            json['app'] == null || json['app']['version_name'] == null
                ? ''
                : json['app']['version_name'],
        _isUpdateAvailable = json['is_update_available'] ?? false,
        _clientUrl = json['app'] == null || json['app']['client_url'] == null
            ? ''
            : json['app']['client_url'];
}

import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:http/http.dart';
import 'package:open_filex/open_filex.dart';
import 'package:sc_appframework/src/models/auth_api.dart';
import 'package:sc_appframework/src/models/failure.dart';
import 'package:sc_appframework/src/network/sc_network_api.dart';
import 'package:sc_appframework/src/storage/sc_internal_storage.dart';
import 'package:sc_appframework/src/storage/sc_shared_prefs_storage.dart';

class SCUpdate {
  AuthApi? _serverVersion;
  int _currentVersionCode = 0;

  static final SCUpdate _scUpdate = SCUpdate._internal();

  factory SCUpdate() {
    return _scUpdate;
  }

  SCUpdate._internal() {
    if (SCSharedPrefStorage.readInt('sc_version_code') != null) {
      _currentVersionCode = SCSharedPrefStorage.readInt('sc_version_code')!;
    }
  }

  AuthApi? get serverVersion => _serverVersion;

  setVersionCode(int versionCode) {
    SCSharedPrefStorage.saveData('sc_version_code', versionCode);
    _currentVersionCode = versionCode;
  }

  checkForUpdate({
    String route = "/auth/apps/check",
  }) async {
    Either<Failure, dynamic> result = await SCNetworkApi().request(
      Method.GET,
      route,
      serializer: (value) => AuthApi.fromJson(value),
      params: {'version_code': _currentVersionCode.toString()},
    );

    result.fold(
      (l) {},
      (r) {
        _serverVersion = r;
      },
    );
  }

  Future<bool> isUpdateAvailable() async {
    if (_serverVersion == null ||
        _serverVersion!.getVersionCode() <= _currentVersionCode) {
      await checkForUpdate();
    }
    if (_serverVersion != null) {
      return _serverVersion!.isUpdateAvailable();
    } else {
      return false;
    }
  }

  Future<File?> downloadUpdate() async {
    File? file;
    if (_serverVersion != null &&
        _serverVersion!.isUpdateAvailable() &&
        _serverVersion!.getClientUrl() != '') {
      Either<Failure, dynamic> result = await SCNetworkApi().request(
        Method.GET,
        _serverVersion!.getClientUrl(),
        timeoutSeconds: 600,
      );

      await result.fold(
        (l) {},
        (r) async {
          Response response = r;
          file = await SCInternalStorage.saveBytesAsFile(
              '', 'app.apk', response.bodyBytes);
          if (file != null) {
            SCSharedPrefStorage.saveData('sc_update_path', file!.path);
          }
        },
      );
    }
    return file;
  }

  bool isUpdateDownloaded() {
    return SCSharedPrefStorage.readString('sc_update_path') != null &&
        SCSharedPrefStorage.readString('sc_update_path') != '';
  }

  installUpdate() async {
      String? file = SCSharedPrefStorage.readString('sc_update_path');
      if (file != null && file != '') {
        OpenResult openResult = await OpenFilex.open(file);
        print(openResult.type);
        print(openResult.message);
        SCSharedPrefStorage.saveData('sc_update_path', '');
      }
    }
}

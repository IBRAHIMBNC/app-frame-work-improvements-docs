import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sc_appframework/sc_appframework.dart';

class SCFileUtils {
  static Future<(HttpHeaders, Uint8List)> downloadFile(String url,
      {Map<String, String>? customHeaders, bool addHeaders = true}) async {
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(Uri.parse(url));

    customHeaders?.forEach((key, value) {
      request.headers.set(key, value);
    });

    if (addHeaders) {
      SCNetworkApi().headers.forEach(
        (key, value) {
          request.headers.set(key, value);
        },
      );
    }

    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    return (response.headers, bytes);
  }

  static Future<File> fileFromUint8List(Uint8List data, String filename) async {
    final tempDir = await getTemporaryDirectory();
    File file = await File('${tempDir.path}/$filename').create(recursive: true);
    file.writeAsBytesSync(data);
    return file;
  }

  static Future<String> createFolderInAppDocDir(
    String folderName,
  ) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    //App Document Directory + folder name
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$folderName/');

    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      return _appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  static Future<void> deleteFilesInDir(String path) async {
    try {
      final dir = Directory(path);
      dir.deleteSync(recursive: true);
    } catch (e) {
      // File couldn't be deleted (doesn't exist, no access to it?)
    }
  }

  static Future<File> createFile(String fileName) async {
    final Directory _appDocDir = await getApplicationDocumentsDirectory();

    File file = File('${_appDocDir.path}/$fileName');
    return await file.create();
  }

  static Future<File> saveJsonInFile(String filename, String jsonString,
      {String filePath = ""}) async {
    filename = filename.endsWith(".json") ? filename : (filename + ".json");

    if (filePath.isEmpty) {
      final Directory _appDocDir = await getApplicationDocumentsDirectory();
      filePath = _appDocDir.path;
    }
    File file = File(filePath + "/" + filename);
    return await file.create();
  }
}

import 'dart:io';

import 'package:path_provider/path_provider.dart';

class SCInternalStorage {
  static Future<File> saveStringAsFile(
      String path, String fileName, String content) async {
    File file = await getFile(path, fileName);
    return file.writeAsString(content);
  }

  static Future<File> saveBytesAsFile(
      String path, String fileName, List<int> bytes) async {
    File file = await getFile(path, fileName);
    return file.writeAsBytes(bytes);
  }

  static Future<String> readFileAsString(String path, String fileName) async {
    try {
      File file = await getFile(path, fileName);
      String fileInput = await file.readAsString();
      return fileInput;
    } catch (e) {
      return '';
    }
  }

  static Future<List<int>> readFileAsBytes(String path, String fileName) async {
    try {
      File file = await getFile(path, fileName);
      return file.readAsBytes();
    } catch (e) {
      return [];
    }
  }

  static Future<File> getFile(String path, String fileName) async {
    late File file;
    if (path == '') {
      final directory = await getApplicationDocumentsDirectory();
      file = File('${directory.path}/$fileName');
    } else {
      file = File('$path/$fileName');
    }
    return file;
  }

  static Future<void> deleteFile(String path, String fileName) async {
    late File file;
    if (path == '') {
      final directory = await getApplicationDocumentsDirectory();
      file = File('${directory.path}/$fileName');
    } else {
      file = File('$path/$fileName');
    }
    await file.delete();
  }
}

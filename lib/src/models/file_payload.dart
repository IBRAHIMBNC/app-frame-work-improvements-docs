import 'dart:convert';

class FilePayload {
  List<String> filePaths;
  Map<String, String> params;
  bool deleteFile = false;
  String fieldName; // Field name for multipart upload (default: "image")

  FilePayload(
    this.filePaths,
    this.params, {
    this.deleteFile = false,
    this.fieldName = 'image',
  });

  Map<String, dynamic> toJson() {
    return {
      "file_paths": filePaths,
      "params": params,
      "delete_file": deleteFile,
      "field_name": fieldName,
    };
  }

  factory FilePayload.fromJson(Map<String, dynamic> json) {
    return FilePayload(
      json["file_paths"].cast<String>(),
      jsonDecode(jsonEncode(json["params"])).cast<String, String>(),
      deleteFile: json["delete_file"] ?? false,
      fieldName: json["field_name"] ?? 'image',
    );
  }
}

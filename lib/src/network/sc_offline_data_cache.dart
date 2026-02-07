import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:sc_appframework/src/models/failure.dart';
import 'package:sc_appframework/src/models/list_response.dart';
import 'package:sc_appframework/src/models/single_response.dart';
import 'package:sc_appframework/src/network/sc_network_api.dart';
import 'package:sc_appframework/src/storage/sc_internal_storage.dart';

class SCOfflineDataCache {
  static Future<File?> cacheDataFromNetwork({
    required String route,
    required String model,
    Method method = Method.GET,
    Map<String, String> headers = const {},
    dynamic body,
    Map<String, String?> params = const {},
    bool enableLog = false,
    bool enableBodyLog = false,
    bool decodeUtf8 = false,
    ResponseType responseType = ResponseType.LIST,
  }) async {
    Either<Failure, dynamic> result = await SCNetworkApi().request(
      method,
      route,
      responseType: responseType,
      decodeUtf8: decodeUtf8,
      headers: headers,
      body: body,
      params: params,
      enableLog: enableLog,
      enableBodyLog: enableBodyLog,
    );

    File? file;

    await result.fold((l) {}, (r) async {
      Map<String, dynamic> json;

      if (decodeUtf8) {
        json = jsonDecode(utf8.decode(r.bodyBytes));
      } else {
        json = jsonDecode(r.body);
      }
      file = await SCInternalStorage.saveStringAsFile(
          '', '$model.json', jsonEncode(json['data']));
    });

    return file;
  }

  static Future<dynamic> getCachedData({
    required String model,
    Function(dynamic)? serializer,
    ResponseType responseType = ResponseType.LIST,
  }) async {
    String data = await SCInternalStorage.readFileAsString('', '$model.json');
    if (serializer == null) {
      return data;
    } else {
      Map<String, dynamic> jsonMap = {'data': jsonDecode(data)};
      dynamic result;
      switch (responseType) {
        case ResponseType.SINGLE:
          result =
              SingleResponse.fromJson(jsonMap, serializer, ["data"], true).data;
          break;
        case ResponseType.LIST:
          result =
              ListResponse.fromJson(jsonMap, serializer, ["data"], true).data;
          break;
      }
      return result;
    }
  }
}

import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:sc_appframework/src/network/sc_network_api.dart';

import 'file_payload.dart';

class SCCachedRequest {
  int requestId;
  Method method;
  String route;
  dynamic body;
  Map<String, String?> params = const {};
  ResponseType responseType = ResponseType.SINGLE;
  bool raw = false;
  int? paging;
  int perPage = 30;
  String? searchQuery;
  List<String>? searchIn;
  bool retry = false;
  FilePayload? filePayload;
  Map<String, String> headers = {};
  int timeoutSeconds;

  SCCachedRequest(
    this.requestId,
    this.method,
    this.route,
    this.body,
    this.params,
    this.responseType,
    this.raw,
    this.paging,
    this.perPage,
    this.searchQuery,
    this.searchIn,
    this.retry,
    this.filePayload,
    this.headers,
    this.timeoutSeconds,
  );

  Map<String, dynamic> toJson() {
    return {
      "requestId": requestId,
      "method": EnumToString.convertToString(method),
      "route": route,
      "body": body,
      "params": jsonEncode(params),
      "raw": raw,
      "paging": paging,
      "per_page": perPage,
      "search_query": searchQuery,
      "search_in": searchIn,
      "retry": retry,
      "file_payload": filePayload != null ? filePayload!.toJson() : null,
      "headers": jsonEncode(headers),
      "timeout_seconds": timeoutSeconds,
    };
  }

  factory SCCachedRequest.fromJson(Map<String, dynamic> json) {
    Method method = Method.POST;
    switch (json["method"]) {
      case "POST":
        method = Method.POST;
        break;
      case "GET":
        method = Method.GET;
        break;
      case "PUT":
        method = Method.PUT;
        break;
      case "MULTIPART":
        method = Method.MULTIPART;
        break;
      case "DELETE":
        method = Method.DELETE;
        break;
      case "PATCH":
        method = Method.PATCH;
        break;
      default:
    }
    return SCCachedRequest(
      json["requestId"],
      method,
      json["route"],
      json["body"],
      jsonDecode(json["params"]).cast<String, String>(),
      ResponseType.SINGLE,
      json["raw"],
      json["paging"],
      json["per_page"],
      json["search_query"],
      json["search_in"] != null ? List<String>.from(json["search_in"]) : null,
      json["retry"],
      json["file_payload"] != null
          ? FilePayload.fromJson(json["file_payload"].cast<String, dynamic>())
          : null,
      jsonDecode(json["headers"]).cast<String, String>(),
      json["timeout_seconds"],
    );
  }
}

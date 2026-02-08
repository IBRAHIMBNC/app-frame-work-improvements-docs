import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:developer' as devtools show log;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sc_appframework/sc_appframework.dart';

import '../models/list_response.dart';
import '../models/single_response.dart';
import 'adapters/dio_http_adapter.dart';
import 'sc_multipart_request.dart';

extension Log on Object {
  void log() => devtools.log(toString());
}

enum Method { GET, POST, PUT, DELETE, PATCH, MULTIPART }

enum ResponseType {
  LIST,
  SINGLE,
}

class SCNetworkApi {
  int REQUEST_ID = 0;
  String _baseUrl = "";
  final Map<String, String> _headers = {
    "Content-Type": "application/json",
  };
  int _timeoutSeconds = 120;
  bool _enableLog = false;
  bool _enableBodyLog = false;
  bool _enableHeaderLog = false;
  List<SCCachedRequest> _cachedRequests = [];
  List<String> _jsonDataLevel = ["data"];
  Box? _getCacheBox;

  // Dio adapter for improved GET request handling
  DioHttpAdapter? _dioAdapter;
  bool _useDioForGet = false;

  static final SCNetworkApi _instance = SCNetworkApi._internal();
  factory SCNetworkApi() => _instance;

  SCNetworkApi._internal();

  init({
    String baseUrl = '',
    bool enableLog = false,
    bool enableBodyLog = false,
    bool enableHeaderLog = false,
    bool useDioForGet = false, // New parameter to opt-in to Dio for GET
  }) async {
    _enableLog = enableLog;
    _enableBodyLog = enableBodyLog;
    _enableHeaderLog = enableHeaderLog;
    _useDioForGet = useDioForGet;
    this.baseUrl = baseUrl;

    // Initialize Dio adapter if enabled
    if (_useDioForGet) {
      _dioAdapter = DioHttpAdapter(
        timeout: Duration(seconds: _timeoutSeconds),
        headers: Map.from(_headers),
      );
    }

    await Hive.initFlutter("sc_appframework");
    _getCacheBox = await Hive.openBox(SCConstants.HIVE_BOX_GET_CACHE);
  }

  String get baseUrl {
    return _baseUrl;
  }

  set baseUrl(String baseUrl) {
    RegExp regExp = RegExp(r"^(http|https):");
    if (regExp.hasMatch(baseUrl)) {
      _baseUrl = baseUrl;
    }
  }

  Map<String, String> get headers {
    return _headers;
  }

  set headers(Map<String, String> headers) {
    _headers.addAll(headers);
  }

  int get timeoutSeconds {
    return _timeoutSeconds;
  }

  set timeoutSeconds(int seconds) {
    if (seconds > 0) {
      _timeoutSeconds = seconds;
    }
  }

  List<String> get jsonDataLevel {
    return _jsonDataLevel;
  }

  List<SCCachedRequest> get cachedRequests {
    return _cachedRequests;
  }

  set cachedRequests(List<SCCachedRequest> cachedRequest) {
    _cachedRequests = cachedRequest;
  }

  set jsonDataLevel(List<String> jsonDataLevel) {
    _jsonDataLevel = jsonDataLevel;
  }

  void enableLog() {
    _enableLog = true;
  }

  void disableLog() {
    _enableLog = false;
  }

  void enableBodyLog() {
    _enableBodyLog = true;
  }

  void disableBodyLog() {
    _enableBodyLog = false;
  }

  void enableHeaderLog() {
    _enableHeaderLog = true;
  }

  void disableHeaderLog() {
    _enableHeaderLog = false;
  }

  /// Adds an interceptor to the Dio adapter
  /// Only works when useDioForGet is enabled
  void addInterceptor(Interceptor interceptor) {
    if (_dioAdapter == null) {
      throw StateError(
        'Interceptors are only available when useDioForGet is enabled. '
        'Call init(useDioForGet: true) first.',
      );
    }
    _dioAdapter!.addInterceptor(interceptor);
  }

  /// Removes all interceptors from the Dio adapter
  /// Only works when useDioForGet is enabled
  void clearInterceptors() {
    if (_dioAdapter == null) {
      throw StateError(
        'Interceptors are only available when useDioForGet is enabled. '
        'Call init(useDioForGet: true) first.',
      );
    }
    _dioAdapter!.clearInterceptors();
  }

  bool get hasInterceptorSupport => _dioAdapter != null;

  switchCacheBox({required String boxId}) async {
    await _getCacheBox?.close();
    _getCacheBox =
        await Hive.openBox('${SCConstants.HIVE_BOX_GET_CACHE}_$boxId');
  }

  Future<void> serializeRequests() async {
    await SCSharedPrefStorage.saveData(
      SCConstants.STORAGE_CACHE_KEY,
      jsonEncode(_cachedRequests),
    );
  }

  Future<void> deSerializeRequests({bool startCachedRequests = true}) async {
    if (!SCSharedPrefStorage.isInitialized()) {
      await SCSharedPrefStorage().init();
    }

    REQUEST_ID =
        SCSharedPrefStorage.readInt(SCConstants.STORAGE_REQUEST_ID_KEY) ?? 1;
    var requests = jsonDecode(
      SCSharedPrefStorage.readString(SCConstants.STORAGE_CACHE_KEY) ?? "[]",
    );
    _cachedRequests = [];

    requests.forEach(
      (request) {
        _cachedRequests.add(
          SCCachedRequest.fromJson(request),
        );
      },
    );

    if (!startCachedRequests) {
      return;
    }

    for (var cachedRequest in _cachedRequests) {
      request(
        cachedRequest.method,
        cachedRequest.route,
        body: cachedRequest.body,
        params: cachedRequest.params,
        responseType: cachedRequest.responseType,
        raw: cachedRequest.raw,
        page: cachedRequest.paging,
        perPage: cachedRequest.perPage,
        searchQuery: cachedRequest.searchQuery,
        searchIn: cachedRequest.searchIn,
        retry: cachedRequest.retry,
        filePayload: cachedRequest.filePayload,
        requestId: cachedRequest.requestId,
        headers: cachedRequest.headers,
        timeoutSeconds: cachedRequest.timeoutSeconds,
      );
    }
  }

  void addToHeader(Map<String, String> headerEntry) {
    _headers.addAll(headerEntry);
  }

  Future<Either<Failure, dynamic>> request<T>(
    Method method,
    String route, {
    Map<String, String> headers = const {},
    dynamic body,
    Function(dynamic)? serializer,
    Map<String, String?> params = const {},
    Map<String, List<String>> repeatableParams = const {},
    Map<String, String?> filter = const {},
    ResponseType responseType = ResponseType.SINGLE,
    bool raw = false,
    int? page,
    int perPage = 30,
    String? searchQuery,
    List<String>? searchIn,
    bool retry = false,
    bool cacheRequest = false,
    FilePayload? filePayload,
    void Function(int bytes, int totalBytes)? onProgress,
    int requestId = -1,
    bool enableLog = false,
    bool enableBodyLog = false,
    bool enableHeaderLog = false,
    int? timeoutSeconds,
    bool decodeUtf8 = false,
    bool enableGetCache = false,
  }) async {
    Either<Failure, dynamic>? result;
    http.Response? response;
    Map<String, String> requestHeaders = _headers;
    requestHeaders.addAll(headers);

    Uri uri = _buildUri(route, params, page, perPage, searchQuery, searchIn,
        filter, repeatableParams);

    if (enableLog || _enableLog) {
      "URL: ${uri.toString()}".log();
    }

    if (enableBodyLog || _enableBodyLog) {
      "body: $body".log();
    }

    if (enableHeaderLog || _enableHeaderLog) {
      "header: $requestHeaders".log();
    }

    int requestTimeoutSeconds = timeoutSeconds ?? _timeoutSeconds;
    if (cacheRequest) {
      bool requestFound = false;
      if (_cachedRequests.isNotEmpty) {
        for (int i = _cachedRequests.length - 1; i >= 0; i--) {
          if (_cachedRequests[i].requestId == requestId) {
            requestFound = true;
            break;
          }
        }
      }

      if (!requestFound || _cachedRequests.isEmpty) {
        REQUEST_ID++;
        await SCSharedPrefStorage.saveData(
            SCConstants.STORAGE_REQUEST_ID_KEY, REQUEST_ID);
        requestId = requestId == -1 ? REQUEST_ID : requestId;
        SCCachedRequest cachedRequest = SCCachedRequest(
          requestId,
          method,
          uri.toString(),
          body,
          params,
          responseType,
          raw,
          page,
          perPage,
          searchQuery,
          searchIn,
          retry,
          filePayload,
          requestHeaders,
          requestTimeoutSeconds,
        );
        _cachedRequests.add(cachedRequest);
        "REQUEST MIT DER ID: ${cachedRequest.requestId.toString()} wurde hinzugefügt!"
            .log();
      }
      await serializeRequests();
    }

    try {
      response = await _makeRequest(method, uri, body, filePayload, onProgress,
          requestHeaders, requestTimeoutSeconds);
    } catch (e) {
      if (enableGetCache && method == Method.GET) {
        dynamic responseBody;

        try {
          responseBody = jsonDecode(_getCacheBox?.get(uri.toString()));
        } catch (e) {
          e.log();
        }

        if (responseBody != null && serializer != null) {
          switch (responseType) {
            case ResponseType.SINGLE:
              result = Right<Failure, T>(
                SingleResponse<T>.fromJson(
                        responseBody, serializer, jsonDataLevel, true)
                    .data,
              );
              break;
            case ResponseType.LIST:
              result = Right<Failure, List<T>>(
                ListResponse<T>.fromJson(
                        responseBody, serializer, jsonDataLevel, true)
                    .data,
              );
              break;
          }
        } else {
          switch (responseType) {
            case ResponseType.SINGLE:
              result = Left<Failure, T>(
                SCConstants.CacheFailure,
              );
              break;
            case ResponseType.LIST:
              result = Left<Failure, List<T>>(SCConstants.CacheFailure);
              break;
          }
        }
      } else {
        Failure failure = SCConstants.NetworkFailure;
        failure.errorMessage = e.toString();
        switch (responseType) {
          case ResponseType.SINGLE:
            result = Left<Failure, T>(
              failure,
            );
            break;
          case ResponseType.LIST:
            result = Left<Failure, List<T>>(
              failure,
            );
            break;
        }
      }
    }

    Map<String, dynamic> statusAndMessage = {};
    if (response != null) {
      if (serializer != null) {
        try {
          statusAndMessage = jsonDecode(response.body);
        } catch (e) {
          result = Left<Failure, T>(
            Failure(
              response.statusCode,
              -1,
              e.toString(),
            ),
          );
        }
      }
      bool isFailure = false;

      // Failure
      if (response.statusCode != 200) {
        isFailure = true;
      } else if (response.statusCode == 200 &&
          statusAndMessage.containsKey("status") &&
          statusAndMessage["status"] != 1) {
        isFailure = true;
      }

      if (!isFailure) {
        if (_cachedRequests.isNotEmpty) {
          for (int i = _cachedRequests.length - 1; i >= 0; i--) {
            if (_cachedRequests[i].requestId == requestId) {
              _cachedRequests.removeAt(i);
              await serializeRequests();
              break;
            }
          }
        }

        dynamic responseBody;

        try {
          responseBody = decodeUtf8
              ? jsonDecode(utf8.decode(response.bodyBytes))
              : jsonDecode(response.body);
        } catch (e) {
          result = Left<Failure, T>(
            SCConstants.JsonFailure,
          );
        }

        if (enableGetCache && method == Method.GET) {
          _getCacheBox?.put(uri.toString(), jsonEncode(responseBody));
        }

        if (serializer == null) {
          return Right<Failure, http.Response>(response);
        }

        switch (responseType) {
          case ResponseType.SINGLE:
            result = Right<Failure, T>(
              SingleResponse<T>.fromJson(
                      responseBody, serializer, jsonDataLevel, false)
                  .data,
            );
            break;
          case ResponseType.LIST:
            result = Right<Failure, List<T>>(
              ListResponse<T>.fromJson(
                      responseBody, serializer, jsonDataLevel, false)
                  .data,
            );
            break;
        }
      } else {
        // NOT 200 STATUS OR INTERNAL STATUS IS NOT 1
        if (responseType == ResponseType.SINGLE) {
          result = Left<Failure, T>(
            Failure(
              response.statusCode,
              statusAndMessage["status"] ?? 0,
              response.body,
            ),
          );
        } else {
          result = Left<Failure, List<T>>(
            Failure(
              response.statusCode,
              statusAndMessage["status"] ?? 0,
              response.body,
            ),
          );
        }
      }
    }

    if (result!.isLeft()) {
      if (retry) {
        await Future.delayed(const Duration(seconds: 5), () async {
          result = await request(
            method,
            route,
            body: body,
            page: page,
            params: params,
            perPage: perPage,
            raw: raw,
            responseType: responseType,
            retry: retry,
            searchIn: searchIn,
            searchQuery: searchQuery,
            serializer: serializer,
            requestId: requestId,
            filePayload: filePayload,
            onProgress: onProgress,
            cacheRequest: cacheRequest,
            headers: requestHeaders,
            timeoutSeconds: requestTimeoutSeconds,
          );
        });
      }
    }

    return Future.value(result);
  }

  Future<http.Response?> _makeRequest(
    Method method,
    Uri uri,
    dynamic body,
    FilePayload? filePayload,
    void Function(int bytes, int totalBytes)? onProgress,
    Map<String, String> headers,
    int timeoutSeconds,
  ) async {
    http.Response? response;
    switch (method) {
      case Method.GET:
        // Use Dio adapter if enabled, otherwise fall back to http package
        if (_useDioForGet && _dioAdapter != null) {
          if (_enableLog) {
            "Using Dio adapter for GET request".log();
          }
          response = await _dioAdapter!.get(
            uri,
            headers: headers,
            timeout: Duration(seconds: timeoutSeconds),
          );
        } else {
          response = await http
              .get(
            uri,
            headers: headers,
          )
              .timeout(
            Duration(seconds: timeoutSeconds),
            onTimeout: () {
              throw TimeoutException(SCConstants.TIMEOUT_EXCEPTION_MESSAGE);
            },
          );
        }
        break;
      case Method.POST:
        response = await http.post(uri, headers: headers, body: body).timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            throw TimeoutException(SCConstants.TIMEOUT_EXCEPTION_MESSAGE);
          },
        );

        break;
      case Method.PUT:
        response = await http.put(uri, headers: headers, body: body).timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            throw TimeoutException(SCConstants.TIMEOUT_EXCEPTION_MESSAGE);
          },
        );
        break;
      case Method.DELETE:
        response = await http.delete(uri, headers: headers, body: body).timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            throw TimeoutException(SCConstants.TIMEOUT_EXCEPTION_MESSAGE);
          },
        );
        break;
      case Method.PATCH:
        response = await http.patch(uri, headers: headers, body: body).timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            throw TimeoutException(SCConstants.TIMEOUT_EXCEPTION_MESSAGE);
          },
        );
        break;
      case Method.MULTIPART:
        SCMultipartRequest request =
            SCMultipartRequest("POST", uri, onProgress: onProgress);
        request.headers.addAll(headers);

        for (var filePath in filePayload!.filePaths) {
          http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
              filePayload.fieldName, filePath);
          request.files.add(multipartFile);
        }

        request.fields.addAll(filePayload.params);

        http.StreamedResponse streamedResponse = await request
            .send()
            .timeout(Duration(seconds: timeoutSeconds), onTimeout: () {
          throw TimeoutException(SCConstants.TIMEOUT_EXCEPTION_MESSAGE);
        });
        response = await http.Response.fromStream(streamedResponse);
        if (filePayload.deleteFile && response.statusCode == 200) {
          try {
            for (var filePath in filePayload.filePaths) {
              File file = File(filePath);
              if (await file.exists()) {
                await file.delete();
              }
            }
          } catch (e) {
            e.log();
          }
        }
    }

    return response;
  }

  String _paramStringFromMap(Map<String, dynamic> params) {
    String paramString = "";

    if (params.isNotEmpty) {
      paramString = "?";
      params.forEach(
        (key, value) {
          if (value != null) {
            if (key == "search_in" && value is List<String>?) {
              for (var searchIn in value!) {
                paramString += "search_in=" + searchIn + "&";
              }
            } else {
              paramString += key + "=" + value + "&";
            }
          }
        },
      );

      paramString = paramString.substring(0, paramString.length - 1);
    }

    return paramString;
  }

  String _addRepeatableParamsString(
      String paramsString, Map<String, List<String>> repeatableParams) {
    String newParamsString = paramsString;

    if (repeatableParams.isNotEmpty) {
      if (newParamsString.isEmpty) {
        newParamsString = "?";
      } else if (!newParamsString.endsWith("&")) {
        newParamsString = newParamsString + "&";
      }

      repeatableParams.forEach((key, value) {
        for (int i = 0; i < value.length; i++) {
          if (!newParamsString.endsWith("&")) {
            newParamsString = newParamsString + "&";
          }
          newParamsString += "$key=${value[i]}";
        }
      });
    }
    return newParamsString;
  }

  String _addFilterToParamsString(
      String paramsString, Map<String, String?> filter) {
    String newParamsString = paramsString;

    if (filter.isNotEmpty) {
      if (newParamsString.isEmpty) {
        newParamsString = "?";
      } else if (!newParamsString.endsWith("&")) {
        newParamsString = newParamsString + "&";
      }
      filter.forEach((key, value) {
        if (!newParamsString.endsWith("&")) {
          newParamsString = newParamsString + "&";
        }
        newParamsString += "filter=$key,$value";
      });
    }

    return newParamsString;
  }

  Uri _buildUri(
    String route,
    Map<String, String?> params,
    int? page,
    int perPage,
    String? searchQuery,
    List<String>? searchIn,
    Map<String, String?> filter,
    Map<String, List<String>> repeatableParams,
  ) {
    RegExp regExp = RegExp(r"^(http|https):");
    Uri uri;

    String paramsString = "";
    if (!route.contains("?")) {
      Map<String, dynamic> updatedParams = Map.from(params);
      if (page != null) {
        updatedParams
            .addAll({"page": page.toString(), "per_page": perPage.toString()});
      }

      if (searchQuery != null && searchQuery != "") {
        updatedParams.addAll(
          {
            "search": searchQuery,
          },
        );
      }

      if (searchIn != null && searchIn.isNotEmpty) {
        updatedParams.addAll({"search_in": searchIn});
      }

      paramsString = _paramStringFromMap(updatedParams);
      paramsString = _addFilterToParamsString(paramsString, filter);
      paramsString = _addRepeatableParamsString(paramsString, repeatableParams);
    }

    if (!regExp.hasMatch(route)) {
      if (!route.startsWith('/')) {
        route = '/$route';
      }
      uri = Uri.parse(_baseUrl + route + paramsString);
    } else {
      uri = Uri.parse(route + paramsString);
    }

    return uri;
  }

  List<SCCachedRequest> filterCachedRequest({Method? method, String? route}) {
    return method == null && route == null
        ? cachedRequests
        : cachedRequests
            .where(
              (element) =>
                  element.method == method &&
                  (route != null && element.route.contains(route)),
            )
            .toList();
  }
}

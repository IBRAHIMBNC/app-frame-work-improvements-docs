import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

/// Internal adapter that wraps Dio for HTTP requests
/// This provides better error handling, interceptor support, and more features
/// while maintaining compatibility with the existing http.Response interface
class DioHttpAdapter {
  late final Dio _dio;
  final Duration defaultTimeout;
  final Map<String, String> defaultHeaders;

  DioHttpAdapter({
    Duration? timeout,
    Map<String, String>? headers,
  })  : defaultTimeout = timeout ?? const Duration(seconds: 120),
        defaultHeaders = headers ?? {} {
    _dio = Dio(
      BaseOptions(
        connectTimeout: defaultTimeout,
        receiveTimeout: defaultTimeout,
        sendTimeout: defaultTimeout,
        headers: defaultHeaders,
      ),
    );
  }

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.getUri<dynamic>(
        uri,
        options: Options(
          headers: headers,
          receiveTimeout: timeout ?? defaultTimeout,
        ),
      );

      return _convertToHttpResponse(response, uri);
    } on DioException catch (e) {
      return _handleDioError(e, uri);
    }
  }

  /// Converts Dio Response to http.Response for backward compatibility
  http.Response _convertToHttpResponse(Response<dynamic> dioResponse, Uri uri) {
    final body = jsonEncode(dioResponse.data);

    return http.Response(
      body,
      dioResponse.statusCode ?? 500,
      headers: _convertHeaders(dioResponse.headers.map),
      request: http.Request('GET', uri),
      reasonPhrase: dioResponse.statusMessage,
    );
  }

  /// Converts Dio headers to http headers format
  Map<String, String> _convertHeaders(Map<String, List<String>> dioHeaders) {
    return dioHeaders.map(
      (key, value) => MapEntry(key, value.join(', ')),
    );
  }

  /// Handles Dio errors and converts them to http.Response format
  http.Response _handleDioError(DioException error, Uri uri) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw TimeoutException(
          'Request timeout: ${error.message}',
          defaultTimeout,
        );

      case DioExceptionType.badResponse:
        // Server responded with an error status
        final response = error.response;
        if (response != null) {
          return _convertToHttpResponse(response, uri);
        }
        throw Exception('Bad response: ${error.message}');

      case DioExceptionType.connectionError:
        // Network error (no internet, DNS failure, etc.)
        throw const SocketException('Network connection failed');

      case DioExceptionType.cancel:
        throw Exception('Request was cancelled');

      case DioExceptionType.badCertificate:
        throw Exception('SSL certificate error: ${error.message}');

      case DioExceptionType.unknown:
        // Unknown error or other exceptions
        throw Exception('Network error: ${error.message}');
    }
  }

  /// Allows adding interceptors for advanced use cases
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Clears all interceptors
  void clearInterceptors() {
    _dio.interceptors.clear();
  }

  Dio get dioInstance => _dio;
}

/// Exception thrown when a socket/network error occurs
class SocketException implements Exception {
  final String message;

  const SocketException(this.message);

  @override
  String toString() => 'SocketException: $message';
}

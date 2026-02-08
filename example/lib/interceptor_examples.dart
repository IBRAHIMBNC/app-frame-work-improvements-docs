import 'dart:convert';

import 'package:dio/dio.dart' hide ResponseType;
import 'package:flutter/material.dart';
import 'package:sc_appframework/sc_appframework.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interceptor Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Interceptor Example')),
        body: const InterceptorDemo(),
      ),
    );
  }
}

class InterceptorDemo extends StatelessWidget {
  const InterceptorDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Interceptors are configured!',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          const Text(
            'Active Interceptors:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('• LogInterceptor (request/response logging)'),
          const Text('• AuthInterceptor (automatic token injection)'),
          const Text('• RetryInterceptor (automatic retry on failure)'),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: sendRequest,
            child: const Text('Make API Request'),
          ),
        ],
      ),
    );
  }

  sendRequest() async {
    // Make a request - interceptors will automatically handle it
    final result = await SCNetworkApi().request<Map<String, dynamic>>(
      Method.GET,
      '/posts',
      responseType: ResponseType.LIST,
    );
    result.fold(
      (error) => print('Request failed: $error'),
      (response) {
        final decodeBody = json.decoder.convert(response.body) as List<dynamic>;
        print('Request succeeded with response: ${decodeBody.length} items');
      },
    );
  }
}

/// Custom interceptor to automatically add authentication tokens
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add auth token to all requests
    final token = getAuthToken(); // Your auth logic here
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    print('🔐 Auth token added to request: ${options.path}');
    handler.next(options);
  }

  String? getAuthToken() {
    // Implement your token retrieval logic
    return 'your-auth-token-here';
  }
}

/// Custom interceptor to retry failed requests
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    if (retryCount < maxRetries && _shouldRetry(err)) {
      print(
          '🔄 Retrying request (${retryCount + 1}/$maxRetries): ${err.requestOptions.path}');

      // Wait before retrying
      await Future.delayed(retryDelay);

      // Increment retry count
      err.requestOptions.extra['retryCount'] = retryCount + 1;

      try {
        // Retry the request
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // If retry also fails, pass the error to the next handler
        print('❌ Retry failed: $e');
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors or 5xx server errors
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode ?? 0) >= 500;
  }
}

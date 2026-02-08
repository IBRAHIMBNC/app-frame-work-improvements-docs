import 'package:dio/dio.dart' hide ResponseType;
import 'package:flutter/material.dart';
import 'package:sc_appframework/sc_appframework.dart';
import 'package:sc_appframework_example/interceptor_examples.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SCNetworkApi with Dio enabled to use interceptors
  await SCNetworkApi().init(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    useDioForGet: true, // Required for interceptor support
    enableLog: true,
  );

  // Add built-in Dio interceptors
  SCNetworkApi().addInterceptor(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ),
  );

  // Add custom interceptors
  SCNetworkApi().addInterceptor(AuthInterceptor());
  SCNetworkApi().addInterceptor(RetryInterceptor());
  runApp(const MyApp());
}

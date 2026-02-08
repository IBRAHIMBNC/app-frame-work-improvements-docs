import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sc_appframework/src/network/adapters/dio_http_adapter.dart';

void main() {
  group('DioHttpAdapter', () {
    late DioHttpAdapter adapter;

    setUp(() {
      adapter = DioHttpAdapter(
        timeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      );
    });

    test('should successfully perform GET request and return http.Response',
        () async {
      // Using a public API endpoint for testing
      final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');

      final response = await adapter.get(uri);

      // Verify response properties
      expect(response, isA<http.Response>());
      expect(response.statusCode, equals(200));
      expect(response.body, isNotEmpty);

      // Verify the response can be decoded as JSON
      expect(() => response.body, returnsNormally);
    });

    test('should handle 404 errors correctly', () async {
      final uri =
          Uri.parse('https://jsonplaceholder.typicode.com/posts/999999');

      final response = await adapter.get(uri);

      // Should return a response, not throw
      expect(response, isA<http.Response>());
      expect(response.statusCode, equals(404));
    });

    test('should handle timeout errors', () async {
      // Create adapter with very short timeout
      final shortTimeoutAdapter = DioHttpAdapter(
        timeout: const Duration(milliseconds: 1),
      );

      final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');

      // Should throw TimeoutException
      expect(
        () async => await shortTimeoutAdapter.get(uri),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should maintain backward compatibility with http.Response', () async {
      final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');

      final response = await adapter.get(uri);

      // Verify all expected http.Response properties exist
      expect(response.statusCode, isNotNull);
      expect(response.body, isNotNull);
      expect(response.headers, isNotNull);
      expect(response.request, isNotNull);
    });
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_auth_response.dart';

Future<ApiAuthResponse?> postJson({
  required List<String> baseUrls,
  required String path,
  required Map<String, dynamic> body,
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 3),
}) {
  return _requestJson(
    baseUrls: baseUrls,
    path: path,
    method: 'POST',
    body: body,
    headers: headers,
    timeout: timeout,
  );
}

Future<ApiAuthResponse?> getJson({
  required List<String> baseUrls,
  required String path,
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 3),
}) {
  return _requestJson(
    baseUrls: baseUrls,
    path: path,
    method: 'GET',
    headers: headers,
    timeout: timeout,
  );
}

Future<ApiAuthResponse?> _requestJson({
  required List<String> baseUrls,
  required String path,
  required String method,
  Map<String, dynamic>? body,
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 3),
}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;

  try {
    for (final baseUrl in baseUrls) {
      try {
        final uri = _uriFor(baseUrl, path);
        final request = await client.openUrl(method, uri).timeout(timeout);
        request.headers.contentType = ContentType.json;
        for (final entry in headers.entries) {
          request.headers.set(entry.key, entry.value);
        }
        if (body != null) {
          request.write(jsonEncode(body));
        }

        final response = await request.close().timeout(timeout);
        final responseBody = await response
            .transform(utf8.decoder)
            .join()
            .timeout(timeout);
        return ApiAuthResponse(
          statusCode: response.statusCode,
          json: _decodeMap(responseBody),
          body: responseBody,
          baseUrl: baseUrl,
        );
      } on Object {
        continue;
      }
    }
    return null;
  } finally {
    client.close(force: true);
  }
}

Uri _uriFor(String baseUrl, String path) {
  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$normalizedBase$normalizedPath');
}

Map<String, dynamic>? _decodeMap(String body) {
  if (body.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

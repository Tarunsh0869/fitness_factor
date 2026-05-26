import 'api_auth_response.dart';
import 'api_auth_client_stub.dart'
    if (dart.library.io) 'api_auth_client_io.dart'
    as client;

class ApiAuthClient {
  static Future<ApiAuthResponse?> postJson({
    required List<String> baseUrls,
    required String path,
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 3),
  }) {
    return client.postJson(
      baseUrls: baseUrls,
      path: path,
      body: body,
      headers: headers,
      timeout: timeout,
    );
  }

  static Future<ApiAuthResponse?> getJson({
    required List<String> baseUrls,
    required String path,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 3),
  }) {
    return client.getJson(
      baseUrls: baseUrls,
      path: path,
      headers: headers,
      timeout: timeout,
    );
  }
}

import 'api_auth_response.dart';

Future<ApiAuthResponse?> postJson({
  required List<String> baseUrls,
  required String path,
  required Map<String, dynamic> body,
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 3),
}) async {
  return null;
}

Future<ApiAuthResponse?> getJson({
  required List<String> baseUrls,
  required String path,
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 3),
}) async {
  return null;
}

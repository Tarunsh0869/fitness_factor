class ApiAuthResponse {
  final int statusCode;
  final Map<String, dynamic>? json;
  final String body;
  final String baseUrl;

  const ApiAuthResponse({
    required this.statusCode,
    required this.json,
    required this.body,
    required this.baseUrl,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

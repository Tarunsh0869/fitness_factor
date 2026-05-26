import 'dart:convert';

import '../config/api_config.dart';
import 'api_auth_client.dart';
import 'api_auth_response.dart';

class JwtSession {
  final String token;
  final int apiMemberId;
  final int apiGymId;
  final DateTime? expiresAt;

  const JwtSession({
    required this.token,
    required this.apiMemberId,
    required this.apiGymId,
    this.expiresAt,
  });
}

class JwtAuthService {
  static Future<JwtSession?> loginOrRegister({
    required String phone,
    required String name,
  }) async {
    final loginResponse = await _post('/api/members/login', {'phone': phone});
    if (loginResponse == null) return null;

    final loginSession = await _sessionFromResponse(loginResponse);
    if (loginSession != null) return loginSession;

    if (loginResponse.statusCode != 401 && loginResponse.statusCode != 404) {
      return null;
    }

    final registerResponse = await _post('/api/members/register', {
      'name': name,
      'phone': phone,
    });
    final registerSession = await _sessionFromResponse(registerResponse);
    if (registerSession != null) return registerSession;

    if (registerResponse?.statusCode == 409) {
      final retryLogin = await _post('/api/members/login', {'phone': phone});
      return _sessionFromResponse(retryLogin);
    }

    return null;
  }

  static Future<ApiAuthResponse?> _post(
    String path,
    Map<String, dynamic> body,
  ) {
    return ApiAuthClient.postJson(
      baseUrls: ApiConfig.authBaseUrls,
      path: path,
      body: body,
    );
  }

  static Future<JwtSession?> _sessionFromResponse(
    ApiAuthResponse? response,
  ) async {
    if (response == null || !response.isSuccess || response.json == null) {
      return null;
    }

    final json = response.json!;
    final token = _stringValue(json, 'token');
    final apiMemberId = _intValue(json, 'memberId');
    final apiGymId = _intValue(json, 'gymId');
    if (token == null || apiMemberId == null || apiGymId == null) {
      return null;
    }

    final session = JwtSession(
      token: token,
      apiMemberId: apiMemberId,
      apiGymId: apiGymId,
      expiresAt: _tokenExpiry(token),
    );

    final isValid = await validate(session);
    return isValid ? session : null;
  }

  static Future<bool> validate(JwtSession session) async {
    if (session.expiresAt != null &&
        session.expiresAt!.isBefore(DateTime.now())) {
      return false;
    }

    final response = await ApiAuthClient.getJson(
      baseUrls: ApiConfig.authBaseUrls,
      path: '/api/gyms/${session.apiGymId}',
      headers: {'Authorization': 'Bearer ${session.token}'},
    );
    return response?.isSuccess == true;
  }

  static String? _stringValue(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_pascalKey(key)];
    return value is String ? value : null;
  }

  static int? _intValue(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_pascalKey(key)];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _pascalKey(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  static DateTime? _tokenExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload);
      final exp = json is Map<String, dynamic> ? json['exp'] : null;
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          exp.toInt() * 1000,
          isUtc: true,
        ).toLocal();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

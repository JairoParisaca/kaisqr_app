import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  final AppConfig config;
  final http.Client _client;

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool includeApiKey = false,
    String? sessionToken,
  }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _headers(
        includeApiKey: includeApiKey,
        sessionToken: sessionToken,
      ),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> uploadFile({
    required String path,
    required File file,
    required String sessionToken,
    String? personalizedName,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path))
      ..headers['X-Session-Token'] = sessionToken
      ..files.add(await http.MultipartFile.fromPath('archivo', file.path));

    if (personalizedName != null && personalizedName.trim().isNotEmpty) {
      request.fields['nombre_personalizado'] = personalizedName.trim();
    }

    final response = await _client.send(request);
    final streamedResponse = await http.Response.fromStream(response);
    return _decodeResponse(streamedResponse);
  }

  Uri _buildUri(String path) {
    return Uri.parse('${config.apiUrl.replaceFirst(RegExp(r'\/$'), '')}/$path');
  }

  Map<String, String> _headers({
    required bool includeApiKey,
    String? sessionToken,
  }) {
    return <String, String>{
      'Content-Type': 'application/json',
      if (includeApiKey) 'X-API-Key': config.apiKey,
      if (sessionToken != null && sessionToken.isNotEmpty)
        'X-Session-Token': sessionToken,
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final dynamic decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail =
          body['detail']?.toString() ?? 'La operación no pudo completarse';
      throw ApiException(response.statusCode, detail);
    }

    return body;
  }
}

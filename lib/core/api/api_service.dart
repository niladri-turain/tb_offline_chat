import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_endpoints.dart';
import 'api_exception.dart';

/// Sends GET, POST and DELETE requests to [ApiEndpoints.baseUrl] and returns the decoded JSON.
/// Any failure is thrown as an [ApiException]. In debug builds every call is printed.
class ApiService {
  ApiService({http.Client? client, this.tokenProvider}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns the saved access token, added as `Authorization: Bearer …` when present.
  final String? Function()? tokenProvider;

  static const _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? query}) {
    final uri = _uri(endpoint, query);
    return _send('GET', uri, null, () => _client.get(uri, headers: _headers()));
  }

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) {
    final uri = _uri(endpoint, null);
    final encoded = jsonEncode(body ?? const {});
    return _send('POST', uri, encoded, () => _client.post(uri, headers: _headers(), body: encoded));
  }

  /// Sends no body; only the headers, token included.
  Future<Map<String, dynamic>> delete(String endpoint) {
    final uri = _uri(endpoint, null);
    return _send('DELETE', uri, null, () => _client.delete(uri, headers: _headers()));
  }

  Uri _uri(String endpoint, Map<String, String>? query) =>
      Uri.parse('${ApiEndpoints.baseUrl}$endpoint').replace(queryParameters: query);

  Map<String, String> _headers() {
    final token = tokenProvider?.call();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri,
    String? body,
    Future<http.Response> Function() request,
  ) async {
    _log('➡️ $method $uri');
    if (body != null) _log('📦 Body: $body');

    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      _log('⏱️ TIMEOUT $method $uri');
      throw ApiException(code: 'TIMEOUT', message: 'The server took too long to answer. Please try again.');
    } on SocketException catch (e) {
      _log('🚫 NETWORK ERROR $method $uri: $e');
      throw ApiException(code: 'NETWORK_ERROR', message: 'No internet connection. Check your network and try again.');
    } on http.ClientException catch (e) {
      _log('🚫 NETWORK ERROR $method $uri: $e');
      throw ApiException(code: 'NETWORK_ERROR', message: 'Could not reach the server. Please try again.');
    }

    Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok) {
      _log('✅ SUCCESS ${response.statusCode} $method $uri\n📥 Response: ${response.body}');
      if (decoded is Map<String, dynamic>) return decoded;
      // 204 No Content and other empty successes.
      if (response.body.isEmpty) return const {};
      throw ApiException(
        statusCode: response.statusCode,
        code: 'BAD_RESPONSE',
        message: 'Unexpected answer from the server. Please try again.',
      );
    }

    _log('❌ ERROR ${response.statusCode} $method $uri\n📥 Error response: ${response.body}');
    throw ApiException.fromResponse(response.statusCode, decoded);
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[API] $message');
  }
}

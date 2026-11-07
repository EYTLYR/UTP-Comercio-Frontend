import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'session_store.dart';

/// Error de la API (ProblemDetail del backend: detail + code).
class ApiException implements Exception {
  final int status;
  final String code;
  final String message;

  const ApiException(this.status, this.code, this.message);

  /// Sin conexión o el servidor no respondió.
  bool get isNetwork => status == 0;

  @override
  String toString() => 'ApiException($status, $code): $message';
}

/// Cliente HTTP de la Nearby API: JSON, JWT y renovación automática del token.
class ApiClient {
  final http.Client _http;
  final SessionStore store;

  String? accessToken;
  String? refreshToken;

  /// Se llama cuando el token de refresco ya no sirve (hay que volver a ingresar).
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  ApiClient({http.Client? client, SessionStore? store})
    : _http = client ?? http.Client(),
      store = store ?? SessionStore();

  bool get hasSession => accessToken != null;

  void setTokens(String access, String refresh) {
    accessToken = access;
    refreshToken = refresh;
  }

  Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
    await store.clear();
  }

  // ------------------------------------------------------------- verbos

  Future<dynamic> get(String path, {Map<String, Object?>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  // ------------------------------------------------------------- interno

  Uri _uri(String path, Map<String, Object?>? query) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null) q[k] = '$v';
    });
    final full = path.startsWith('/') ? path : '/api/v1/$path';
    final base = Uri.tryParse(ApiConfig.baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        (base.scheme != 'http' && base.scheme != 'https')) {
      throw const ApiException(
        0,
        'CONFIG',
        'Configura una URL válida del backend en API_BASE_URL (.env).',
      );
    }
    return Uri.parse('${ApiConfig.baseUrl}$full')
        .replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool auth = true,
    bool retry = true,
  }) async {
    final uri = _uri(path, query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (auth && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      res = await http.Response.fromStream(streamed).timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException(
        0,
        'NETWORK',
        'El servidor no respondió. Revisa tu conexión.',
      );
    } catch (_) {
      throw const ApiException(
        0,
        'NETWORK',
        'Sin conexión con Nearby. Revisa tu internet.',
      );
    }

    if (res.statusCode == 401 && auth && retry && refreshToken != null) {
      if (await _refresh()) {
        return _send(
          method,
          path,
          query: query,
          body: body,
          auth: auth,
          retry: false,
        );
      }
      onSessionExpired?.call();
    }

    final text = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (text.isEmpty) return null;
      try {
        return jsonDecode(text);
      } catch (_) {
        return text;
      }
    }

    var code = 'HTTP_${res.statusCode}';
    var message = 'Algo salió mal (${res.statusCode}). Inténtalo otra vez.';
    try {
      final err = jsonDecode(text);
      if (err is Map) {
        code = (err['code'] as String?) ?? code;
        message =
            (err['detail'] as String?) ?? (err['title'] as String?) ?? message;
      }
    } catch (_) {}
    throw ApiException(res.statusCode, code, message);
  }

  /// Rota el token de refresco. Una sola renovación a la vez.
  Future<bool> _refresh() {
    return _refreshing ??= () async {
      try {
        final data = await _send(
          'POST',
          '/api/v1/auth/refresh',
          body: {'refreshToken': refreshToken},
          auth: false,
          retry: false,
        );
        if (data is Map && data['accessToken'] is String) {
          setTokens(
            data['accessToken'] as String,
            data['refreshToken'] as String,
          );
          await store.save(refreshToken: refreshToken!);
          return true;
        }
        return false;
      } on ApiException catch (error) {
        if (error.isNetwork) rethrow;
        return false;
      } catch (_) {
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }

  /// Ingresa con un token de refresco guardado (al abrir la app).
  Future<Map<String, dynamic>?> resume(String savedRefresh) async {
    refreshToken = savedRefresh;
    try {
      final data = await _send(
        'POST',
        '/api/v1/auth/refresh',
        body: {'refreshToken': savedRefresh},
        auth: false,
        retry: false,
      );
      if (data is Map<String, dynamic>) {
        setTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        await store.save(refreshToken: refreshToken!);
        return data;
      }
    } on ApiException catch (e) {
      if (!e.isNetwork) await clearSession();
      rethrow;
    }
    return null;
  }
}

/// UUID v4 para clientId (idempotencia de los POST creados en el teléfono).
String newClientId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = List.generate(16, h).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

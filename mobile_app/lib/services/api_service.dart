import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/user_model.dart';

/// Hasil pemanggilan API auth (login/register).
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  const AuthResult({required this.success, required this.message, this.user});
}

/// Service untuk berkomunikasi dengan backend FastAPI.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// Base URL backend FastAPI.
  ///
  /// Otomatis menyesuaikan target:
  /// - Web (Chrome) / iOS sim / desktop : http://localhost:8000
  /// - Emulator Android                 : http://10.0.2.2:8000
  ///
  /// Untuk HP fisik, ganti manual ke IP komputer, mis:
  ///   static const String _manualBaseUrl = 'http://192.168.100.23:8000';
  static const String? _manualBaseUrl = null;

  String get baseUrl {
    if (_manualBaseUrl != null) return _manualBaseUrl!;
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {
      // Platform tidak tersedia (mis. web) -> abaikan.
    }
    return 'http://localhost:8000';
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static const Duration _timeout = Duration(seconds: 15);

  /// Ekstrak pesan error dari body response FastAPI.
  String _extractError(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        // Error validasi Pydantic: ambil pesan pertama.
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString().replaceFirst('Value error, ', '');
        }
      }
      if (body['message'] is String) return body['message'];
    } catch (_) {}
    return fallback;
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);

      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      if (res.statusCode == 200) {
        return AuthResult(
          success: true,
          message: body['message'] ?? 'Login berhasil',
          user: body['user'] != null
              ? UserModel.fromJson(body['user'])
              : null,
        );
      }
      return AuthResult(
        success: false,
        message: _extractError(res, 'Login gagal'),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Tidak bisa terhubung ke server. Pastikan backend aktif.',
      );
    }
  }

  Future<AuthResult> register({
    required String email,
    required String fullName,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'full_name': fullName,
              'username': username,
              'password': password,
              'confirm_password': confirmPassword,
            }),
          )
          .timeout(_timeout);

      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      if (res.statusCode == 201 || res.statusCode == 200) {
        return AuthResult(
          success: true,
          message: body['message'] ?? 'Registrasi berhasil',
          user: body['user'] != null
              ? UserModel.fromJson(body['user'])
              : null,
        );
      }
      return AuthResult(
        success: false,
        message: _extractError(res, 'Registrasi gagal'),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Tidak bisa terhubung ke server. Pastikan backend aktif.',
      );
    }
  }
}

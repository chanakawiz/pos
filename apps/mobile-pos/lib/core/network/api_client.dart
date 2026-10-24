import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._init();
  late final Dio dio;

  String? _authToken;
  String? _deviceUuid;
  String _baseUrl = 'http://127.0.0.1:8000';

  ApiClient._init() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          if (_deviceUuid != null && _deviceUuid!.isNotEmpty) {
            options.headers['X-Device-UUID'] = _deviceUuid;
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Pass error forward
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _deviceUuid = prefs.getString('device_uuid');

    // Generate stable device UUID if not set yet
    if (_deviceUuid == null || _deviceUuid!.isEmpty) {
      _deviceUuid = const Uuid().v4();
      await prefs.setString('device_uuid', _deviceUuid!);
    }

    // Default base URL for Android Emulator vs desktop/iOS
    final savedUrl = prefs.getString('base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    } else {
      if (!kIsWeb && Platform.isAndroid) {
        _baseUrl = 'http://10.0.2.2:8000';
      } else {
        _baseUrl = 'http://127.0.0.1:8000';
      }
    }
    dio.options.baseUrl = _baseUrl;
  }

  String get baseUrl => _baseUrl;
  String? get deviceUuid => _deviceUuid;
  String? get authToken => _authToken;

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    dio.options.baseUrl = _baseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', _baseUrl);
  }

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  Future<void> setDeviceUuid(String uuid) async {
    _deviceUuid = uuid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_uuid', uuid);
  }
}

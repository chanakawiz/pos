import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<UserModel> login({
    required String email,
    String? password,
    String? pinCode,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          if (password != null) 'password': password,
          if (pinCode != null) 'pin_code': pinCode,
          'device_uuid': _apiClient.deviceUuid,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token']?.toString();
      await _apiClient.setAuthToken(token);

      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return user;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Authentication failed';
      throw Exception(msg);
    }
  }

  Future<void> pairDevice({
    required String pairingCode,
    required String deviceName,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/devices/register',
        data: {
          'pairing_code': pairingCode,
          'device_name': deviceName,
          'device_type': Platform.isIOS ? 'ios' : 'android',
          'mac_address': 'MOBILE-${_apiClient.deviceUuid?.substring(0, 8)}',
          'app_version': '1.0.0',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final device = data['device'] as Map<String, dynamic>?;
      if (device != null && device['uuid'] != null) {
        await _apiClient.setDeviceUuid(device['uuid'].toString());
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Device pairing failed';
      throw Exception(msg);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token']?.toString();
      await _apiClient.setAuthToken(token);

      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return user;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Registration failed';
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/api/v1/auth/logout');
    } catch (_) {}
    await _apiClient.setAuthToken(null);
  }
}


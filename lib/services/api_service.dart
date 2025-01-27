import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:petcarezone/utils/logger.dart';
import 'package:petcarezone/constants/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<Map<String, dynamic>?> request({
    required String url,
    required Map<String, dynamic> body,
    required String method,
    bool isToken = true,
  }) async {
    http.Response response;

    logD.i('Request: Method=$method\nURL=$url\nBody=$body');

    final headers = {
      'Content-Type': 'application/json',
    };

    if (isToken) {
      final token = await _getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(Uri.parse(url), headers: headers, body: json.encode(body));
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers, body: json.encode(body));
          break;
        default:
          throw Exception('HTTP method $method not supported');
      }

      logD.i('Response: StatusCode=${response.statusCode}, Body=${json.decode(utf8.decode(response.bodyBytes))}');
      final responseBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        final errorMessage = responseBody['message'] ?? 'Unknown error occurred';
        throw errorMessage;
      }
    } catch (e) {
      logD.e('API Request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> postLogin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
    };

    return await request(
      url: ApiUrls.loginUrl,
      body: requestBody,
      method: 'POST',
      isToken: false,
    );
  }

  Future<Map<String, dynamic>?> regMobileToken({
    required String mobileId,
    required int mobileType,
    required String mobileToken,
  }) async {
    Map<String, dynamic> requestBody = {
      'mobileId': mobileId,
      'mobileType': mobileType,
      'mobileToken': mobileToken,
    };

    return await request(
      url: ApiUrls.regMobileToken,
      body: requestBody,
      method: 'POST',
      isToken: true,
    );
  }

  Future<Map<String, dynamic>?> postDeviceInfo({
    required String deviceId,
    required String deviceName,
    required String serialNumber,
  }) async {
    Map<String, dynamic> requestBody = {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'serialNumber': serialNumber,
    };

    return await request(
      url: ApiUrls.deviceUrl,
      body: requestBody,
      method: 'POST',
      isToken: true,
    );
  }

  Future<Map<String, dynamic>?> deleteDeviceInfo({
    required String deviceId,
    required BuildContext context,
  }) async {
    Map<String, dynamic> requestBody = {
      'deviceId': deviceId,
    };

    return await request(
      url: ApiUrls.deviceUrl,
      body: requestBody,
      method: 'DELETE',
      isToken: true,
    );
  }

  Future<Map<String, dynamic>?> postDeviceProvision({
    required String deviceId,
  }) async {
    Map<String, dynamic> requestBody = {
      'deviceId': deviceId,
    };

    return await request(
      url: '${ApiUrls.deviceUrl}/provision',
      body: requestBody,
      method: 'POST',
      isToken: true,
    );
  }

  Future<Map<String, dynamic>?> getPetProfile({
    required int petId,
  }) async {
    return await request(
      url: '${ApiUrls.getPetProfile}?petId=$petId',
      body: {},
      method: 'GET',
      isToken: true,
    );
  }

  Future<Map<String, dynamic>?> doGetStates({
    required String deviceId,
    required int petId,
  }) async {
    Map<String, dynamic> requestBody = {
      'deviceId': deviceId,
      'petId' : petId
    };

    return await request(
      url: ApiUrls.doGetStates,
      body: requestBody,
      method: 'POST',
      isToken: true,
    );
  }
}

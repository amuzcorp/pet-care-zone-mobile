import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:petcarezone/constants/api_urls.dart';

import '../utils/logger.dart';

class LunaService {
  static const MethodChannel channel = MethodChannel('com.lge.petcarezone/discovery');
  Future<void> webOSRequest(uri, payload) async {
    try {
      logD.i("webOS request sent!\nuri: $uri\npayload: $payload");
      await channel.invokeMethod('webOSRequest', {'uri': uri, 'payload': payload});
    } on PlatformException catch (e) {
      logD.w("Failed to request '${e.message}'.");
    }
  }

  Future checkWifiStatus() async {
    const String uri = ApiUrls.lunaWifiStatusUrl;
    try {
      webOSRequest(uri, {});
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }

  Future startProvision() async {
    const String uri = ApiUrls.lunaProvisionUrl;
    try {
      webOSRequest(uri, {});
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }

  Future getWifiProfileList() async {
    const String uri = ApiUrls.getWifiProfileList;
    try {
      webOSRequest(uri, {});
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }

  Future<void> registerUserProfile(String userId, int petId) async {
    Map<String, dynamic> userData = Map<String, dynamic>.from(ApiUrls.registerUserProfile);

    final String? uri = userData['uri'];

    userData['payload']['userId'] = userId;
    userData['payload']['petId'] = petId;

    try {
      String payloadString = jsonEncode(userData['payload']);
      final Map<String, dynamic>? payload = jsonDecode(payloadString!);
      print('Decoded payload: $payload');

      print('lunaRegisterUserProfile $payload');

      webOSRequest(uri, payload);
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }
}

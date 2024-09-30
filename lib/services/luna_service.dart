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

  Future lunaTest() async {
    const String uri = ApiUrls.lunaTest;
    try {
      webOSRequest(uri, {});
    } catch (e) {
      throw Exception('Failed Response $e');
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

  Future scanWifi() async {
    final String uri = await ApiUrls.lunaWifiScan['uri'];
    final Map payload = await ApiUrls.lunaWifiScan['payload'];
    try {
      await webOSRequest(uri, payload);
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }

  Future connectWifi(String wifi, String passKey) async {
    final wifiData = ApiUrls.getLunaWifiConnectUrl(wifi, passKey);
    print('wifiData $wifiData');

    final String? uri = wifiData['uri'];
    final String? payloadString = wifiData['payload'];
    print('uri $uri, payloadString: $payloadString');

    final Map<String, dynamic>? payload = jsonDecode(payloadString!);
    print('Decoded payload: $payload');

    try {
      await webOSRequest(uri, payload);
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

  Future lunaGetProfileList() async {
    const String uri = ApiUrls.lunaGetProfileList;
    try {
      webOSRequest(uri, {});
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }
}

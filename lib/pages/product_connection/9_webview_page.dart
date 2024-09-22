import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petcarezone/constants/api_urls.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'dart:convert';
import 'package:petcarezone/services/user_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import '../../utils/logger.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({
    super.key,
    required this.uri,
  });

  final Uri uri;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late MqttServerClient client;
  late final WebViewController controller;
  final userService = UserService();
  final deviceService = DeviceService();
  final lunaService = LunaService();
  String? deviceIp = "";
  String? deviceId = "";
  String userId = "";
  int petId = 0;
  bool isSubscribed = false;
  bool isSetPetInfo = false;

  Future<void> initialize() async {
    await getUserInfo();
    logD.i('Loaded userIds: userId: $userId, petId: $petId, deviceId: $deviceId, deviceIp: $deviceIp');

    /// If petId is not 0, set pet info and initialize MQTT
    if (petId != 0) {
      await setPetInfo();
      if (isSetPetInfo) {
        await mqttInitialize();
      }
    } else {
      /// Start tracking petId until it's updated in localStorage
      logD.i('Starting to track petId from localStorage...');
      await trackPetId();
    }
  }

  Future getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    deviceIp = await deviceService.getDeviceIp();
    userId = prefs.getString('userId')!;
    deviceId = prefs.getString('deviceId');
    petId = prefs.getInt('petId')!;
  }

  Future setPetInfo() async {
    isSetPetInfo = true;
    return await lunaService.setPetInfo(deviceIp!, userId, petId.toString());
  }

  Future<void> trackPetId() async {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final petIdFromStorage = await controller.runJavaScriptReturningResult("""localStorage.getItem('petId');""");
      String petIdStr = petIdFromStorage.toString().replaceAll('"', '');
      int localStoragePetId = int.tryParse(petIdStr) ?? 0;

      if (localStoragePetId != 0) {
        logD.i('PetId updated to $localStoragePetId, stopping tracking.');
        timer.cancel();
        petId = localStoragePetId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('petId', localStoragePetId);

        await setPetInfo(); // Continue with initialization
        if (isSetPetInfo) {
          await mqttInitialize();
        }
      }
    });
  }

  Future mqttInitialize() async {
    final accessToken = await userService.getAccessToken();
    await controller.runJavaScript("""
    localStorage.setItem('accessToken', '$accessToken');
    localStorage.setItem('userId', '$userId');
    localStorage.setItem('petId', '$petId');
    localStorage.setItem('deviceId', '$deviceId');
    """);

    getLocalStorageValues();
    try {
      final claimCert = await rootBundle.load('assets/data/claim-cert.pem');
      final claimPrivateKey = await rootBundle.load('assets/data/claim-private.key');
      final rootCA = await rootBundle.load('assets/data/root-CA.crt');

      final context = SecurityContext(withTrustedRoots: false);
      context.useCertificateChainBytes(claimCert.buffer.asUint8List());
      context.usePrivateKeyBytes(claimPrivateKey.buffer.asUint8List());
      context.setTrustedCertificatesBytes(rootCA.buffer.asUint8List());

      client = MqttServerClient(
        'axjobfp4mqj2j-ats.iot.ap-northeast-2.amazonaws.com',
        'clientIdentifier',
      )
        ..useWebSocket = false
        ..port = 8883
        ..secure = true
        ..securityContext = context;

      try {
        await client.connect();
        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          logD.i('AWS IoT에 연결됨');
          subscribe();
        } else {
          logD.e('AWS IoT에 연결 실패');
        }
      } catch (e) {
        logD.e('Error: $e');
        client.disconnect();
      }
    } catch (e) {
      logD.e('Error loading certificates: $e');
    }
  }

  Future<void> checkPetIdAndInitialize() async {
    final petIdFromStorage = await controller.runJavaScriptReturningResult("""localStorage.getItem('petId');""");
    String petId = petIdFromStorage.toString().replaceAll('"', '');
    if (petId == 'null' || petId == "0") {
      petId = this.petId.toString();
    } else {
      logD.i('PetId is 0, skipping initialization.');
    }
  }

  void subscribe() {
    if (!isSubscribed) {
      final stateTopic = 'iot/petcarezone/topic/states/$deviceId';
      final eventTopic = 'iot/petcarezone/topic/events/$deviceId';

      logD.i('Subscribing to topics: stateTopic $stateTopic, eventTopic $eventTopic');

      client.subscribe(stateTopic, MqttQos.atLeastOnce);
      client.subscribe(eventTopic, MqttQos.atLeastOnce);

      client.updates.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (dynamic message in messages) {
          final payload = message.payload as MqttPublishMessage;
          final payloadMsg = MqttUtilities.bytesToStringAsString(payload.payload.message!);

          final jsonPayload = jsonDecode(payloadMsg) as Map<String, dynamic>;
          if (message.topic == stateTopic) {
            _sendToWebView(jsonPayload, 'stateTopic');
          } else if (message.topic == eventTopic) {
            _sendToWebView(jsonPayload, 'eventTopic');
          }
        }
      }).onError((error) {
        logD.e('Error while listening to updates: $error');
      });

      isSubscribed = true;
    } else {
      logD.i('Already subscribed to MQTT topics.');
    }
  }
  void _sendToWebView(Map<String, dynamic> data, String topic) async {
    if (topic == 'eventTopic') {
      String jsonData = jsonEncode(data);

      await controller.runJavaScript("""
      localStorage.setItem('eventTopic', '$jsonData');
    """);

      final result = await controller.runJavaScriptReturningResult("""
      localStorage.getItem('eventTopic');
    """);
      print('event result $result');
    }

    if (topic == 'stateTopic') {
      String jsonData = jsonEncode(data);

      await controller.runJavaScript("""
      localStorage.setItem('stateTopic', '$jsonData');
    """);

      final result = await controller.runJavaScriptReturningResult("""
      localStorage.getItem('stateTopic');
    """);
      print('state result $result');
    }
  }

  void disconnect() {
    client.disconnect();
  }

  void getLocalStorageValues() async {
    try {
      final accessToken = await controller.runJavaScriptReturningResult("localStorage.getItem('accessToken')");
      final userId = await controller.runJavaScriptReturningResult("localStorage.getItem('userId')");
      final petId = await controller.runJavaScriptReturningResult("localStorage.getItem('petId')");
      final deviceId = await controller.runJavaScriptReturningResult("localStorage.getItem('deviceId')");
      logD.i('Fetched from localStorage - accessToken: $accessToken, userId: $userId, petId: $petId, deviceId: $deviceId');
    } catch (e) {
      logD.e('Error fetching local storage values: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
    controller = WebViewController();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: controller
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {},
              onPageFinished: (String url) async {
                checkPetIdAndInitialize();
              },
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith(ApiUrls.webViewUrl)) {
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(
            Uri.parse(ApiUrls.webViewUrl),
          ),
      ),
    );
  }
}

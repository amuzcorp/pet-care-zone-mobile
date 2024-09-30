import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petcarezone/constants/api_urls.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/utils/permissionCheck.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import '../../utils/logger.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, required this.uri, required this.backPage});

  final Uri uri;
  final Widget backPage;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  static const MethodChannel _channel =
      MethodChannel("com.lge.petcarezone/media");
  late MqttServerClient client;
  late final WebViewController controller;
  late final PlatformWebViewControllerCreationParams params;
  final userService = UserService();
  final deviceService = DeviceService();
  final lunaService = LunaService();
  final permissionCheck = PermissionCheck();
  String? deviceIp = "";
  String? deviceId = "";
  String userId = "";
  int petId = 0;
  bool isSubscribed = false;
  bool isSetPetInfo = false;

  Future mqttInit() async {
    client = MqttServerClient(
      'axjobfp4mqj2j-ats.iot.ap-northeast-2.amazonaws.com',
      'clientIdentifier',
    );
    params = const PlatformWebViewControllerCreationParams();
    controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (WebViewPermissionRequest request) {
        request.grant();
      },
    );
  }

  Future userInfoInit() async {
    await getUserInfo();
    await setUserInfo();
    logD.i(
        'Loaded userIds: userId: $userId, petId: $petId, deviceId: $deviceId, deviceIp: $deviceIp');
    await trackPetId();
  }

  /// 0. get user info
  Future getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    deviceIp = await deviceService.getDeviceIp();
    userId = prefs.getString('userId')!;
    deviceId = prefs.getString('deviceId');
    petId = prefs.getInt('petId')!;

    print('userId $userId');
    print('deviceId $deviceId');
    print('petId $petId');
    await getLocalStorageValues();
  }

  Future setUserInfo() async {
    final accessToken = await userService.getAccessToken();
    await controller.runJavaScript("""
    localStorage.setItem('accessToken', '$accessToken');
    localStorage.setItem('userId', '$userId');
    localStorage.setItem('petId', '$petId');
    localStorage.setItem('deviceId', '$deviceId');
    """);
  }

  /// 1. pet id check
  Future<void> trackPetId() async {
    final petIdFromLocalStorage = await controller
        .runJavaScriptReturningResult("""localStorage.getItem('petId');""");
    String petIdStr = petIdFromLocalStorage.toString().replaceAll('"', '');
    int localStoragePetId = int.tryParse(petIdStr) ?? 0;

    /// 2. petId 있는 경우
    if (localStoragePetId != 0) {
      logD.i('PetId updated to $localStoragePetId, stopping tracking.');
      petId = localStoragePetId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('petId', localStoragePetId);

      /// 3. device에 pet,user info 등록
      await setPetInfo();

      /// 4. pet,user info 등록된 경우 device mqtt 구독
      if (isSetPetInfo) {
        await mqttSubscribe();
      }
    }
  }

  Future setPetInfo() async {
    isSetPetInfo = true;
    return await lunaService.setPetInfo(deviceIp!, userId, petId.toString());
  }

  Future mqttCertInitialize() async {
    final claimCert = await rootBundle.load('assets/data/claim-cert.pem');
    final claimPrivateKey =
        await rootBundle.load('assets/data/claim-private.key');
    final rootCA = await rootBundle.load('assets/data/root-CA.crt');

    final context = SecurityContext(withTrustedRoots: false);
    context.useCertificateChainBytes(claimCert.buffer.asUint8List());
    context.usePrivateKeyBytes(claimPrivateKey.buffer.asUint8List());
    context.setTrustedCertificatesBytes(rootCA.buffer.asUint8List());

    try {
      client
        ..useWebSocket = false
        ..port = 8883
        ..secure = true
        ..securityContext = context;
    } catch (e) {
      logD.e('Error loading certificates: $e');
    }
  }

  Future mqttSubscribe() async {
    final accessToken = await userService.getAccessToken();
    await controller.runJavaScript("""
    localStorage.setItem('accessToken', '$accessToken');
    localStorage.setItem('userId', '$userId');
    localStorage.setItem('petId', '$petId');
    localStorage.setItem('deviceId', '$deviceId');
    """);

    await getLocalStorageValues();
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
  }

  void subscribe() {
    if (!isSubscribed) {
      final stateTopic = 'iot/petcarezone/topic/states/$deviceId';
      final eventTopic = 'iot/petcarezone/topic/events/$deviceId';

      logD.i(
          'Subscribing to topics: stateTopic $stateTopic, eventTopic $eventTopic');

      client.subscribe(stateTopic, MqttQos.atLeastOnce);
      client.subscribe(eventTopic, MqttQos.atLeastOnce);

      client.updates.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (dynamic message in messages) {
          final payload = message.payload as MqttPublishMessage;
          final payloadMsg =
              MqttUtilities.bytesToStringAsString(payload.payload.message!);

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

  Future _sendToWebView(Map<String, dynamic> data, String topic) async {
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

  Future getLocalStorageValues() async {
    final accessToken = await controller
        .runJavaScriptReturningResult("localStorage.getItem('accessToken')");
    final userId = await controller
        .runJavaScriptReturningResult("localStorage.getItem('userId')");
    final petId = await controller
        .runJavaScriptReturningResult("localStorage.getItem('petId')");
    final deviceId = await controller
        .runJavaScriptReturningResult("localStorage.getItem('deviceId')");
    logD.i(
        'Fetched from localStorage - accessToken: $accessToken, userId: $userId, petId: $petId, deviceId: $deviceId');
  }

  Future<void> saveFile(String dataURL, String format) async {
    final byteData = base64Decode(dataURL.split(',')[1]);

    if (Platform.isAndroid) {
      Directory? folder;
      if (format == 'png') {
        folder = Directory('/sdcard/Pictures/PetCareZone');
      }
      if (format == 'mp4') {
        folder = Directory('/sdcard/Movies/PetCareZone');
      }

      if (!await folder!.exists()) {
        await folder.create(recursive: true);
      }

      final filePath =
          '${folder.path}/${DateTime.now().millisecondsSinceEpoch}.$format';

      final file = File(filePath);
      await file.writeAsBytes(byteData);

      await _channel.invokeMethod("scanFile", {'filePath': filePath});
    } else if (Platform.isIOS) {
      await _channel.invokeMethod("saveFile", {
        'byteData': byteData,
        'fileName': '${DateTime.now().millisecondsSinceEpoch}.$format',
        'format': format
      });
    }
  }

  Future jsChannelListener(message) async {
    if (message.message.startsWith('data:image/png')) {
      return await saveFile(message.message, 'png');
    }
    if (message.message.startsWith('data:video/mp4')) {
      return saveFile(message.message, 'mp4');
    }
    if (message.message == "backButtonClicked") {
      logD.i("Back button clicked in WebView");
      return Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    mqttInit();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool _, dynamic __) async {
          final currentUrl = await controller.currentUrl();
          if (currentUrl ==
                  'https://amuzcorp-pet-care-zone-webview.vercel.app/home' ||
              currentUrl ==
                  "https://amuzcorp-pet-care-zone-webview.vercel.app/profile/register") {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => widget.backPage),
              );
            }
          }
          controller.runJavaScript(
              "if (window.location.pathname !== '/') { window.history.back(); }");
        },
        child: WebViewWidget(
          controller: controller
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (String url) async {
                  await userInfoInit();
                  await trackPetId();
                },
                // onPageFinished: (String url) {},
                // onNavigationRequest: (NavigationRequest request) {
                //   if (request.url.startsWith(ApiUrls.webViewUrl)) {
                //     return NavigationDecision.prevent;
                //   }
                //   return NavigationDecision.navigate;
                // },
              ),
            )
            ..addJavaScriptChannel(
              'Flutter',
              onMessageReceived: (JavaScriptMessage message) async {
                await jsChannelListener(message);
              },
            )
            ..loadRequest(
              Uri.parse(ApiUrls.webViewUrl),
            ),
        ),
      ),
    );
  }
}

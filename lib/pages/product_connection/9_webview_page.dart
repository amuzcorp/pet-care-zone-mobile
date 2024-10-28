import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petcarezone/constants/api_urls.dart';
import 'package:petcarezone/pages/product_connection/1-1_initial_device_home_page.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../services/connect_sdk_service.dart';
import '../../utils/logger.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, required this.uri, this.backPage});

  final Uri uri;
  final Widget? backPage;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  static const MethodChannel _channel =
      MethodChannel("com.lge.petcarezone/media");
  late MqttServerClient client;
  final WebViewController controller = WebViewController();
  late final PlatformWebViewControllerCreationParams params;
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final userService = UserService();
  final deviceService = DeviceService();
  final lunaService = LunaService();
  String deviceId = "";
  String userId = "";
  int petId = 0;
  bool isSubscribed = false;
  bool isSetPetInfo = false;

  Future mqttInit() async {
    client = MqttServerClient(
      'axjobfp4mqj2j-ats.iot.ap-northeast-2.amazonaws.com',
      'clientIdentifier',
    );

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
      client.updates.listen(onMessageReceived);
      isSubscribed = true;
    } else {
      logD.i('Already subscribed to MQTT topics.');
    }
  }

  void onMessageReceived(List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final pt = MqttUtilities.bytesToStringAsString(recMess.payload.message!);

    final topic = c[0].topic;
    if (topic == "iot/petcarezone/topic/events/${deviceId}") {
      controller.runJavaScript("handleEventTopicEvent($pt);");
    }
    if (topic == "iot/petcarezone/topic/states/${deviceId}") {
      controller.runJavaScript("handleStateTopicEvent($pt);");
    }
    logD.i(
        'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
  }

  /// Indicate the notification is correct

  Future webViewInit() async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          userInfoInit();
        },
      ),
    );
    await controller.addJavaScriptChannel(
      'Flutter',
      onMessageReceived: (JavaScriptMessage message) async {
        await jsChannelListener(message);
      },
    );

    await controller.loadRequest(
      Uri.parse(ApiUrls.webViewUrl),
    );

    final platformController = controller.platform;
    if (platformController is AndroidWebViewController) {
      platformController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          // request location permission
          final locationPermissionStatus =
              await Permission.locationWhenInUse.request();

          // return the response
          return GeolocationPermissionsResponse(
            allow: locationPermissionStatus == PermissionStatus.granted,
            retain: false,
          );
        },
      );
    }
    await mqttInit();
  }

  Future userInfoInit() async {
    await getUserInfo();
    await setUserInfo();
    logD.i(
        'initial Loaded userIds: userId: $userId, petId: $petId, deviceId: $deviceId');
  }

  /// 1. get user info
  Future getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId')!;
    deviceId = prefs.getString('deviceId')!;
    petId = prefs.getInt('petId')!;
  }

  /// 2. set user info
  Future setUserInfo() async {
    final accessToken = await userService.getAccessToken();
    await controller.runJavaScript("""
    localStorage.setItem('accessToken', '$accessToken');
    localStorage.setItem('userId', '$userId');
    localStorage.setItem('petId', '${petId == 0 ? "" : petId}');
    localStorage.setItem('deviceId', '${deviceId!.isEmpty ? "" : deviceId}');
    """);
    await getLocalStorageValues();
  }

  /// 3. pet id check
  Future<void> trackPetId() async {
    final petIdFromLocalStorage = await controller
        .runJavaScriptReturningResult("""localStorage.getItem('petId');""");
    String petIdStr = petIdFromLocalStorage.toString().replaceAll('"', '');

    /// 2. petId 있는 경우
    if (petIdStr != '0' && petIdStr.isNotEmpty) {
      logD.i('PetId updated to $petIdStr, stopping tracking.');
      petId = int.tryParse(petIdStr)!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('petId', petId);
      await prefs.setString('userId', userId);
      await prefs.setString('deviceId', deviceId);

      /// 3. device에 pet,user info 등록
      await setPetInfo();
      await mqttSubscribe();
    } else {
      logD.e('Pet id 없음.');
    }
  }

  Future setPetInfo() async {
    isSetPetInfo = true;
    print('setPetInfo $userId,$petId');
    await lunaService.registerUserProfile(userId, petId);
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

    if (petId is String &&
        petId.isNotEmpty &&
        deviceId is String &&
        deviceId.isNotEmpty) {
      print('mqttSubscribe 구독');
      await setPetInfo();
      await mqttSubscribe();
    }
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

  var isShowBottomSheet = false;
  var isShowSubBottomSheet = false;

  Future jsChannelListener(message) async {
    if (message.message.startsWith('data:image/png')) {
      return await saveFile(message.message, 'png');
    }
    if (message.message.startsWith('data:video/mp4')) {
      return saveFile(message.message, 'mp4');
    }
    if (message.message == "deleteDevice") {
      logD.i("Device info deleted. navigate to device register page.");
      await userService.deleteUserInfo();
      if (mounted) {
        return Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const InitialDeviceHomePage()),
            (route) => false);
      }
    }
    if (message.message == "petId") {
      await trackPetId();
    }

    if (message.message == "backButtonClicked") {
      logD.i("Back button clicked in WebView");
      backPageNavigator();
      return;
    }

    if (message.message == "showBottomSheet") {
      isShowBottomSheet = true;
      return;
    }
    if (message.message == "showSubBottomSheet") {
      isShowSubBottomSheet = true;
      return;
    }

    if (message.message == "closeBottomSheet") {
      isShowBottomSheet = false;
      return;
    }
    if (message.message == "closeSubBottomSheet") {
      isShowSubBottomSheet = false;
      return;
    }

    if (message.message == "openGallery") {
      _getImage(ImageSource.gallery);
      return;
    }

    if (message.message == "openCamera") {
      _getImage(ImageSource.camera);
      return;
    }

    if (message.message.startsWith("tel:")) {
      _makePhoneCall(message.message);
    }
  }

  Future<void> _getImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      final Uint8List bytes = await pickedFile.readAsBytes();
      // final String base64 = base64Encode(bytes);

      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        img.Image resizedImage = img.copyResize(originalImage, width: 500);
        List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 70);
        // Base64로 변환합니다.
        String? base64String = base64Encode(compressedBytes);
        controller.runJavaScript(
            'window.changeFile("data:image/jpeg;base64,$base64String")');
      }
    }
  }

  void _makePhoneCall(String url) async {
    if (await launchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw '전화 연결 실패: $url';
    }
  }

  void backPageNavigator() {
    if (widget.backPage != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => widget.backPage!),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<bool> onWillPopFunction() async {
    if (!Platform.isAndroid) {
      return true;
    } else {
      final currentUrl = await controller.currentUrl();
      if (currentUrl == null) {
        return true;
      }
      if (isShowSubBottomSheet) {
        controller.runJavaScript("closeSubBottomSheetAtFlutter();");
        return false;
      }
      if (isShowBottomSheet) {
        controller.runJavaScript("closeBottomSheetAtFlutter();");
        return false;
      }

      if (currentUrl.contains('/home') ||
          currentUrl.contains('/profile/register') ||
          currentUrl.contains('/timeline') ||
          currentUrl.contains('/ai-health')) {
        if (mounted) {
          if (widget.backPage != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => widget.backPage!),
              (route) => false,
            );
          } else {
            Navigator.pop(context);
          }
        }
      } else {
        controller.runJavaScript(
            "if (window.location.pathname !== '/') { window.history.back(); }");
      }
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    webViewInit();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
          onWillPop: onWillPopFunction,
          child: Column(
            children: [
              Expanded(
                child: WebViewWidget(
                  controller: controller
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..setNavigationDelegate(
                      NavigationDelegate(
                        onPageStarted: (String url) {
                          userInfoInit();
                        },
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
              )
            ],
          )),
    );
  }
}

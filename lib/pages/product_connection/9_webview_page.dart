import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petcarezone/pages/ai_health_camera_page.dart';
import 'package:petcarezone/pages/product_connection/1-1_initial_device_home_page.dart';
import 'package:petcarezone/pages/product_connection/2_device_list_page.dart';
import 'package:petcarezone/services/api_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:petcarezone/services/wifi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../constants/api_urls.dart';
import '../../utils/locale_manager.dart';
import '../../utils/logger.dart';
import '../../utils/webview_state_manager.dart';
import '../../widgets/indicator/indicator.dart';

class WebViewPage extends StatefulWidget {
  WebViewPage(
      {super.key,
      required this.uri,
      this.fcmUri,
      this.backPage,
      this.historyPeriod});

  final Uri uri;
  final Widget? backPage;
  Uri? fcmUri;
  String? historyPeriod;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  static const MethodChannel _channel =
      MethodChannel("com.lge.petcarezone/media");
  late final Widget webViewWidget;
  late final MqttServerClient client;
  final WebViewStateManager stateManager = WebViewStateManager();
  final UserService userService = UserService();
  final LunaService lunaService = LunaService();
  final ApiService apiService = ApiService();
  final DeviceService deviceService = DeviceService();
  final WifiService wifiService = WifiService();
  int petId = 0;
  String deviceId = "";
  String userId = "";
  String stateTopic = "";
  String eventTopic = "";
  bool isWebViewWidgetInitialized = false;
  bool isConnected = false;
  bool isDisposed = false;
  bool isWebViewActive = true;
  bool isRegisterPage = false;
  bool isShowBottomSheet = false;
  bool isShowSubBottomSheet = false;
  bool isShowModal = false;

  Uint8List? aiPresetImg;

  Widget buildWebViewWidget() {
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: stateManager.controller!.platform,
          displayWithHybridComposition: true,
        ),
      );
    } else {
      return WebViewWidget(controller: stateManager.controller!);
    }
  }

  Future<void> initializePage() async {
    await webViewInit();
    setState(() {
      webViewWidget = buildWebViewWidget();
      isWebViewWidgetInitialized = true;
    });
  }

  Future<void> webViewInit() async {
    stateManager.controller!
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            await userInfoInit();
          },
          onPageFinished: (String url) async {
            await mqttConnect();
          },
        ),
      )
      ..loadRequest(Uri.parse(ApiUrls.webViewUrl))
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) async {
          await jsChannelListener(message);
        },
      );
    final platformController = stateManager.controller!.platform;
    if (platformController is AndroidWebViewController) {
      platformController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          final locationPermissionStatus =
              await Permission.locationWhenInUse.request();
          return GeolocationPermissionsResponse(
            allow: locationPermissionStatus == PermissionStatus.granted,
            retain: false,
          );
        },
      );
    }
    await mqttInit();
  }

  Future mqttInit() async {
    final prefs = await SharedPreferences.getInstance();
    String userUuid = prefs.getString('uuid')!;
    client = MqttServerClient(
      'axjobfp4mqj2j-ats.iot.ap-northeast-2.amazonaws.com',
      userUuid,
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
        ..autoReconnect = true
        ..keepAlivePeriod = 60
        ..securityContext = context
        ..onConnected = onConnected
        ..onDisconnected = onDisconnected;
    } catch (e) {
      logD.e('Error loading certificates: $e');
    }
  }

  Future mqttConnect() async {
    if (isConnected) return;
    try {
      if (client.connectionStatus?.state == MqttConnectionState.disconnected) {
        await client.connect();
      }
    } catch (e) {
      logD.e('Error: $e');
      client.disconnect();
    }
  }

  /// MQTT Callback method
  void onConnected() {
    if (isConnected) return;
    isConnected = true;
    logD.i('Callback method result : MQTT 연결 성공');
    subscribe();
  }

  /// MQTT Callback method
  void onDisconnected() async {
    isConnected = false;
    logD.w('MQTT 연결 끊김');
    if (isWebViewActive && !isDisposed) {
      logD.i('MQTT 재연결 시도 중...');
      await mqttConnect();
    } else {
      logD.w('WebView 비활성 상태로 MQTT 재연결 시도하지 않음');
    }
  }

  void subscribe() {
    if (stateTopic.isNotEmpty && eventTopic.isNotEmpty) {
      client.subscribe(stateTopic, MqttQos.atLeastOnce);
      client.subscribe(eventTopic, MqttQos.atLeastOnce);
      client.updates.listen(onMessageReceived);
      logD.i(
          'Subscribing to topics: stateTopic $stateTopic, eventTopic $eventTopic');
    }
  }

  void onMessageReceived(List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final pt = MqttUtilities.bytesToStringAsString(recMess.payload.message!);
    final topic = c[0].topic;

    if (topic == "iot/petcarezone/topic/events/$deviceId") {
      stateManager.runJavaScript("handleEventTopicEvent($pt);");
    }
    if (topic == "iot/petcarezone/topic/states/$deviceId") {
      stateManager.runJavaScript("handleStateTopicEvent($pt);");
    }
    logD.i(
        'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
  }

  Future getBleInfo() async {
    return await deviceService.getBleInfo();
  }

  Future userInfoInit() async {
    await getUserInfo();
    await setUserInfo();
    logD.i(
        'initial Loaded userIds: userId: $userId, petId: $petId, deviceId: $deviceId');
  }

  Future getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId')!;
    deviceId = prefs.getString('deviceId')!;
    petId = prefs.getInt('petId')!;
    stateTopic = 'iot/petcarezone/topic/states/$deviceId';
    eventTopic = 'iot/petcarezone/topic/events/$deviceId';
  }

  Future setUserInfo() async {
    final accessToken = await userService.getAccessToken();
    await stateManager.runJavaScript("""
    localStorage.setItem('accessToken', '$accessToken');
    localStorage.setItem('userId', '$userId');
    localStorage.setItem('petId', '${petId == 0 ? "" : petId}');
    localStorage.setItem('deviceId', '${deviceId!.isEmpty ? "" : deviceId}');
    localStorage.setItem('ssid', '${await wifiService.getCurrentSSID()}');
    """);
  }

  /// 1. 초기 등록 & 펫 프로필 수정 시
  Future trackPetId() async {
    final petIdFromLocalStorage = await stateManager.controller!
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
    } else {
      logD.e('Pet id 없음.');
    }
  }

  Future setPetInfo() async {
    final petList = await apiService.getPetProfile(petId: petId);
    await lunaService.registerUserProfile(userId, petId);
    if (petList != null) {
      userService.saveLocalPetInfo(petList['petInfo']);
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

  Future jsChannelListener(message) async {
    switch (message.message) {
      case "setLanguage":
        final Locale lang = EasyLocalization.of(context)!.currentLocale!;
        await stateManager.runJavaScript("window.setLanguage('$lang')");
        break;
      case "setFlutterLanguage:ko":
        await LocaleManager.instance.setLocale(context, 'ko');
        break;
      case "setFlutterLanguage:en":
        await LocaleManager.instance.setLocale(context, 'en');
        break;
      case "home":
        if (widget.fcmUri != null) {
          final fcmUri = widget.fcmUri.toString();
          print('fcmUri $fcmUri');
          await stateManager.runJavaScript(
              "navigateToPetCareSection('$fcmUri', '${widget.historyPeriod}');");
          widget.fcmUri = null;
          print('widget.fcmUri ${widget.fcmUri}');
        }
        break;
      case "register":
        logD.i('now register page');
        isRegisterPage = true;
        break;
      case "setMobileStatusBarHeight":
        await stateManager.runJavaScript(
            "window.setMobileStatusBarHeight(${MediaQuery.of(context).padding.top})");
        break;

      case "changeNetwork":
        logD.i('changeNetwork');
        if (mounted && context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeviceListPage(
                isFromWebView: true,
              ),
            ),
          );
        }
        break;

      case "deleteDevice":
        logD.w("Device info deleted. Navigate to device register page.");
        await userService.deleteUserInfo();
        if (mounted) {
          return Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const InitialDeviceHomePage()),
              (route) => false);
        }
        break;

      case "petId":
        await trackPetId();
        await mqttConnect();
        break;

      case "backButtonClicked":
        logD.i("Back button clicked in WebView");
        backPageNavigator();
        break;

      case "showBottomSheet":
        isShowBottomSheet = true;
        break;

      case "showSubBottomSheet":
        isShowSubBottomSheet = true;
        break;

      case "showModal":
        isShowModal = true;
        break;

      case "closeBottomSheet":
        isShowBottomSheet = false;
        break;

      case "closeSubBottomSheet":
        isShowSubBottomSheet = false;
        break;

      case "closeModal":
        isShowModal = false;
        break;

      case "openGallery":
        _getImage(ImageSource.gallery);
        break;

      case "openCamera":
        _getImage(ImageSource.camera);
        break;
      case "openAnimalSite":
        launchUrl(
          Uri.parse('https://www.animal.go.kr'),
        );
        break;

      default:
        if (message.message.startsWith('data:image/png')) {
          return await saveFile(message.message, 'png');
        }
        if (message.message.startsWith('data:video/mp4')) {
          return saveFile(message.message, 'mp4');
        }
        if (message.message.startsWith("tel:")) {
          _makePhoneCall(message.message);
        }
        if (message.message.startsWith("aiCamGuideImage:")) {
          String base64String = message.message.split(':')[1];
          aiPresetImg =
              base64String.isNotEmpty ? base64Decode(base64String) : null;
        }
        if (message.message.startsWith("openAICamAtFlutter:")) {
          String type = message.message.split(':')[1];
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AIHealthCameraPage(
                      type: type,
                      aiPresetImg: aiPresetImg,
                      cameraShutFunction: (String base64) {
                        _uploadPicture(base64);
                      })),
            );
          }
        }
        break;
    }
  }

  void _uploadPicture(String base64String) {
    Future.delayed(
        const Duration(milliseconds: 150),
        () => {
              stateManager.runJavaScript(
                  'window.uploadAIPhotoAtFlutter("data:image/jpeg;base64,$base64String")')
            });
  }

  Future _getImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      final Uint8List bytes = await pickedFile.readAsBytes();

      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        img.Image resizedImage = img.copyResize(originalImage, width: 500);
        List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 70);
        String? base64String = base64Encode(compressedBytes);
        stateManager.runJavaScript(
            'window.changeFile("data:image/jpeg;base64,$base64String")');
      }
    }
  }

  Future _makePhoneCall(String url) async {
    if (await launchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw '전화 연결 실패: $url';
    }
  }

  Future<bool> onWillPopFunction() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final currentUrl = await stateManager.controller!.currentUrl();
    if (currentUrl == null) {
      return true;
    }
    if (isShowModal) {
      stateManager.runJavaScript("closeModalAtFlutter();");
      return false;
    }
    if (isShowSubBottomSheet) {
      stateManager.runJavaScript("closeSubBottomSheetAtFlutter();");
      return false;
    }
    if (isShowBottomSheet) {
      stateManager.runJavaScript("closeBottomSheetAtFlutter();");
      return false;
    }

    List splittedUrl = currentUrl.split('/');
    if (splittedUrl.isEmpty) {
      return true;
    }
    String path = splittedUrl.last;
    if (path == 'home' ||
        path == 'register' ||
        path == 'timeline' ||
        path == 'ai-health') {
      logD.i("Flutter 경로에서 뒤로가기 처리.");
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
        return false;
      }
    } else {
      if (splittedUrl.contains("ai-health") && splittedUrl.contains("result")) {
        logD.i("AI Health 결과 페이지 뒤로가기.");
        stateManager.runJavaScript("window.moveBackByStep(-3);");
      } else {
        print('currentUrlcurrentUrl $currentUrl');
        logD.i("JavaScript로 일반 뒤로가기 처리.");
        stateManager.runJavaScript(
            "if (window.location.pathname !== '/') { window.history.back(); }");
      }
      return false;
    }
    return true;
  }

  void backPageNavigator() async {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getBleInfo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      isWebViewActive = true;
      logD.i("WebView 상태 $state $isWebViewActive");
    } else {
      isWebViewActive = false;
      logD.i("WebView 상태 $state $isWebViewActive");
      if (isRegisterPage && state == AppLifecycleState.detached) {
        await lunaService.resetDevice();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    stateManager.setWebViewActive(true);
    stateManager.setController(WebViewController());
    WidgetsBinding.instance.addObserver(this);
    initializePage();
  }

  @override
  void dispose() {
    isDisposed = true;
    client.disconnect();
    WidgetsBinding.instance.removeObserver(this);
    stateManager.setWebViewActive(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: onWillPopFunction,
        child: isWebViewWidgetInitialized
            ? Column(children: [Expanded(child: webViewWidget)])
            : const Center(child: GradientCircularLoader(size: 30.0)),
      ),
    );
  }
}

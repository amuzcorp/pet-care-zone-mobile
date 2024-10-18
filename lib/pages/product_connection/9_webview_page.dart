import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petcarezone/constants/api_urls.dart';
import 'package:petcarezone/pages/product_connection/1-1_initial_device_home_page.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../services/connect_sdk_service.dart';
import '../../utils/logger.dart';
import '../../widgets/navigator/navigator.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, required this.uri, this.backPage});

  final Uri uri;
  final Widget? backPage;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  static const MethodChannel _channel = MethodChannel("com.lge.petcarezone/media");
  late final WebViewController controller;
  late final PlatformWebViewControllerCreationParams params;
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final userService = UserService();
  final deviceService = DeviceService();
  final lunaService = LunaService();
  String? deviceId = "";
  String userId = "";
  int petId = 0;
  bool isSetPetInfo = false;

  Future webViewInit() async {
    params = const PlatformWebViewControllerCreationParams();
    controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (WebViewPermissionRequest request) {
        request.grant();
      },
    );
    final platformController = controller.platform;

    if (platformController is AndroidWebViewController) {
      platformController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          // request location permission
          final locationPermissionStatus = await Permission.locationWhenInUse.request();

          // return the response
          return GeolocationPermissionsResponse(
            allow: locationPermissionStatus == PermissionStatus.granted,
            retain: false,
          );
        },
      );
    }
  }
  Future userInfoInit() async {
    await getUserInfo();
    await setUserInfo();
    logD.i('initial Loaded userIds: userId: $userId, petId: $petId, deviceId: $deviceId');
  }

  /// 1. get user info
  Future getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId')!;
    deviceId = prefs.getString('deviceId');
    petId = prefs.getInt('petId')!;
  }

  /// 2. set user info
  Future setUserInfo() async {
    final accessToken = await userService.getAccessToken();
    print('setUserInfo accesst $accessToken');
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
    final petIdFromLocalStorage = await controller.runJavaScriptReturningResult("""localStorage.getItem('petId');""");
    String petIdStr = petIdFromLocalStorage.toString().replaceAll('"', '');
    print('petIdStr $petIdStr');
    /// 2. petId 있는 경우
    if (petIdStr.isNotEmpty) {
      logD.i('PetId updated to $petIdStr, stopping tracking.');
      petId = int.tryParse(petIdStr)!;
      print('petId $petId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('petId', petId);

      /// 3. device에 pet,user info 등록
      await setPetInfo();
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
    final accessToken = await controller.runJavaScriptReturningResult("localStorage.getItem('accessToken')");
    final userId = await controller.runJavaScriptReturningResult("localStorage.getItem('userId')");
    final petId = await controller.runJavaScriptReturningResult("localStorage.getItem('petId')");
    final deviceId = await controller.runJavaScriptReturningResult("localStorage.getItem('deviceId')");
    logD.i('Fetched from localStorage - accessToken: $accessToken, userId: $userId, petId: $petId, deviceId: $deviceId');
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

      final filePath = '${folder.path}/${DateTime.now().millisecondsSinceEpoch}.$format';

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
    if (message.message == "deleteDevice") {
      logD.i("Device info deleted. navigate to device register page.");
      await userService.deleteUserInfo();
      if (mounted) {
        navigator(context, () => const InitialDeviceHomePage());
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
        )
      ),
    );
  }
}

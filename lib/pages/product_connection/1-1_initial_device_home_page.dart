import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/pages/product_connection/1-2_power_check_page.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import 'package:petcarezone/widgets/cards/initial_device_register_card.dart';
import 'package:petcarezone/widgets/dialog/permission_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/api_urls.dart';
import '../../constants/color_constants.dart';
import '../../constants/icon_constants.dart';
import '../../constants/image_constants.dart';
import '../../data/models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/logger.dart';
import '../../widgets/page/basic_page.dart';
import '9_webview_page.dart';

class InitialDeviceHomePage extends StatefulWidget {
  const InitialDeviceHomePage({super.key});

  @override
  State<InitialDeviceHomePage> createState() => _InitialDeviceHomePageState();
}

class _InitialDeviceHomePageState extends State<InitialDeviceHomePage> {
  final PermissionCheckDialog permissionCheckDialog = PermissionCheckDialog();
  final UserService userService = UserService();
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final DeviceService deviceService = DeviceService();
  final FirebaseService firebaseService = FirebaseService();
  Widget destinationPage = const PowerCheckPage();
  String deviceName = "";
  String? fcmToken = "";
  bool isRegistered = false;
  bool isDeviceReady = false;
  bool isTapOn = false;

  Future getFcmInfo() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        fcmToken = token;
        firebaseService.setFcmToken(token);
        logD.i('fcm Token in LifeCycleChecker : $token');
      }
    }).catchError((err) {
      logD.e("초기 토큰 가져오기 중 오류 발생: $err");
    });
  }

  Future<void> validateUserInfo() async {
    UserModel? userInfo = await userService.getUserInfo();
    String userId = userInfo!.userId;
    String? deviceId = userInfo.deviceList.isNotEmpty ? userInfo.deviceList.first.deviceId : "";
    int petId = userInfo.petList.isNotEmpty ? userInfo.petList.first.petId : 0;
    deviceName = userInfo.deviceList.isNotEmpty ? userInfo.deviceList.first.deviceName : "";
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userId', userId);
    await prefs.setInt('petId', petId);
    await prefs.setString('deviceId', deviceId!);

    logD.i('[Userinfo]\nuserId:$userId\npetId: $petId\ndeviceId: $deviceId\ndeviceName: $deviceName');

    if (userId.isNotEmpty && petId != 0 && deviceId.isNotEmpty) {
      setState(() {
        isRegistered = true;
        destinationPage = WebViewPage(
          uri: Uri.parse(ApiUrls.webViewUrl),
          backPage: const InitialDeviceHomePage(),
        );
      });
    }
  }

  Future userInfoLoad() async {
    await getFcmInfo();
    validateUserInfo();
    firebaseService.refreshFcmToken();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userInfoLoad();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final isPermitted = prefs.getBool('isPermitted') ?? false;
      if (!isPermitted && mounted) {
        await permissionCheckDialog.showPermissionAlertDialog(context);
      }
    });
    connectSdkService.setupLogListener();
    connectSdkService.startLogSubscription((data) {});
  }

  @override
  void dispose() {
    connectSdkService.logSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: false,
      backgroundImage: Image.asset(
        ImageConstants.productConnectionGuide1,
        fit: BoxFit.cover,
      ),
      contentWidget: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () async {
                  setState(() {
                    isTapOn = !isTapOn;
                  });
                },
                child: Text(
                  '홈',
                  style: TextStyle(
                    fontSize: FontConstants.descriptionTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          boxH(30),
          InitialDeviceRegisterCard(
            iconUrl: IconConstants.deviceNameEditIcon,
            iconColor: ColorConstants.blackIcon,
            text: deviceName,
            bgColor: ColorConstants.white,
            destinationPage: destinationPage,
            isRegistered: isRegistered,
          ),
          boxH(10),
          if (isTapOn) Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                'fcmToken: $fcmToken',
              )
            ],
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/pages/product_connection/1-2_power_check_page.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import 'package:petcarezone/widgets/cards/initial_device_register_card.dart';
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
  final UserService userService = UserService();
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final DeviceService deviceService = DeviceService();
  Widget destinationPage = const PowerCheckPage();
  String deviceName = "";
  bool isRegistered = false;
  bool isDeviceReady = false;

  List<String> logMessages = [];

  Future connectToDevice() async {
    final webOSDeviceInfo = await deviceService.getWebOSDeviceInfo();
    if (webOSDeviceInfo.isNotEmpty && !isDeviceReady) {
      connectSdkService.setupListener();
      await deviceService.deviceInitialize();
      await deviceService.connectToDevice();
      isDeviceReady = true;
      connectSdkService.logStreamController.add("device connection is completed.");
    }
  }

  Future<void> validateUserInfo() async {
    UserModel? userInfo = await userService.getUserInfo();
    if (userInfo != null) {
      String userId = userInfo.userId;
      String? deviceId = userInfo.deviceList.isNotEmpty ? userInfo.deviceList.first.deviceId : "";
      int petId = userInfo.petList.isNotEmpty ? userInfo.petList.first.petId : 0;
      deviceName = userInfo.deviceList.isNotEmpty ? userInfo.deviceList.first.deviceName : "";
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userId', userId);
      await prefs.setInt('petId', petId);
      await prefs.setString('deviceId', deviceId!);

      logD.i('[Userinfo]\nuserId:$userId\npetId: $petId\ndeviceId: $deviceId\n deviceName: $deviceName');

      if (userId.isNotEmpty && petId != 0 && deviceId.isNotEmpty) {
        setState(() {
          isRegistered = true;
          destinationPage = WebViewPage(
            uri: Uri.parse(ApiUrls.webViewUrl),
            backPage: const InitialDeviceHomePage(),
          );
        });
      }
    } else {
      logD.e('User info is null');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    validateUserInfo();
  }

  @override
  void initState() {
    super.initState();
    connectSdkService.setupLogListener();
    connectSdkService.startLogSubscription((data) {});
    connectToDevice();
  }

  @override
  void dispose() {
    connectSdkService.cancelLogSubscription();
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
              Text(
                '홈',
                style: TextStyle(
                  fontSize: FontConstants.descriptionTextSize,
                  fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}

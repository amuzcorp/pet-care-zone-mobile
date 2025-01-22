import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/pages/product_connection/1-2_power_check_page.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:petcarezone/utils/locale_manager.dart';
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
  final FirebaseService firebaseService = FirebaseService();
  Widget destinationPage = const PowerCheckPage();
  String deviceName = "";
  String? fcmToken = "";
  bool isRegistered = false;
  bool isTapOn = false;

  Future<void> getFcmInfo() async {
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

  Future<void> userInfoLoad() async {
    await getFcmInfo();
    await validateUserInfo();
    firebaseService.refreshFcmToken();
  }

  void initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final isPermitted = prefs.getBool('isPermitted') ?? false;
      if (!isPermitted && mounted) {
        await permissionCheckDialog.showPermissionAlertDialog(context);
      }
    });
    connectSdkService.setupLogListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userInfoLoad();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    if (connectSdkService.logSubscription != null) {
      connectSdkService.logSubscription!.cancel();
    }
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
      contentWidget: _contentWidget()
    );
  }

  Widget _contentWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _homeTitle()
          ],
        ),
        boxH(30),
        _deviceRegisterCard(),
        boxH(10),
        if (isTapOn) _fcmToken()
      ],
    );
  }

  Widget _homeTitle() {
    return InkWell(
      onTap: () async {
        setState(() {
          isTapOn = !isTapOn;
        });
        final locale = await LocaleManager.instance.getLocale();
        if (locale.toString() == 'ko') {
          if (mounted) {
            await LocaleManager.instance.setLocale(context, 'en');
          }
        } else {
          if (mounted) {
            await LocaleManager.instance.setLocale(context, 'ko');
          }
        }

      },
      child: Text(
        'first_use.register.home.title'.tr(),
        style: TextStyle(
          fontSize: FontConstants.descriptionTextSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _deviceRegisterCard() {
    return InitialDeviceRegisterCard(
      iconUrl: IconConstants.deviceNameEditIcon,
      iconColor: ColorConstants.blackIcon,
      text: deviceName,
      bgColor: ColorConstants.white,
      destinationPage: destinationPage,
      isRegistered: isRegistered,
    );
  }

  Widget _fcmToken() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          'fcmToken: $fcmToken',
        )
      ],
    );
  }
}

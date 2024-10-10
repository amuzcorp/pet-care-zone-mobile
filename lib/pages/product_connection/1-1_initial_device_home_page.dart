import 'package:flutter/material.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/pages/product_connection/2_device_list_page.dart';
import 'package:petcarezone/widgets/box/box.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/images/image_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/api_urls.dart';
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
  Widget destinationPage = const DeviceListPage();

  Future<void> validateUserInfo() async {
    UserModel? userInfo = await userService.getUserInfo();

    if (userInfo != null) {
      String userId = userInfo.userId;
      int petId = userInfo.petList.isNotEmpty ? userInfo.petList.first.petId : 0;
      String? deviceId = userInfo.deviceList.isNotEmpty ? userInfo.deviceList.first.deviceId : "";

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userId', userId);
      await prefs.setInt('petId', petId);
      await prefs.setString('deviceId', deviceId!);

      logD.i('[Userinfo]\nuserId:$userId\npetId: $petId\ndeviceId: $deviceId');

      if (userId.isNotEmpty && petId != 0 && deviceId.isNotEmpty) {
        setState(() {
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
  void initState() {
    super.initState();
    validateUserInfo();
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
          boxH(10),
          BasicButton(text: "aa", height: 100, width: 150,),

        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:petcarezone/pages/product_connection/2_device_list_page.dart';
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

class PowerCheckPage extends StatefulWidget {
  const PowerCheckPage({super.key});

  @override
  State<PowerCheckPage> createState() => _PowerCheckPageState();
}

class _PowerCheckPageState extends State<PowerCheckPage> {
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
              uri: Uri.parse(ApiUrls.webViewUrl), backPage: const PowerCheckPage(),
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
      leadingHeight: 60,
      topHeight: 70,
      description: 'Pet Care Zone의 전원 코드를\n연결해 전원을 켜주세요.',
      contentWidget: Column(
        children: [
          guideImageWidget(imagePath: ImageConstants.productConnectionGuide2)
        ],
      ),
      bottomButton: BasicButton(
        text: '전원을 켰어요',
        onPressed: () => {
          if (mounted)
            {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destinationPage),
              )
            }
        },
      ),
    );
  }
}

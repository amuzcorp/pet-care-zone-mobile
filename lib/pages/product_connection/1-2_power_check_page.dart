import 'package:flutter/material.dart';
import 'package:petcarezone/pages/product_connection/2_device_list_page.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/images/image_widget.dart';

import '../../constants/image_constants.dart';
import '../../services/user_service.dart';
import '../../widgets/page/basic_page.dart';

class PowerCheckPage extends StatefulWidget {
  const PowerCheckPage({super.key});

  @override
  State<PowerCheckPage> createState() => _PowerCheckPageState();
}

class _PowerCheckPageState extends State<PowerCheckPage> {
  final UserService userService = UserService();
  Widget destinationPage = const DeviceListPage();

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
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

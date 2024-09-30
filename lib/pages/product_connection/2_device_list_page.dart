import 'package:flutter/material.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/widgets/box/box.dart';

import '../../widgets/lists/device_list.dart';
import '../../widgets/page/basic_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "연결 가능한 제품",
      contentWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          boxH(80),
          FontConstants.inputLabelText('주변 제품'),
          boxH(10),
          const DeviceList(),
        ],
      ),
    );
  }
}

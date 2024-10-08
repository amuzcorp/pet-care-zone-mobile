import 'package:flutter/material.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/widgets/box/box.dart';

import '../../widgets/indicator/indicator.dart';
import '../../widgets/lists/device_list.dart';
import '../../widgets/page/basic_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  late ValueNotifier<bool> isLoading;

  @override
  void initState() {
    super.initState();
    isLoading = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    isLoading.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "연결 가능한 제품",
      contentWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          boxH(80),
          Row(
            children: [
              FontConstants.inputLabelText('주변 제품'),
              SizedBox(
                width: 30,
                height: 30,
                child: ValueListenableBuilder<bool>(
                  valueListenable: isLoading,
                  builder: (context, loading, _) {
                    return loading ? const GradientCircularLoader(size: 30.0) : const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          boxH(10),
          DeviceList(
            onLoadingChanged: (loading) {
              isLoading.value = loading;
            },
          ),
        ],
      ),
    );
  }
}

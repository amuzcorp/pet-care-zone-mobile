import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/message_service.dart';
import 'package:petcarezone/widgets/box/box.dart';

import '../../widgets/indicator/indicator.dart';
import '../../widgets/lists/device_list.dart';
import '../../widgets/page/basic_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key, required this.isFromWebView});
  final bool isFromWebView;
  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final MessageService messageService = MessageService();
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
      description: "first_use.register.connect_to_ble.title".tr(),
      contentWidget: Column(
        children: [
          boxH(80),
          Row(
            children: [
              FontConstants.inputLabelText('first_use.register.connect_to_ble.nearby_products'.tr()),
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
            isFromWebview : widget.isFromWebView,
            onLoadingChanged: (loading) {
              isLoading.value = loading;
            },
          ),
        ],
      ),
      bottomButton: StreamBuilder<String>(
        stream: messageService.messageController.stream,
        builder: (context, snapshot) {
          if (snapshot.data != null && snapshot.data!.isNotEmpty) {
            return Text(snapshot.data!, style: TextStyle(color: ColorConstants.red));
          }
          return Container();
        },
      ),
    );
  }
}

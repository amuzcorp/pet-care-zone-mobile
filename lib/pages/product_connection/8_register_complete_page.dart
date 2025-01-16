import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/icon_constants.dart';
import 'package:petcarezone/data/models/device_model.dart';
import 'package:petcarezone/pages/product_connection/1-1_initial_device_home_page.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/luna_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/cards/device_register_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_urls.dart';
import '../../services/connect_sdk_service.dart';
import '../../widgets/indicator/indicator.dart';
import '../../widgets/page/basic_page.dart';
import '9_webview_page.dart';

class RegisterCompletePage extends StatefulWidget {
  const RegisterCompletePage({super.key});

  @override
  State<RegisterCompletePage> createState() => _RegisterCompletePageState();
}

class _RegisterCompletePageState extends State<RegisterCompletePage> {
  final DeviceService deviceService = DeviceService();
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final LunaService lunaService = LunaService();
  bool isLoading = false;
  String deviceId = '';
  String deviceName = 'first_use.register.connect_to_device.register.product_name.tr'.tr();
  String modelNumber = '';
  String guideMessage = 'first_use.register.connect_to_device.register.change_product_name'.tr();

  Future getWebOSDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final webOSDeviceInfo = await deviceService.getWebOSDeviceInfo();
    modelNumber = await webOSDeviceInfo['modelNumber'];
    deviceId = prefs.getString("deviceId")!;
  }

  Future registerDeviceInfo() async {
    await getWebOSDeviceInfo();
    final deviceInfo = DeviceModel(deviceId: deviceId, serialNumber: modelNumber, deviceName: deviceName);
    setState(() {
      isLoading = true;
    });
    await deviceService.registerDevice(
      deviceId,
      deviceName,
      modelNumber,
    );
    await deviceService.provisionDevice(deviceId!);
    await deviceService.saveLocalDeviceInfo(deviceInfo.toJson());
    setState(() {
      isLoading = false;
    });
  }

  void _updateDeviceName(String newName) {
    setState(() {
      deviceName = newName;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached) {
      await lunaService.resetDevice();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: false,
      description: "first_use.register.connect_to_device.register.title".tr(),
      leadingHeight: 40.0,
      contentWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DeviceRegisterCard(
            iconUrl: IconConstants.deviceNameEditIcon,
            iconColor: ColorConstants.blackIcon,
            text: deviceName,
            bgColor: ColorConstants.white,
            onTextChanged: _updateDeviceName,
          ),
          boxH(15),
          Text(
            guideMessage,
            style: TextStyle(
              color: ColorConstants.inputLabelColor,
            ),
          ),
        ],
      ),
      bottomButton: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          isLoading ? const GradientCircularLoader() : Container(),
          boxH(10),
          BasicButton(
            text: 'first_use.register.connect_to_device.register.register_additional_information'.tr(),
            backgroundColor: Colors.transparent,
            fontColor: ColorConstants.teal,
            fontSize: 15,
          ),
          BasicButton(
            text: "first_use.register.connect_to_device.register.register_pet_profile".tr(),
            onPressed: () async {
              await registerDeviceInfo();
              if (mounted && deviceId.isNotEmpty && deviceName.isNotEmpty && modelNumber.isNotEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebViewPage(
                        uri: Uri.parse(ApiUrls.webViewUrl),
                        backPage: const InitialDeviceHomePage(),
                      ),
                    ),
                  );
              } else {
                guideMessage = "first_use.register.connect_to_device.register.register_fail".tr();
              }
            },
          ),
        ],
      ),
    );
  }
}

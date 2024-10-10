import 'package:flutter/material.dart';
import 'package:petcarezone/constants/color_constants.dart';
import 'package:petcarezone/constants/icon_constants.dart';
import 'package:petcarezone/data/models/device_model.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/widgets/box/box.dart';
import 'package:petcarezone/widgets/buttons/basic_button.dart';
import 'package:petcarezone/widgets/cards/device_register_card.dart';
import '../../constants/api_urls.dart';
import '../../services/connect_sdk_service.dart';
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
  DeviceModel? deviceModel;
  String deviceName = '';

  Future<void> getDeviceInfo() async {
    deviceModel = await deviceService.getDeviceInfo();
    setState(() {
      deviceName = deviceModel?.deviceName ?? '';
    });
  }

  Future<void> modifyDeviceInfo() async {
    if (deviceModel != null) {
      await deviceService.modifyDevice(
        deviceModel!.deviceId,
        deviceName,
        deviceModel!.serialNumber,
      );
    }
  }

  void _updateDeviceName(String newName) {
    setState(() {
      deviceName = newName;
    });
    print('deviceName $deviceName');
  }

  @override
  void initState() {
    super.initState();
    getDeviceInfo();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "Pet Care Zone 추가를\n완료했어요.",
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
            '제품 이름을 바꿀 수 있어요.',
            style: TextStyle(
              color: ColorConstants.inputLabelColor,
            ),
          ),
        ],
      ),
      bottomButton: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BasicButton(
            text: '더 정확한 서비스를 위해 추가 정보 등록하기 >',
            backgroundColor: Colors.transparent,
            fontColor: ColorConstants.teal,
            fontSize: 15,
          ),
          BasicButton(
            text: "반려동물 프로필 등록",
            onPressed: () => {
              modifyDeviceInfo(),
              if (mounted)
                {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebViewPage(
                        uri: Uri.parse(ApiUrls.webViewUrl),
                        backPage: const RegisterCompletePage(),
                      ),
                    ),
                  )
                }
            },
          ),
        ],
      ),
    );
  }
}

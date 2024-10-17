import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/pages/product_connection/4_pincode_check_page.dart';
import 'package:petcarezone/services/ble_service.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/message_service.dart';

import '../../constants/color_constants.dart';
import '../../constants/size_constants.dart';
import '../../data/models/device_model.dart';
import '../../services/luna_service.dart';
import '../../services/wifi_service.dart';
import '../../utils/logger.dart';
import '../../widgets/box/box.dart';
import '../../widgets/buttons/basic_button.dart';
import '../../widgets/indicator/indicator.dart';
import '../../widgets/page/basic_page.dart';

class WifiConnectionPage extends StatefulWidget {
  const WifiConnectionPage({super.key});

  @override
  State<WifiConnectionPage> createState() => _WifiConnectionPageState();
}

class _WifiConnectionPageState extends State<WifiConnectionPage> {
  final WifiService wifiService = WifiService();
  final DeviceService deviceService = DeviceService();
  final LunaService lunaService = LunaService();
  final BleService bleService = BleService();
  final MessageService messageService = MessageService();
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final TextEditingController passwordController = TextEditingController();
  final LayerLink layerLink = LayerLink();

  late StreamController<String> messageController;

  Uint8List? macAddressArray;
  String? macAddressWithSeparatorString = "";

  String selectedWifi = "";
  String selectedSecurityType = "";
  String password = "";
  bool isLoading = false;
  BluetoothCharacteristic? targetCharacteristic;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bleService.getCharacteristics();
  }

  @override
  void initState() {
    super.initState();
    wifiService.initialize();
    messageController = messageService.messageController;
    connectSdkService.setupListener();
    connectSdkService.startScan();
    passwordController.clear();
    logD.i('BLE connectedDevice ${bleService.connectedDevice}');
  }

  @override
  void dispose() {
    wifiService.dispose();
    connectSdkService.stopScan();
    passwordController.dispose();
    messageController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "Pet Care Zone에 연결할\nWi-Fi 네트워크를 아래 화면에서\n선택해주세요.",
      topHeight: 50,
      contentWidget: Column(
        children: [
          Row(
            children: [
              FontConstants.inputLabelText('Wi-Fi 네트워크'),
            ],
          ),
          boxH(10),
          widgetWifiDropdown(),
          boxH(20),
          Row(
            children: [
              FontConstants.inputLabelText('비밀번호'),
            ],
          ),
          boxH(10),
          widgetPasswordField(),
          boxH(16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                isLoading ? const GradientCircularLoader() : Container(),
                errorStreamBuilder(),
              ],
            )
          ),
          boxH(16),
        ],
      ),
      bottomButton: BasicButton(
        text: "연결하기",
        onPressed: connectToWifi,
      ),
    );
  }

  Widget errorStreamBuilder() {
    return StreamBuilder<String>(
      stream: messageController.stream,
      builder: (context, snapshot) {
        String errorText = snapshot.data ?? "";
        return Text(errorText, style: TextStyle(color: ColorConstants.red),);
      },
    );
  }

  Widget widgetWifiDropdown() {
    return StreamBuilder<List<Map<String, String>>>(
      stream: wifiService.wifiStream,
      builder: (context, snapshot) {
        List<Map<String, String>> wifiInfos = snapshot.data ?? [];
        print('wifiInfos $wifiInfos');
        if (wifiInfos.isNotEmpty) {
          final firstSsid = wifiInfos[0]['SSID'] ?? "";
          final firstSecurityType = wifiInfos[0]['securityType']?.toLowerCase().contains("");

          if (selectedWifi.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedWifi = firstSsid;
              });
            });
          }
        }

        return CompositedTransformTarget(
          link: LayerLink(),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: ColorConstants.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                borderSide: BorderSide(
                  color: ColorConstants.border,
                  width: SizeConstants.borderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                borderSide: BorderSide(
                  color: ColorConstants.activeBorder,
                  width: SizeConstants.borderWidth,
                ),
              ),
              counterText: "",
            ),
            value: wifiInfos.any((wifi) => wifi['SSID'] == selectedWifi) ? selectedWifi : null,
            hint: Text(wifiInfos.isNotEmpty ? wifiInfos[0]['SSID'] ?? "Wi-Fi Scanning..." : "Wi-Fi Scanning..."),
            items: wifiInfos.map((wifi) {
              return DropdownMenuItem<String>(
                value: wifi['SSID'],
                child: Text(wifi['SSID'] ?? ''),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedWifi = newValue ?? '';
              });
            },
          ),
        );
      },
    );
  }

  Widget widgetPasswordField() {
    return TextFormField(
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        filled: true,
        fillColor: ColorConstants.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConstants.borderSize),
          borderSide: BorderSide(
            color: ColorConstants.border,
            width: SizeConstants.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConstants.borderSize),
          borderSide: BorderSide(
            color: ColorConstants.activeBorder,
            width: SizeConstants.borderWidth,
          ),
        ),
        counterText: "",
      ),
      controller: passwordController,
      obscureText: true,
      onChanged: (value) {
        setState(() {
          password = value;
        });
      },
    );
  }

  Future<void> navigateToPincodeCheckPage() async {
    wifiService.scanTimer?.cancel();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PincodeCheckPage()));
  }

  Future<void> connectToWifi() async {
    // if (!mounted) return;
    if (!await checkWifiConnection()) return;
    if (!checkPassword()) return;
    if (bleService.connectedDevice == null) {
      messageController.add('* BLE 연결을 확인해주세요.');
      return;
    }

    setState(() {
      isLoading = true;
    });
    try {
      await bleService.setRegistration();
      await bleService.sendWifiCredentialsToBLE(selectedWifi, password);
      await getWebosDeviceInfoAndNavigate();
    } catch (e) {
      errorListener(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  errorListener(error) async {
    String bleErrorText = e.toString().toLowerCase();
    if (bleErrorText.contains('disconnect')) {
      messageController.add('기기와 연결이 끊어졌어요.\n뒤로 가서 다시 메뉴를 눌러 기기를 연결해 주세요.');
    } else {
      messageController.add('에러가 발생했어요. $error');
    }
  }

  Future getWebosDeviceInfoAndNavigate() async {
    await Future.delayed(const Duration(seconds: 4));
    final matchedWebosDevice = connectSdkService.matchedWebosDevice;

    print('matchedWebosDevice $matchedWebosDevice');

    if (matchedWebosDevice.isNotEmpty) {
      messageController.add('');

      /// DeviceModel 생성
      final deviceModel = DeviceModel(
        serialNumber: matchedWebosDevice['modelNumber'],
        deviceName: matchedWebosDevice['friendlyName'],
        deviceIp: matchedWebosDevice['lastKnownIPAddress'],
      );

      /// webOS Whole Data 저장
      await deviceService.saveWebOSDeviceInfo(matchedWebosDevice);

      /// webOS 필요한 Data 저장
      await deviceService.saveDeviceInfo(deviceModel);
      navigateToPincodeCheckPage();
    } else {
      messageController.add('webOS 기기 연결이 되지 않았어요.\n연결하기 버튼을 한번 더 눌러주세요.');
    }
  }

  Future<bool> checkWifiConnection() async {
    String currentWifi = await wifiService.getCurrentSSID();
    print('currentWifi $currentWifi');
    if (currentWifi != selectedWifi) {
      messageController.add('*연결할 Wi-Fi가 다릅니다.\n현재 Wi-Fi: $currentWifi');
      return false;
    }
    return true;
  }

  bool checkPassword() {
    if (password.isEmpty) {
      messageController.add('*Wi-Fi 비밀번호를 입력해주세요.');
      return false;
    }
    return true;
  }
}

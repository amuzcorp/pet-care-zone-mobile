import 'dart:async';
import 'dart:math';

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
  final LayerLink _layerLink = LayerLink();


  late StreamController<String> messageController;

  Uint8List? macAddressArray;
  String? macAddressWithSeparatorString = "";

  String selectedWifi = "";
  String selectedSecurityType = "";
  String password = "";
  bool isLoading = false;
  bool _isDropdownOpen = false;

  BluetoothCharacteristic? targetCharacteristic;

  OverlayEntry? _overlayEntry;

  void _openDropdown(List<Map<String, String>> wifiInfos) {
    if (!_isDropdownOpen) {
      _overlayEntry = _createDropdown(wifiInfos);
      Overlay.of(context)?.insert(_overlayEntry!);
      setState(() {
        _isDropdownOpen = true;
      });
    }
  }

  // 드롭다운 닫기
  void _closeDropdown() {
    _overlayEntry?.remove();
    setState(() {
      _isDropdownOpen = false;
    });
  }

  OverlayEntry _createDropdown(List<Map<String, String>> wifiInfos) {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 40,
          height: MediaQuery.of(context).size.height * 0.4,
          child: CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(0, 60),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SizeConstants.borderSize),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                child: SingleChildScrollView(
                  child: Column(
                    children: _buildDropdownItems(wifiInfos),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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

  List<Widget> _buildDropdownItems(List<Map<String, String>> wifiInfos) {
    List<Widget> items = [];

    for (int i = 0; i < wifiInfos.length; i++) {
      BorderRadius borderRadius = BorderRadius.zero;

      if (i == 0) {
        // 첫 번째 타일의 위쪽 모서리에만 borderRadius 적용
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        );
      } else if (i == wifiInfos.length - 1) {
        // 마지막 타일의 아래쪽 모서리에만 borderRadius 적용
        borderRadius = const BorderRadius.only(
          bottomLeft: Radius.circular(10.0),
          bottomRight: Radius.circular(10.0),
        );
      }

      items.add(
        ClipRRect(
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () {
              setState(() {
                selectedWifi = wifiInfos[i]['SSID'] ?? '';
                _closeDropdown();
              });
            },
              child: ListTile(
                title: Text(
                  wifiInfos[i]['SSID'] ?? 'Wi-Fi Scanning...',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ),
        ),
      );

      // 마지막 아이템 뒤에는 Divider를 추가하지 않도록 조건을 설정
      if (i < wifiInfos.length - 1) {
        items.add(const Divider(height: 0));
      }
    }

    return items;
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

        if (wifiInfos.isNotEmpty && selectedWifi.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedWifi = wifiInfos[0]['SSID'] ?? "";
            });
          });
        }

        return CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: () {
              if (_isDropdownOpen) {
                _closeDropdown();
              } else {
                _openDropdown(wifiInfos);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                border: Border.all(color: ColorConstants.border, width: SizeConstants.borderWidth),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedWifi.isEmpty ? 'Wi-Fi Scanning...' : selectedWifi
                  ),
                  Icon(_isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                ],
              ),
            ),
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
      await navigateToPincodeCheckPage();
    } catch (e) {
      errorListener(e);
    } finally {
      setState(() {
        isLoading = false;
      });
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

  errorListener(error) async {
    String bleErrorText = e.toString().toLowerCase();
    if (bleErrorText.contains('disconnect')) {
      messageController.add('기기와 연결이 끊어졌어요.\n뒤로 가서 다시 메뉴를 눌러 기기를 연결해 주세요.');
    } else if (bleErrorText.contains('fbp-code: 6')) {
      messageController.add('BLE 연결이 끊어졌어요. BLE를 먼저 활성화 해주세요.');
    } else {
      messageController.add('에러가 발생했어요. $error');
    }
  }

  bool checkPassword() {
    if (password.isEmpty) {
      messageController.add('*Wi-Fi 비밀번호를 입력해주세요.');
      return false;
    }
    return true;
  }
}

import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/pages/product_connection/4_pincode_check_page.dart';
import 'package:petcarezone/services/ble_service.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:petcarezone/services/message_service.dart';
import 'package:petcarezone/utils/webview_state_manager.dart';

import '../../constants/color_constants.dart';
import '../../constants/size_constants.dart';
import '../../services/wifi_service.dart';
import '../../utils/logger.dart';
import '../../widgets/box/box.dart';
import '../../widgets/buttons/basic_button.dart';
import '../../widgets/indicator/indicator.dart';
import '../../widgets/page/basic_page.dart';

class WifiConnectionPage extends StatefulWidget {
  const WifiConnectionPage({super.key, required this.isFromWebView});
  final bool isFromWebView;

  @override
  State<WifiConnectionPage> createState() => _WifiConnectionPageState();
}

class _WifiConnectionPageState extends State<WifiConnectionPage> {
  final WifiService wifiService = WifiService();
  final BleService bleService = BleService();
  final MessageService messageService = MessageService();
  final DeviceService deviceService = DeviceService();
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final TextEditingController passwordController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final WebViewStateManager webViewStateManager = WebViewStateManager();

  final Completer<void> completer = Completer<void>();
  late StreamController<String> messageController;

  Uint8List? macAddressArray;
  String? macAddressWithSeparatorString = "";

  String selectedWifi = "";
  String selectedSecurityType = "";
  String password = "";
  bool isLoading = false;
  bool isDropdownOpen = false;
  bool isFromWebView = false;

  OverlayEntry? overlayEntry;

  OverlayEntry createDropdown(List<Map<String, String>> wifiInfos) {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 40,
          height: MediaQuery.of(context).size.height * 0.4,
          child: CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(0, 65),
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
      stream: messageService.messageController.stream,
      builder: (context, snapshot) {
        String errorText = snapshot.data ?? "";
        return Text(errorText, style: TextStyle(color: ColorConstants.red),);
      },
    );
  }

  Widget widgetWifiDropdown() {
    return Builder(
      builder: (context) {
        return StreamBuilder<List<Map<String, String>>>(
          stream: wifiService.wifiStream,
          builder: (context, snapshot) {
            List<Map<String, String>> wifiInfos = snapshot.data ?? [];

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
                onTap: wifiInfos.isNotEmpty? () {
                  if (isDropdownOpen) {
                    _closeDropdown();
                  } else {
                    openDropdown(wifiInfos);
                  }
                }
                : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 21.0),
                  decoration: BoxDecoration(
                    color: ColorConstants.white,
                    borderRadius: BorderRadius.circular(SizeConstants.borderSize),
                    border: Border.all(color: ColorConstants.border, width: SizeConstants.borderWidth),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedWifi.isEmpty ? 'Wi-Fi Scanning...' : selectedWifi),
                      Icon(
                        isDropdownOpen ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                        size: 15,
                        color: ColorConstants.inputLabelColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

  void openDropdown(List<Map<String, String>> wifiInfos) {
    if (!isDropdownOpen) {
      overlayEntry = createDropdown(wifiInfos);
      Overlay.of(context)?.insert(overlayEntry!);
      setState(() {
        isDropdownOpen = true;
      });
    }
  }

  void _closeDropdown() {
    if (overlayEntry != null) {
      overlayEntry?.remove();
      overlayEntry = null;
      setState(() {
        isDropdownOpen = false;
      });
    }
  }

  Future<void> navigateToPincodeCheckPage() async {
    _closeDropdown();
    if(mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PincodeCheckPage()));
    }
  }

  Future<void> initializeBleService() async {
    try {
      if (isFromWebView) {
        await bleService.bleConnectToDeviceFromWebView();
      }
      await bleService.getCharacteristics();
    } catch (e) {
      logD.e("Error during BLE initialization: $e");
      messageService.messageController.add('first_use.register.connect_to_wifi.bluetooth_error'.tr(namedArgs: {'error': e.toString()}));
      await bleService.bleConnectToDeviceFromWebView();
    }
  }

  Future<void> connectToWifiAndDevice() async {
    if (!await checkWifiConnection()) return;
    if (!checkPassword()) return;
    if (bleService.connectedDevice == null) {
      logD.e('connectedDevice is null');
      messageService.messageController.add('first_use.register.connect_to_wifi.bluetooth_check'.tr());
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      await bleService.setRegistration();
      await bleService.sendWifiCredentialsToBLE(selectedWifi, password);
      await Future.delayed(const Duration(seconds: 3));
      if (isFromWebView && webViewStateManager.controller != null) {
        webViewStateManager.controller!.runJavaScript("updateSSID('$selectedWifi')");
        if (mounted && !completer.isCompleted) {
          completer.complete();
          return Navigator.pop(context, true);
        }
      }
      connectSdkService.startScan();
      connectSdkService.setupListener();
      connectSdkService.matchedDeviceStream.listen((devices) async {
        if (devices.isNotEmpty) {
            await connectSdkService.matchedDeviceController.close();
            await deviceService.saveAndInitializeWebOSDevice();
            await navigateToPincodeCheckPage();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        },
      );
      await completer.future;
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
    if (currentWifi != selectedWifi) {
      messageService.messageController.add('first_use.register.connect_to_wifi.wifi_different'.tr(namedArgs: {'currentWifi' : currentWifi}));
      return false;
    } else {
      messageService.messageController.add('');
    }
    return true;
  }

  void errorListener(error) {
    String bleErrorText = e.toString().toLowerCase();
    if (bleErrorText.contains('disconnect')) {
      messageService.messageController.add('first_use.register.connect_to_wifi.wifi_disconnect'.tr());
    } else if (bleErrorText.contains('fbp-code: 6')) {
      messageService.messageController.add('first_use.register.connect_to_wifi.bluetooth_disconnect'.tr());
    } else {
      messageService.messageController.add('first_use.register.connect_to_wifi.error'.tr(namedArgs: {'error' : error}));
      connectToWifiAndDevice();
    }
    print('bleErrorText $error');
  }

  bool checkPassword() {
    if (password.isEmpty) {
      messageService.messageController.add('first_use.register.connect_to_wifi.wifi_password'.tr());
      return false;
    }
    return true;
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    initializeBleService();
  }

  @override
  void initState() {
    super.initState();
    isFromWebView = widget.isFromWebView;
    wifiService.initialize();
    passwordController.clear();
  }

  @override
  void dispose() {
    _closeDropdown();
    connectSdkService.stopScan();
    wifiService.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "first_use.register.connect_to_wifi.title".tr(),
      topHeight: 50,
      contentWidget: Column(
        children: [
          Row(
            children: [
              FontConstants.inputLabelText('first_use.register.connect_to_wifi.wifi_network'.tr()),
            ],
          ),
          boxH(10),
          widgetWifiDropdown(),
          boxH(20),
          Row(
            children: [
              FontConstants.inputLabelText('first_use.register.connect_to_wifi.password'.tr()),
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
        text: "first_use.register.connect_to_wifi.connect".tr(),
        onPressed: connectToWifiAndDevice,
      ),
    );
  }
}

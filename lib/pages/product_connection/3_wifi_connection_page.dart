import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petcarezone/pages/product_connection/4_pincode_check_page.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../../constants/color_constants.dart';
import '../../constants/size_constants.dart';
import '../../services/luna_service.dart';
import '../../services/wifi_service.dart';
import '../../utils/logger.dart';
import '../../widgets/box/box.dart';
import '../../widgets/buttons/basic_button.dart';
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
  final TextEditingController passwordController = TextEditingController();
  final LayerLink layerLink = LayerLink();

  String currentWifi = "";
  String selectedWifi = "";
  String password = "";
  String errorText = "";
  String sshHost = "";

  Timer? scanTimer;

  @override
  void initState() {
    super.initState();
    wifiService.initialize();
    lunaServiceInitialize();
  }

  @override
  void dispose() {
    wifiService.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicPage(
      showAppBar: true,
      description: "Pet Care Zone에 연결할\nWi-Fi 네트워크를 아래 화면에서\n선택해주세요.",
      topHeight: 70,
      contentWidget: Column(
        children: [
          widgetWifiDropdown(),
          boxH(20),
          widgetPasswordField(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(errorText, style: TextStyle(color: ColorConstants.red)),
              ],
            ),
          ),
          boxH(16),
        ],
      ),
      bottomButton: BasicButton(
        text: "연결하기",
        onPressed: _connectToWifi,
      ),
    );
  }

  Widget widgetWifiDropdown() {
    return StreamBuilder<List<Map<String, String>>>(
      stream: wifiService.wifiStream,
      builder: (context, snapshot) {
        List<Map<String, String>> wifiInfos = snapshot.data ?? [];

        if (wifiInfos.isNotEmpty) {
          final firstSsid = wifiInfos[0]['SSID'] ?? "";

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
        labelText: "비밀번호",
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '*Wi-Fi 비밀번호를 입력해 주세요.';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          password = value;
        });
      },
    );
  }

  Future<void> _connectToWifi() async {
    await getCurrentSSID();
    if (currentWifi != selectedWifi) {
      setState(() {
        errorText = '*연결할 Wi-Fi가 달라요.\n현재 Wi-Fi: $currentWifi';
      });
    }

    if (password.isEmpty) {
      setState(() {
        errorText = "*Wi-Fi 비밀번호를 입력해주세요.";
      });
    }

    if (currentWifi == selectedWifi) {
      if (password.isNotEmpty) {
        await lunaServiceWifiConnect();
      }
    }
  }

  Future lunaServiceInitialize() async {
    await getDeviceIp();
    await lunaServiceWifiStatus();
    await lunaServiceScanWifi();
  }

  Future getCurrentSSID() async {
     return currentWifi = (await WiFiForIoTPlugin.getSSID())!;
  }

  /// 1. Search Device IP from Device list
  Future<String?> getDeviceIp() async {
    return sshHost = (await deviceService.getDeviceIp())!;
  }

  /// 2. Check Wi-Fi Status
  Future<bool> lunaServiceWifiStatus() async {
    final wifiStatus = await lunaService.checkWifiStatus(sshHost);
    final networkInfo = wifiStatus['networkInfo'];
    logD.i('networkInfo : $networkInfo');
    if (networkInfo != null || networkInfo.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<bool> lunaServiceScanWifi() async {
     final scanResult = await lunaService.scanWifi(sshHost);
     logD.i('scanResult : $scanResult');
     if (scanResult != null || scanResult.isNotEmpty) {
       scanTimer?.cancel();
       return true;
     } else {
       scanTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
         await lunaService.scanWifi(sshHost);
       });
     }
     return false;
  }

  Future lunaServiceWifiConnect() async {
    final result = await lunaService.connectWifi(sshHost, selectedWifi, password);
    final resultValue = await result['returnValue'];
    final errorResult = await result['errorCode'];

    wifiService.dispose();

    /// Success case
    if (resultValue) {
      if (await lunaServiceWifiStatus()) {
        setState(() {
          errorText = "";
        });
        navigateToPincodeCheckPage();
      }
    }

    if (!resultValue) {
      /// Success case
      print('101 ${errorResult == 101}');
      print('165 ${errorResult == 165}');
      if (errorResult == 101 || errorResult == 165){
        if (await lunaServiceWifiStatus()) {
          /// navigate
          setState(() {
            errorText = "";
          });
          navigateToPincodeCheckPage();
        }
      }
      // if (errorResult == 102) {
      //
      // }
      print('179 ${errorResult == 179}');

      if (errorResult == 179) {
        setState(() {
          errorText = '*비밀번호를 확인해주세요.';
        });
      }
    }
  }

  Future<void> navigateToPincodeCheckPage() async {
    scanTimer?.cancel();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PincodeCheckPage()));
  }
}

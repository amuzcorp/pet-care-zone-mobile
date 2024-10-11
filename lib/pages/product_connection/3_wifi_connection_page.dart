import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/constants/font_constants.dart';
import 'package:petcarezone/pages/product_connection/4_pincode_check_page.dart';
import 'package:petcarezone/services/connect_sdk_service.dart';
import 'package:petcarezone/services/device_service.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../../constants/color_constants.dart';
import '../../constants/size_constants.dart';
import '../../services/luna_service.dart';
import '../../services/wifi_service.dart';
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
  final ConnectSdkService connectSdkService = ConnectSdkService();
  final TextEditingController passwordController = TextEditingController();
  final LayerLink layerLink = LayerLink();

  StreamController<String> messageController = StreamController<String>();

  Uint8List? macAddressArray;
  String? macAddressWithSeparatorString = "";

  String currentWifi = "";
  String selectedWifi = "";
  String selectedSecurityType = "";
  String password = "";
  String errorText = "";
  String sshHost = "";
  bool isLoading = false;
  BluetoothDevice connectedDevice = FlutterBluePlus.connectedDevices.first;
  BluetoothCharacteristic? targetCharacteristic;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getCharacteristics();
  }

  @override
  void initState() {
    super.initState();
    wifiService.initialize();
    passwordController.clear();
    print('connectedDevice $connectedDevice');
  }

  @override
  void dispose() {
    wifiService.dispose();
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StreamBuilder<String>(
                  stream: messageController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!, style: TextStyle(color: ColorConstants.red));
                    }
                    return Container();
                  },
                ),
                // Text(errorText, style: TextStyle(color: ColorConstants.red)),
              ],
            ),
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
                print('selectedWifi $selectedWifi');
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

  Future getCharacteristics() async {
    if (connectedDevice != null) {
      await Future.delayed(const Duration(seconds: 2)); // 서비스 검색 전 대기

      List<BluetoothService> services = await connectedDevice.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          /// 쓰기 가능한 characteristic을 찾는다
          if (characteristic.properties.write) {
            targetCharacteristic = characteristic;
            print("구독 가능한 characteristic 발견: ${characteristic.uuid}");
          }
        }
      }

      if (targetCharacteristic == null) {
        print("쓰기 가능한 characteristic을 찾지 못했습니다.");
      }
    } else {
      print("연결된 기기가 없습니다.");
    }
  }

  Future<void> connectToWifi() async {
    await getCurrentSSID();

    if (!mounted) return;

    if (currentWifi != selectedWifi) {
      messageController.add('*연결할 Wi-Fi가 다릅니다.\n현재 Wi-Fi: $currentWifi');
      return;
    }

    if (password.isEmpty) {
      messageController.add('*Wi-Fi 비밀번호를 입력해주세요.');
      return;
    }

    if (connectedDevice != null) {
      await setRegistration();
      await sendWifiCredentialsToBLE(selectedWifi, password);
      navigateToPincodeCheckPage();
    } else {
      messageController.add('* BLE 연결을 확인해주세요.');
    }
  }

  Future<void> setRegistration() async {
    await generateRandomMacAddressWithSeparator();
    Uint8List dataArray = Uint8List.fromList(macAddressArray ?? Uint8List(0)); // Null일 경우 빈 배열로 대체

    Uint8List result = Uint8List(dataArray.length + 1); // Create a new array with extra space for 0x00
    result[0] = 0x00; // Add 0x00 : setRegistration id
    result.setRange(1, result.length, dataArray); // Copy the original result into the new array

    print("result with 0x00 at the front: ${result}");
    print("result in Hex: [${result.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}]");

    // Here you can send 'result' to your BLE characteristic
    await targetCharacteristic!.write(result);
  }

  Future<void> sendWifiCredentialsToBLE(String ssid, String password) async {
    if (targetCharacteristic != null) {
      try {
        /// 연결된 BLE 기기에 SSID + PW 전송
        String securityType = "PSK";
        String isHidden = "FALSE";

        String dataToSend = '$ssid\u0000\u0000$password\u0000\u0000$securityType\u0000\u0000$isHidden';
        await writeCharacteristic(dataToSend);
      } catch (e) {
        messageController.add('* BLE 기기와 통신 오류 발생');
      }
    } else {
      messageController.add('* 지원 불가 BLE입니다.');
    }
  }

  String makeKey(String key, Uint8List uuid) {
    print("UUID length: ${uuid.length}");
    int keyValue = 0;
    if ((uuid[1] & 0x01) == 0x01) {
      keyValue = 1;
    }

    int uuidIndex = 0;

    // char 단위로 XOR 연산 수행
    for (int i = 0; i < key.length; i++) {
      if (i % 2 == keyValue) {
        // 현재 문자와 uuid의 문자를 XOR
        key = key.replaceRange(i, i + 1,
            String.fromCharCode(key.codeUnitAt(i) ^ uuid[++uuidIndex % uuid.length])); // XOR 연산 후 문자로 변환
      }
    }

    return key;
  }


  Future<void> writeCharacteristic(String value) async {
    macAddressWithSeparatorString = macAddressArray
        ?.map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');

    final String uuidString = targetCharacteristic!.uuid.toString();
    final Uint8List uuidArray = Uint8List(2);
    uuidArray[0] = int.parse(uuidString.substring(0, 2), radix: 16);
    uuidArray[1] = int.parse(uuidString.substring(2, 4), radix: 16);

    String key = "";
    key = makeKey(macAddressWithSeparatorString?? "", uuidArray);

    print("key: $key");
    String hexKey = key.split('').map((char) {
      int codeUnit = char.codeUnitAt(0);
      return codeUnit.toRadixString(16).padLeft(2, '0');
    }).join(', ').toUpperCase(); // 문자열로 조합

    print("Key in Hex: [$hexKey]");

    print("dataToSend: ${value}");

    Uint8List encryptedBytes = encryptXOR(value, value.length, key);

    // Adding 0x0A(action id for Wifi Sync Info) byte at the front of result
    Int8List finalResult = Int8List(encryptedBytes.length + 1); // Create a new array with extra space for 0x0A
    finalResult[0] = 0x0A; // Add 0x0A at the front
    finalResult.setRange(1, finalResult.length, encryptedBytes); // Copy the original result into the new array

    print("Final result with 0x0A at the front: ${finalResult}");
    print("Final result in Hex: ${finalResult.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}");

    await targetCharacteristic!.write(finalResult);
  }

  Uint8List encryptXOR(String original, int originalLength, String key) {
    if (original.isEmpty || key.isEmpty || originalLength <= 0) {
      return Uint8List(0);
    }

    List<int> result = List<int>.filled(originalLength, 0);

    for (int i = 0; i < originalLength; i++) {
      result[i] = original.codeUnitAt(i) ^ key.codeUnitAt(i % key.length); // XOR 연산
    }

    return Uint8List.fromList(result);
  }

  Future generateRandomMacAddressWithSeparator() async {
    final rand = Random();
    List<int> macAddressBytes = [];

    for (int i = 0; i < 6; i++) {
      int value = rand.nextInt(256); // 0-255 random value
      macAddressBytes.add(value);    // Add byte value
    }
    print('macAddressArray $macAddressBytes');
    macAddressArray = Uint8List.fromList(macAddressBytes);
  }



  void handleReceivedData(String data) {
    print('data $data');
    // 수신된 데이터를 처리하는 로직 (Wi-Fi 연결 결과 등)
    if (data.contains("success")) {
      print("Wi-Fi 연결 성공!");
      // 성공 시 처리
    } else if (data.contains("fail")) {
      print("Wi-Fi 연결 실패.");
      // 실패 시 처리
    } else {
      print("알 수 없는 데이터: $data");
    }
  }

  Future getCurrentSSID() async {
    return currentWifi = (await WiFiForIoTPlugin.getSSID())!;
  }

  Future<void> navigateToPincodeCheckPage() async {
    wifiService.scanTimer?.cancel();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PincodeCheckPage()));
  }
}

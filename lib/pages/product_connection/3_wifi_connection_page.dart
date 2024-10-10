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

  Uint8List? macAddressWithSeparatorArray;
  Uint8List? macAddressArray;

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

  // Future<void> setRegistration() async {
  //   String macAddressString = targetCharacteristic!.remoteId.toString();
  //   Uint8List macAddressArray = stringToMacAddressArray(macAddressString);
  //   Int8List result = Int8List(macAddressArray.length + 1);
  //   result[0] = 0x00;
  //   result.setRange(1, result.length, macAddressArray);
  //
  //   print("result with 0x00 at the front: ${result}");
  //   print("result in Hex: ${result.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}");
  //
  //   await targetCharacteristic!.write(result);
  // }

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

  void makeKey(Uint8List key, int macLength, Uint8List uuid) {
    print("UUID length: ${uuid.length}");
    int keyValue = 0;
    if ((uuid[1] & 0x01) == 0x01) {
      keyValue = 1;
    }

    int uuidIndex = 0;

    for (int i = 0; i < macLength; i++) {
      if (i % 2 == keyValue) {
        key[i] = key[i] ^ uuid[(++uuidIndex) % 2];
      }
    }
  }

  Future<void> writeCharacteristic(String value) async {
    final String uuidString = targetCharacteristic!.uuid.toString();
    final Uint8List uuidArray = Uint8List(2);
    uuidArray[0] = int.parse(uuidString.substring(0, 2), radix: 16);
    uuidArray[1] = int.parse(uuidString.substring(2, 4), radix: 16);

    Uint8List keyArray = Uint8List.fromList(macAddressWithSeparatorArray ?? Uint8List(0)); // Null일 경우 빈 배열로 대체
    int macLength = keyArray.length;

    print("Key before makeKey: ${keyArray}");
    print("Key before makeKey in Hex: [${keyArray.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}]");
    print("Length of keyArray: ${keyArray.length}");

    // Print the UUID
    print("UUID: ${uuidArray}");

    makeKey(keyArray, macLength, uuidArray); // Call makeKey with the string key

    print("Key after makeKey: $keyArray");
    print("Key after makeKey in Hex: ${keyArray.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}");

    Uint8List original = stringToMacAddressArray(value); // Use global macAddressString

    print("original: ${original}");
    print("original in Hex: ${keyArray.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}");

    Int8List result = Int8List(original.length);

    encryptXOR(result, original, original.length, keyArray);

    // Adding 0x0A(action id for Wifi Sync Info) byte at the front of result
    Int8List finalResult = Int8List(result.length + 1); // Create a new array with extra space for 0x0A
    finalResult[0] = 0x0A; // Add 0x0A at the front
    finalResult.setRange(1, finalResult.length, result); // Copy the original result into the new array

    print("Final result with 0x0A at the front: ${finalResult}");
    print("Final result in Hex: ${finalResult.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}");

    // Here you can send 'result' to your BLE characteristic
    await targetCharacteristic!.write(result);
  }

  // Future writeCharacteristic(String value) async {
  //   final String uuidString = targetCharacteristic!.uuid.toString();
  //   final Uint8List uuidArray = Uint8List(2);
  //   uuidArray[0] = int.parse(uuidString.substring(0, 2), radix: 16);
  //   uuidArray[1] = int.parse(uuidString.substring(2, 4), radix: 16);
  //
  //   final String macAddress = targetCharacteristic!.remoteId.toString();
  //   final macAddressArray = stringToMacAddressArray(macAddress);
  //
  //
  //   /// MAC Address 길이
  //   final int macLength = macAddress.length;
  //
  //   print('key $macLength');
  //   print('Key before makeKey: $macAddressArray');
  //   print("Key before makeKey in Hex: ${macAddressArray.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}");
  //   print("Length of macAddressArray: ${macAddressArray.length}");
  //
  //   makeKey(macAddressArray, macLength, uuidArray);
  //
  //   print("Key after makeKey: $macAddressArray"); // Display the key string before modification
  //   print("Key after makeKey in Hex: ${macAddressArray.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}");
  //
  //   Uint8List original = stringToMacAddressArray(value);
  //
  //   // List<int> result = Uint8List(original.length);
  //   Int8List result = Int8List(original.length);
  //   encryptXOR(result, original, original.length, macAddressArray);
  //
  //   Int8List finalResult = Int8List(result.length + 1);
  //   finalResult[0] = 0x0A;
  //   finalResult.setRange(1, finalResult.length, result);
  //   print("result: ${result}");
  //   print("Final result with 0x0A at the front: ${finalResult}");
  //   print("Final result in Hex: ${finalResult.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(', ')}");
  //
  //
  //   await targetCharacteristic!.write(finalResult);
  // }

  Uint8List stringToMacAddressArray(String input) {
    List<int> byteList = input.codeUnits;

    return Uint8List.fromList(byteList);
  }

  int encryptXOR(Int8List result, Uint8List original, int originalLength, Uint8List key) {
    if (original.isEmpty || key.isEmpty || originalLength <= 0) {
      return -1;
    }

    for (int i = 0; i < originalLength; i++) {
      result[i] = original[i] ^ key[i % key.length];
    }

    return 1;
  }

  Future generateRandomMacAddressWithSeparator() async {
    final rand = Random();
    List<int> macAddressBytes = [];
    List<int> macAddressWithSeparatorArrayBytes = [];

    for (int i = 0; i < 6; i++) {
      int value = rand.nextInt(256); // 0-255 random value
      macAddressBytes.add(value);    // Add byte value
      macAddressWithSeparatorArrayBytes.add(value);    // Add byte value
      if (i < 5) {
        macAddressWithSeparatorArrayBytes.add(0x3A);   // Add hex value for ':' (0x3A)
      }
    }
    macAddressArray = Uint8List.fromList(macAddressBytes);
    macAddressWithSeparatorArray = Uint8List.fromList(macAddressWithSeparatorArrayBytes);
    print('macAddressArray $macAddressArray');
    print('macAddressWithSeparatorArray $macAddressWithSeparatorArray');
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

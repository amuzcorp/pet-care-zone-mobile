import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/pages/product_connection/4_pincode_check_page.dart';
import 'package:petcarezone/services/ble_service.dart';
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

  String currentWifi = "";
  String selectedWifi = "";
  String password = "";
  String errorText = "";
  String sshHost = "";
  BluetoothDevice connectedDevice = FlutterBluePlus.connectedDevices.first;
  BluetoothCharacteristic? targetCharacteristic;

  @override
  void initState() {
    super.initState();
    print('connectedDevice $connectedDevice');
  }

  @override
  void dispose() {
    wifiService.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    wifiService.initialize();
    getCharacteristics();
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
        onPressed: connectToWifi,
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

  Future getCharacteristics() async {
    // 연결이 되어있다면 디바이스를 먼저 disconnect 후 reconnect
    if (connectedDevice != null) {
      await Future.delayed(const Duration(seconds: 2)); // 서비스 검색 전 대기

      List<BluetoothService> services = await connectedDevice.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print('characteristic.uuid : ${characteristic.uuid} / properties : ${characteristic.properties}');

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

  // void checkCCCD(BluetoothCharacteristic characteristic) async {
  //   for (BluetoothDescriptor descriptor in characteristic.descriptors) {
  //     print('Descriptor UUID: ${descriptor.uuid}');
  //     if (descriptor.uuid.toString() == '2902') {
  //       print('CCCD found!');
  //     }
  //   }
  // }

  Future<void> connectToWifi() async {
    await getCurrentSSID(); // 현재 Wi-Fi 확인
    print('현재 Wi-Fi: $currentWifi');

    // 선택한 Wi-Fi와 현재 연결된 Wi-Fi가 다른 경우 오류 처리
    if (currentWifi != selectedWifi) {
      setState(() {
        errorText = '*연결할 Wi-Fi가 다릅니다.\n현재 Wi-Fi: $currentWifi';
      });
      return;
    }

    // 비밀번호가 입력되지 않은 경우 오류 처리
    if (password.isEmpty) {
      setState(() {
        errorText = "*Wi-Fi 비밀번호를 입력해주세요.";
      });
      return;
    }

    setState(() {
      errorText = "";
    });

    // BLE 연결 상태 확인 후 데이터 전송
    if (connectedDevice != null) {
      print('!!!$selectedWifi $password');
      // 1. BLE 연결
      await sendWifiCredentialsToBLE(selectedWifi, password);
      // 2. PIN 코드 페이지로 이동
      navigateToPincodeCheckPage();
    } else {
      setState(() {
        errorText = '* BLE 연결을 확인해주세요.';
      });
    }
  }

  Future<void> sendWifiCredentialsToBLE(String ssid, String password) async {
    print('connectedDevice $connectedDevice');
    print('password $password');
    if (targetCharacteristic != null) {
      print('targetCharacteristic $targetCharacteristic');
      try {
        /// 연결된 BLE 기기에 SSID + PW 전송
        SecurityType securityType = SecurityType.PSK;
        String isHidden = "FALSE";

        String dataToSend = '$ssid\u0000$password\u0000${securityType.value}\u0000$isHidden\u0000';
        print('ssid $ssid');
        print('pass $password');
        print('dataToSend $dataToSend');
        await writeCharacteristic(dataToSend);
      } catch (e) {
        setState(() {
          errorText = '* BLE 기기와 통신 오류 발생';
        });
      }
    } else {
      setState(() {
        errorText = '* 지원 불가 BLE입니다.';
      });
    }
  }

  Future writeCharacteristic(String value) async {
    print('targetCharacteristic $targetCharacteristic');

    Uint8List key = Uint8List(16);
    Uint8List macAddress = Uint8List.fromList(connectedDevice!.remoteId.toString().codeUnits);
    await makeKey(key, key.length, macAddress);

    Uint8List original = Uint8List.fromList(utf8.encode(value));
    Uint8List result = Uint8List(original.length);
    encryptXOR(result, original, original.length, key);

    // Key, Original, Result 확인
    print('MAC Address: $macAddress');
    print('Generated Key: $key');
    print('Original Data: $original');
    print('Encrypted Result: $result');

    try {
      // 데이터를 Uint8List로 변환 후 특성에 작성
      await targetCharacteristic!.write(result);
      targetCharacteristic!.lastValueStream.listen((value) {
        print("listened Data: $value");
      });
      await Future.delayed(const Duration(seconds: 3));  // 딜레이 추가
      print("Write successful");

      // await targetCharacteristic!.setNotifyValue(true);
      // print('notify good!!?');
      // targetCharacteristic!.lastValueStream.listen((value) {
      //   print('listen value : $value');
      // });

    } catch (e) {
      print("Write failed: $e");
    }
  }

  Future makeKey(Uint8List key, int keyLength, Uint8List macAddress) async {
    int keyValue = 0;
    if ((macAddress[1] & 0x01) == 0x01) {
      keyValue = 1;
    }

    int macIndex = 0;
    for (int i = 0; i < keyLength; i++) {
      if (i % 2 == keyValue) {
        key[i] = key[i] ^ macAddress[(macIndex++) % 2];
        print("qwdwqewqe ${key[i]}");
      }
    }
  }

  int encryptXOR(Uint8List result, Uint8List original, int originalLength, Uint8List key) {
    if (original == null || key == null || originalLength <= 0) {
      return -1;
    }

    for (int i = 0; i < originalLength; i++) {
      result[i] = original[i] ^ key[i % key.length];
    }

    return 1;
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

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:petcarezone/services/message_service.dart';
import 'package:petcarezone/services/wifi_service.dart';

import 'connect_sdk_service.dart';

class BleService {
  BluetoothCharacteristic? targetCharacteristic;
  BluetoothDevice connectedDevice = FlutterBluePlus.connectedDevices.first;
  ConnectSdkService connectSdkService = ConnectSdkService();
  WifiService wifiService = WifiService();
  MessageService messageService = MessageService();

  Uint8List? macAddressArray;
  String? macAddressWithSeparatorString = "";

  Future getCharacteristics() async {
    if (connectedDevice != null) {
      await Future.delayed(const Duration(seconds: 1));
      List<BluetoothService> services = await connectedDevice.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            targetCharacteristic = characteristic;
          }
        }
      }
    } else {
      messageService.messageController.add("기기 연결이 되지 않았어요.\n뒤로 돌아가 메뉴를 한번 더 눌러주세요.");
    }
  }

  Future<void> setRegistration() async {
    await generateRandomMacAddressWithSeparator();
    Uint8List dataArray = Uint8List.fromList(macAddressArray ?? Uint8List(0));

    Uint8List result = Uint8List(dataArray.length + 1);
    result[0] = 0x00;
    result.setRange(1, result.length, dataArray);

    await targetCharacteristic!.write(result);
  }

  Future generateRandomMacAddressWithSeparator() async {
    final rand = Random();
    List<int> macAddressBytes = [];

    for (int i = 0; i < 6; i++) {
      int value = rand.nextInt(256);
      macAddressBytes.add(value);
    }
    macAddressArray = Uint8List.fromList(macAddressBytes);
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
        messageService.messageController.add('* 기기와 통신 오류 발생');
      }
    } else {
      messageService.messageController.add('* 지원 불가 BLE입니다.');
    }
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

    Uint8List encryptedBytes = encryptXOR(value, value.length, key);

    Int8List finalResult = Int8List(encryptedBytes.length + 1);
    finalResult[0] = 0x0A;
    finalResult.setRange(1, finalResult.length, encryptedBytes);

    await targetCharacteristic!.write(finalResult, withoutResponse: false);
  }

  String makeKey(String key, Uint8List uuid) {
    int keyValue = 0;
    if ((uuid[1] & 0x01) == 0x01) {
      keyValue = 1;
    }

    int uuidIndex = 0;

    for (int i = 0; i < key.length; i++) {
      if (i % 2 == keyValue) {
        key = key.replaceRange(
            i, i + 1, String.fromCharCode(key.codeUnitAt(i) ^ uuid[++uuidIndex % uuid.length])
        );
      }
    }
    return key;
  }

  Uint8List encryptXOR(String original, int originalLength, String key) {
    if (original.isEmpty || key.isEmpty || originalLength <= 0) {
      return Uint8List(0);
    }

    List<int> result = List<int>.filled(originalLength, 0);

    for (int i = 0; i < originalLength; i++) {
      result[i] = original.codeUnitAt(i) ^ key.codeUnitAt(i % key.length);
    }

    return Uint8List.fromList(result);
  }
}

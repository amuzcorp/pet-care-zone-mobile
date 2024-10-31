import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petcarezone/services/firebase_service.dart';

class PermissionCheck {
  FirebaseService firebaseService = FirebaseService();
  bool isPermissionGranted = false;

  // 필요한 권한들을 리스트로 관리
  final List<Permission> permissions = [
    Permission.mediaLibrary,
    Permission.location,
    Permission.accessMediaLocation,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.bluetoothScan,
    Permission.bluetooth,
    Permission.notification
  ];

  // 전체 권한 요청 및 상태 확인 함수
  Future<void> requestPermission() async {
    if (!isPermissionGranted) {
      // 1. 일반 권한을 체크하고 요청 (카메라, 마이크, 미디어 라이브러리)
      await permissionCheck(permissions);

      // 2. Android 버전에 따른 스토리지 권한 처리
      await checkAndRequestStoragePermission();

      // 3. 모든 권한이 허용되었는지 확인
      if (await _areAllPermissionsGranted()) {
        isPermissionGranted = true;
        firebaseService.fcmRequestPermission();
        print("모든 권한이 허용되었습니다.");
      } else {
        print("일부 권한이 허용되지 않았습니다.");
      }
    } else {
      print("권한이 이미 허용되었습니다. 다시 요청하지 않습니다.");
    }
  }

  // 여러 권한을 반복 처리하여 한꺼번에 요청하는 함수
  Future<void> permissionCheck(List<Permission> permissions) async {
    for (Permission permission in permissions) {
      if (!await permission.isGranted) {
        await permission.request();
      }
    }
  }

  // Android 버전에 따른 스토리지 권한 처리 함수
  Future<void> checkAndRequestStoragePermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final String androidVer = androidInfo.version.release;
    final int version = int.tryParse(androidVer)!;

    if (version > 10) {
      await permissionCheck([Permission.manageExternalStorage]);
    } else {
      await permissionCheck([Permission.storage]);
    }
  }

  // 모든 권한이 허용되었는지 확인하는 함수
  Future<bool> _areAllPermissionsGranted() async {
    // 일반 권한 + 스토리지 권한 모두 확인
    List<Permission> allPermissions = List.from(permissions);

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final String androidVer = androidInfo.version.release;
    final int version = int.tryParse(androidVer)!;

    if (version > 10) {
      allPermissions.add(Permission.manageExternalStorage);
    } else {
      allPermissions.add(Permission.storage);
    }

    // 모든 권한이 허용되었는지 확인
    for (Permission permission in allPermissions) {
      if (!await permission.isGranted) {
        return false;
      }
    }
    return true;
  }
}

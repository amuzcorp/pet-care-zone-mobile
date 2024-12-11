import 'package:permission_handler/permission_handler.dart';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

class PermissionCheck {
  FirebaseService firebaseService = FirebaseService();

  // 필요한 권한들을 리스트로 관리
  final List<Permission> permissions = [
    Permission.mediaLibrary,
    Permission.location,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.bluetoothScan,
    Permission.bluetooth,
    Permission.notification,
  ];

  // 전체 권한 요청 및 상태 확인 함수
  Future<void> requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final isPermitted = prefs.getBool('isPermitted') ?? false;

    if (!isPermitted) {
      await permissionCheck(permissions);

      // 허용되지 않은 권한 확인
      List<Permission> deniedPermissions = await getDeniedPermissions();
      if (deniedPermissions.isEmpty) {
        prefs.setBool('isPermitted', true);
        logD.i("모든 권한이 허용되었습니다.");
      } else {
        logD.w("다음 권한이 허용되지 않았습니다: $deniedPermissions");
      }
    } else {
      logD.i("모든 권한이 허용되었습니다.");
    }
  }

  // 여러 권한을 반복 처리하여 한꺼번에 요청하는 함수
  Future<void> permissionCheck(List<Permission> permissions) async {
    await FirebaseService.fcmRequestPermission();
    for (Permission permission in permissions) {
      if (!await permission.isGranted) {
        await permission.request();
      }
      if (await permission.isPermanentlyDenied) {
        logD.w("권한이 영구적으로 거부되었습니다. 설정 화면으로 이동합니다.");
        await openAppSettings();
      }
    }
  }
  // 허용되지 않은 권한 리스트 반환
  Future<List<Permission>> getDeniedPermissions() async {
    List<Permission> allPermissions = List.from(permissions);
    List<Permission> deniedPermissions = [];
    for (Permission permission in allPermissions) {
      if (!await permission.isGranted) {
        deniedPermissions.add(permission);
      }
    }
    return deniedPermissions;
  }
}

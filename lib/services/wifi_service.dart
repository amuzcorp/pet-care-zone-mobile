import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../utils/logger.dart';

class WifiService {
  final StreamController<List<Map<String, String>>> wifiStreamController = StreamController<List<Map<String, String>>>.broadcast();
  Stream<List<Map<String, String>>> get wifiStream => wifiStreamController.stream;
  StreamSubscription<List<WiFiAccessPoint>>? subscription;

  bool get isStreaming => subscription != null;

  Timer? scanTimer;
  bool isScan = false;

  Future<bool> checkPermissions() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    return status.isGranted;
  }

  void startWifiDiscovery() {
    scanTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (await checkPermissions()) {
        await startScan();
        await scanWifiList();
      } else {
        await Permission.location.request();
      }
    });
  }

  Future<void> startScan() async {
    final can = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (can == CanStartScan.yes) {
      await WiFiScan.instance.startScan();
    }
  }

  Future<void> scanWifiList() async {
    final can = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if (can == CanGetScannedResults.yes) {
      final accessPoints = await WiFiScan.instance.getScannedResults();

      final Map<String, String> uniqueSsidMap = {};

      for (final ap in accessPoints) {
        if (ap.ssid.isNotEmpty && ap.bssid.isNotEmpty) {
          uniqueSsidMap[ap.ssid] = ap.bssid;
        }
      }

      final List<Map<String, String>> wifiList = uniqueSsidMap.entries.map((entry) {
        return {'SSID': entry.key, 'BSSID': entry.value};
      }).toList();

      print('wifiList $wifiList');

      if (!wifiStreamController.isClosed) {
        wifiStreamController.add(wifiList);
      } else {
        print("StreamController is closed, cannot add new events.");
      }
    }
  }

  void stopListeningToScanResults() {
    subscription?.cancel();
    subscription = null;
  }

  void initialize() {
    startWifiDiscovery();
  }

  void dispose() {
    logD.i('wifi service dispose');
    print('scanTimer?.isActive ${scanTimer?.isActive}');
    if (scanTimer?.isActive ?? false) {
      scanTimer?.cancel();
      print('scanTimer cancelled');
    } else {
      print('scanTimer was already cancelled or null');
    }
    stopListeningToScanResults();
    if (!wifiStreamController.isClosed) {
      wifiStreamController.close();
    }
  }
}

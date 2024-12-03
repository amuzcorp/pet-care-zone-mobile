import 'dart:convert';

class ApiUrls {
  static const String baseUrl = 'https://pcz-api.odpplatform.com/api/v1';
  static const String loginUrl = '$baseUrl/member/login';
  static const String deviceUrl = '$baseUrl/pet/iot/device';
  static const String getPetProfile = '$baseUrl/pet/profile';
  static const String regMobileToken = '$baseUrl/member/mobile';

  /// WebView Urls
  static const String webViewUrl = 'https://amuzcorp-pet-care-zone-webview.vercel.app';
  static const String home = '/home';
  static const String aiHealthUrl = '/ai-health';

  /// history Urls
  static const String tempHistory = '/history/temperature';
  static const String weightHistory = '/history/weight';
  static const String heartHistory = '/history/heart-rate';
  static const String respHistory = '/history/respiratory-rate';
  static const String stayedTimeHistory = '/history/stayed-time';

  static const Map<String, String> historyUrls = {
    'temperature': '/history/temperature',
    'weight': '/history/weight',
    'heart': '/history/heart-rate',
    'respiratory': '/history/respiratory-rate',
    'stayedTime': '/history/stayed-time',
  };

  // static const String webViewUrl = 'http://192.168.200.75:5173';

  /// WebOS Urls
  static const String allowPincodeRequest = 'luna-send -n 1 -f luna://com.webos.service.secondscreen.gateway/unpairAll';
  static const Map resetDevice = {
    'uri': 'luna://com.webos.service.petcareservice/petcontrol',
    'payload': {"command": "initialSettingReset"}
  };
  static const String lunaProvisionUrl = 'ssap://com.webos.service.petcareservice/mqtt/executeProvisioning';
  static Map registerUserProfile = {
    'uri': 'ssap://com.webos.service.petcareservice/mqtt/setPetInfo',
    'payload': {"userId" : "", "petId" : 0}
  };

  static Map<String, String> getLunaWifiConnectUrl(String wifi, String passKey) {
    return {
      'uri': 'ssap://com.webos.service.wifi/connect',
      'payload': jsonEncode({
        'ssid': wifi,
        'wasCreatedWithJoinOther': true,
        'security': {
          'securityType': 'psk',
          'simpleSecurity': {
            'passKey': passKey
          }
        }
      })
    };
  }
}

import 'dart:convert';

class ApiUrls {
  static const String baseUrl = 'https://pcz-api.odpplatform.com/api/v1';
  static const String loginUrl = '$baseUrl/member/login';
  static const String deviceUrl = '$baseUrl/pet/iot/device';

  static const String webViewUrl = 'https://amuzcorp-pet-care-zone-webview.vercel.app/';

  // static const String lunaTest = 'ssap://com.webos.service.tvpower/power/getPowerState';
  static const String lunaTest = 'ssap://com.webos.service.appcasting/getCommand';
  static const String lunaWifiStatusUrl = 'ssap://com.webos.service.wifi/getstatus';
  static const String lunaGetProfileList = 'ssap://com.webos.service.wifi/getprofilelist';

  static const Map lunaWifiScan = {
    'uri': 'ssap://com.webos.service.wifi/findnetworks',
    'payload': {"subscribe": true}
  };

  static const String lunaProvisionUrl = 'ssap://com.webos.service.petcareservice/mqtt/executeProvisioning';
  static const String lunaProvisionUrl2 = 'luna://com.webos.service.petcareservice/mqtt/executeProvisioning';

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

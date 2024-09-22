class ApiUrls {
  static const String baseUrl = 'https://pcz-api.odpplatform.com/api/v1';
  static const String loginUrl = '$baseUrl/member/login';
  static const String deviceUrl = '$baseUrl/pet/iot/device';

  static const String webViewUrl = 'https://amuzcorp-pet-care-zone-webview.vercel.app/';

  static const String lunaWifiStatusUrl = 'luna-send -n 1 -f luna://com.webos.service.wifi/getstatus {}';
  static const String lunaWifiScan = 'luna-send -n 1 -f luna://com.webos.service.wifi/findnetworks \'{"subscribe": true}\'';

  static const String lunaProvisionUrl = 'luna-send -n 1 -f luna://com.webos.service.petcareservice/mqtt/executeProvisioning {}';

  static String getLunaWifiConnectUrl(String wifi, String passKey) {
    return 'luna-send -n 1 -f luna://com.webos.service.wifi/connect \'{"ssid": "$wifi", "wasCreatedWithJoinOther": true, "security":{"securityType":"psk", "simpleSecurity":{"passKey":"$passKey"}}}\'';
  }

  static String setPetInfo(String userId, String petId) {
    return 'luna-send -f -n 1 luna://com.webos.service.petcareservice/mqtt/setPetInfo \'{"userId" : "$userId", "petId" : "$petId"}\'';
  }
}

import 'package:webview_flutter/webview_flutter.dart';

class WebViewStateManager {
  static final WebViewStateManager _instance = WebViewStateManager._internal();
  factory WebViewStateManager() => _instance;

  WebViewStateManager._internal();
  WebViewController? controller;

  bool isWebViewActive = false;

  void setController(WebViewController webViewController) {
    controller = webViewController;
  }

  void setWebViewActive(bool isActive) {
    isWebViewActive = isActive;
  }

  Future<void> runJavaScript(String script) async {
    if (controller != null) {
      await controller!.runJavaScript(script);
    } else {
      print("WebViewController is not initialized.");
    }
  }
}

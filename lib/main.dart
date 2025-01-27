import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/api_urls.dart';
import 'package:petcarezone/pages/product_connection/9_webview_page.dart';
import 'package:petcarezone/pages/splash_screen.dart';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:petcarezone/utils/locale_manager.dart';
import 'package:petcarezone/utils/logger.dart';
import 'package:petcarezone/utils/routes_web.dart';
import 'package:petcarezone/utils/webview_state_manager.dart';
import 'package:petcarezone/utils/app_life_cycle_state_checker.dart';

import 'firebase_options.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await EasyLocalization.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FirebaseService.init();
    FirebaseService.localNotiInit();

    runApp(
      EasyLocalization(
          supportedLocales: const [
            Locale('ko'),
            Locale('en')
          ],
          saveLocale: true,
          startLocale: await LocaleManager.instance.getLocale(),
          fallbackLocale: const Locale('ko'),
          path: 'assets/translations',
          child : const PetCareZone()
      )
    );
  }, (error, stack) {
  });

}

class PetCareZone extends StatefulWidget {
  const PetCareZone({super.key});

  @override
  PetCareZoneState createState() => PetCareZoneState();
}

class PetCareZoneState extends State<PetCareZone> {
  final AppLifecycleStateChecker lifecycleObserver = AppLifecycleStateChecker();
  final WebViewStateManager stateManager = WebViewStateManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(lifecycleObserver);
    lifecycleObserver.initializeFirebaseListeners();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      navigatorKey: lifecycleObserver.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'LG_Smart_UI',
      ),
      onGenerateRoute: (RouteSettings settings) {
        logD.i("Navigating to: ${settings.name}");
        final route = routesWeb.firstWhere((route) => route.path == settings.name);
        final history = historyPeriods.firstWhere((history) => settings.name!.contains(history),
          orElse: () {
            logD.e("Not History uri: ${settings.name}");
            return '';
          },
        );
        String url = route.url.contains('http') ? '/petcarezone' : route.url;
        /// Webview에서 navigate
        if (stateManager.isWebViewActive) {
          stateManager.controller!.runJavaScript("navigateToPetCareSection('$url', '$history');");
        }
        /// App에서 navigate
        if (!stateManager.isWebViewActive) {
          return MaterialPageRoute(
            builder: (context) => WebViewPage(
              uri: Uri.parse(ApiUrls.webViewUrl),
              fcmUri: Uri.parse(url),
              historyPeriod: history,
            ),
          );
        }
      },
      home: const SplashScreen(),
    );
  }
}

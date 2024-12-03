import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/constants/api_urls.dart';
import 'package:petcarezone/pages/product_connection/0_login_page.dart';
import 'package:petcarezone/pages/product_connection/9_webview_page.dart';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:petcarezone/utils/logger.dart';
import 'package:petcarezone/utils/routes_web.dart';
import 'package:petcarezone/widgets/app_life_cycle_state_checker.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //FCM 푸시 알림 관련 초기화
  FirebaseService.init();
  FirebaseService.localNotiInit();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final AppLifecycleStateChecker lifecycleObserver = AppLifecycleStateChecker();
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  final UserService userService = UserService();
  late Future<Widget> _initialPage;

  @override
  void initState() {
    super.initState();
    _initialPage = userService.initializeApp();
    WidgetsBinding.instance.addObserver(lifecycleObserver);
    lifecycleObserver.initializeFirebaseListeners();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: lifecycleObserver.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'LG_Smart_UI',
      ),
      onGenerateRoute: (RouteSettings settings) {
        logD.i("Navigating to: ${settings.name}");

        final route = routesWeb.firstWhere((route) => route.path == settings.name,
          orElse: () {
            logD.e("Route not found for: ${settings.name}");
            return RoutesWeb('/main', ApiUrls.webViewUrl);
          },
        );

        final history = historyPeriods.firstWhere((history) => settings.name!.contains(history),
          orElse: () {
            logD.e("History period not found for: ${settings.name}");
            return '';
          },
        );

        return MaterialPageRoute(
          builder: (context) => WebViewPage(
            uri: Uri.parse(ApiUrls.webViewUrl),
            fcmUri: Uri.parse(route.url),
            historyPeriod: history,
          ),
        );
      },

      home: FutureBuilder<Widget>(
        future: _initialPage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Error initializing app')),
            );
          } else {
            return snapshot.data ?? const LoginPage();
          }
        },
      ),
    );
  }
}

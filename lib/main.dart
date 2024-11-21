import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/pages/product_connection/0_login_page.dart';
import 'package:petcarezone/pages/product_connection/9_webview_page.dart';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:petcarezone/utils/permissionCheck.dart';
import 'package:petcarezone/widgets/app_life_cycle_state_checker.dart';

import 'constants/api_urls.dart';
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
  final UserService userService = UserService();
  final PermissionCheck permissionCheck = PermissionCheck();
  late Future<Widget> _initialPage;

  @override
  void initState() {
    super.initState();
    _initialPage = userService.initializeApp();
    permissionCheck.requestPermission();
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
        routes: {'/petHome': (context) => WebViewPage(uri: Uri.parse(ApiUrls.webViewUrl))},
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

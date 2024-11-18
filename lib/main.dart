import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:petcarezone/pages/product_connection/0_login_page.dart';
import 'package:petcarezone/pages/product_connection/9_webview_page.dart';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:petcarezone/utils/logger.dart';
import 'package:petcarezone/utils/permissionCheck.dart';

import 'constants/api_urls.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    print("Notification Received! $message");
    String payloadData = jsonEncode(message.data);
    FirebaseService.showSimpleNotification(
        title: message.notification!.title!,
        body: message.notification!.body!,
        payload: payloadData);
  }
}

//푸시 알림 메시지와 상호작용을 정의합니다.
Future<void> setupInteractedMessage() async {
  //앱이 종료된 상태에서 열릴 때 getInitialMessage 호출
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    _handleMessage(initialMessage);
  }
  //앱이 백그라운드 상태일 때, 푸시 알림을 탭할 때 RemoteMessage 처리
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
}

//FCM에서 전송한 data를 처리합니다. /petHome 페이지로 이동하면서 해당 데이터를 화면에 보여줍니다.
Future _handleMessage(RemoteMessage message) async {
  await Future.delayed(const Duration(seconds: 1), () {
    navigatorKey.currentState!.pushNamed("/petHome", arguments: message);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //FCM 푸시 알림 관련 초기화
  FirebaseService.init();
  //flutter_local_notifications 패키지 관련 초기화
  FirebaseService.localNotiInit();
  //백그라운드 알림 수신 리스너
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  //포그라운드 알림 수신 리스너
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    String payloadData = jsonEncode(message.data);
    logD.i('Got a message in foreground\n$payloadData');
    if (message.notification != null) {
      //flutter_local_notifications 패키지 사용
      FirebaseService.showSimpleNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
          payload: payloadData,
      );
    }
  });
  //메시지 상호작용 함수 호출
  setupInteractedMessage();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final UserService userService = UserService();
  final PermissionCheck permissionCheck = PermissionCheck();
  late Future<Widget> _initialPage;

  @override
  void initState() {
    super.initState();
    _initialPage = userService.initializeApp();
    permissionCheck.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'LG_Smart_UI',
        ),
        routes: {
          '/petHome': (context) =>
              WebViewPage(uri: Uri.parse(ApiUrls.webViewUrl))
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
        ));
  }
}

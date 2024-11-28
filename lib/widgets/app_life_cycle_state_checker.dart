import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:petcarezone/utils/logger.dart';

final FirebaseService firebaseService = FirebaseService();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logD.i("Background Notification Received! $message");
  String payloadData = jsonEncode(message?.data);
  await firebaseService.showSimpleNotification(
    title: message.notification?.title,
    body: message.notification?.body,
    imageUrl: message.notification?.android?.imageUrl,
    payload: payloadData,
  );
}

class AppLifecycleStateChecker with WidgetsBindingObserver {
  static final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final AppLifecycleStateChecker instance = AppLifecycleStateChecker._internal();
  factory AppLifecycleStateChecker() => instance;
  AppLifecycleStateChecker._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<RemoteMessage>? firebaseSubscription;

  void initializeFirebaseListeners() {
    startFirebaseSubscription();
    setupInteractedMessage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  void startFirebaseSubscription() {
    firebaseSubscription ??= FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        logD.i('Got a message in foreground\n'
            'body:${message.notification?.body}\n'
            'payload:${jsonEncode(message.data)}\n'
            'imageUrl: ${message.notification!.android!.imageUrl}'
        );
        await firebaseService.showSimpleNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          imageUrl: message.notification?.android?.imageUrl,
          payload: jsonEncode(message?.data),
        );
      });
  }

  Future<void> setupInteractedMessage() async {
    //앱이 종료된 상태에서 열릴 때 getInitialMessage 호출
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    logD.w('initialMessage $initialMessage');
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }

  Future handleMessage(RemoteMessage message) async {
    final deepLink = message.data['deep_link'];
    print('handleMessagedeepLink $deepLink');
    navigatorKey.currentState?.pushNamed('/$deepLink');
  }
}

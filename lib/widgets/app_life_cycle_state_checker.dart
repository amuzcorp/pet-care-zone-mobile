import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:petcarezone/services/firebase_service.dart';
import 'package:petcarezone/utils/logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logD.i("Background Notification Received! $message");
  String payloadData = jsonEncode(message.data);
  await FirebaseService.showSimpleNotification(
    title: message.notification!.title,
    body: message.notification!.body,
    payload: payloadData,
  );
}

class AppLifecycleStateChecker with WidgetsBindingObserver {
  static final AppLifecycleStateChecker _instance = AppLifecycleStateChecker._internal();
  factory AppLifecycleStateChecker() => _instance;
  AppLifecycleStateChecker._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<RemoteMessage>? firebaseSubscription;

  void initializeFirebaseListeners() {
    _startFirebaseSubscription();
    setupInteractedMessage();
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  void _startFirebaseSubscription() {
    firebaseSubscription ??= FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logD.i('Got a message in foreground: ${jsonEncode(message.data)}');
        FirebaseService.showSimpleNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          payload: jsonEncode(message.data),
        );
      });
  }

  Future<void> setupInteractedMessage() async {
    //앱이 종료된 상태에서 열릴 때 getInitialMessage 호출
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    //앱이 백그라운드 상태일 때, 푸시 알림을 탭할 때 RemoteMessage 처리
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future _handleMessage(RemoteMessage message) async {
    await Future.delayed(const Duration(seconds: 1), () {
      navigatorKey.currentState!.pushNamed("/petHome", arguments: message);
    });
  }
}

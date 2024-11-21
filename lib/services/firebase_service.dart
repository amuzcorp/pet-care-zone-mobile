import 'dart:convert';

import 'package:android_id/android_id.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:petcarezone/widgets/app_life_cycle_state_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

class FirebaseService {
  final UserService userService = UserService();
  static final firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const androidIdPlugin = AndroidId();

  static Future init() async {
    await firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  //flutter_local_notifications 패키지 관련 초기화
  static Future localNotiInit() async {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(onDidReceiveLocalNotification: (id, title, body, payload) {},);
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  static Future<bool> isAppInForeground() async {
    final WidgetsBinding widgetsBinding = WidgetsBinding.instance;
    return widgetsBinding?.lifecycleState == AppLifecycleState.resumed;
  }

  Future setFcmToken() async {
    final String? fcmToken = await firebaseMessaging.getToken();
    final String? androidId = await androidIdPlugin.getId();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('fcm_info', [androidId!, fcmToken!]);
    logD.i("fcm_info: ${prefs.getStringList('fcm_info')}");
    return await userService.regMobileToken(androidId, 1, fcmToken);
  }

  static Future fcmRequestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('알림 권한이 허용되었습니다.');
    } else {
      print('알림 권한이 거부되었습니다.');
    }

    return await FirebaseMessaging.instance.requestPermission(
      badge: true,
      alert: true,
      sound: true,
    );
  }

  //포그라운드로 알림을 받아서 알림을 탭했을 때 페이지 이동
  static void onNotificationTap(NotificationResponse notificationResponse) {
    AppLifecycleStateChecker().navigatorKey.currentState!.pushNamed('/petHome', arguments: notificationResponse,);
  }

  //포그라운드에서 푸시 알림을 전송받기 위한 패키지 푸시 알림 발송
  static Future showSimpleNotification({
    String? title,
    String? body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'petcarezone_1',
      'petcarezone',
      icon: '@mipmap/ic_launcher',
      channelDescription: '',
      importance: Importance.max,
      priority: Priority.high,
      groupAlertBehavior: GroupAlertBehavior.all,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    return await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails, payload: payload);
  }
}

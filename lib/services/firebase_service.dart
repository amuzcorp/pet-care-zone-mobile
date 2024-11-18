import 'dart:convert';

import 'package:android_id/android_id.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:petcarezone/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

class FirebaseService {
  static final firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const androidIdPlugin = AndroidId();
  static String? fcmToken;

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

    fcmToken = await firebaseMessaging.getToken();
    final String? androidId = await androidIdPlugin.getId();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('fcm_info', [androidId!, fcmToken!]);
    print("fcm_info: ${prefs.getStringList('fcm_info')}");
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

  //flutter_local_notifications 패키지 관련 초기화
  static Future localNotiInit() async {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(onDidReceiveLocalNotification: (id, title, body, payload) {},);
    const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
    );
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  //포그라운드로 알림을 받아서 알림을 탭했을 때 페이지 이동
  static void onNotificationTap(NotificationResponse notificationResponse) {
    navigatorKey.currentState!.pushNamed('/petHome', arguments: notificationResponse,);
  }

  //포그라운드에서 푸시 알림을 전송받기 위한 패키지 푸시 알림 발송
  static Future showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'pomo_timer_alarm_1',
      'pomo_timer_alarm',
      icon: '@mipmap/ic_launcher',
      channelDescription: '',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    await _flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails, payload: payload);
  }

  //API를 이용한 발송 요청
  static Future<void> send({required String title, required String message}) async {
    final jsonCredentials = await rootBundle.loadString('assets/data/auth.json');
    final creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);
    final client = await auth.clientViaServiceAccount(
      creds,
      ['https://www.googleapis.com/auth/cloud-platform'],
    );

    final notificationData = {
      'message': {
        'token': fcmToken, //기기 토큰
        'data': { //payload 데이터 구성
          'petInfo': 'please give me pet data',
        },
        'notification': {
          'title': title, //푸시 알림 제목
          'body': message, //푸시 알림 내용
        }
      },
    };
    final response = await client.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/pet-care-zone-8d4e2/messages:send'),
      headers: {
        'content-type': 'application/json',
      },
      body: jsonEncode(notificationData),
    );

    client.close();
    if (response.statusCode == 200) {
      logD.i('FCM notification sent with status code: ${response.statusCode}');
    } else {
      logD.e('${response.statusCode} , ${response.reasonPhrase} , ${response.body}');
    }
  }
}

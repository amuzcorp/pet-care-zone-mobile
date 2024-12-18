import 'dart:convert';

import 'package:android_id/android_id.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:petcarezone/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import '../utils/logger.dart';
import '../widgets/app_life_cycle_state_checker.dart';

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
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(onDidReceiveLocalNotification: (id, title, body, payload) {},);
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );

    await initializeNotificationChannels();
  }

  static Future<void> initializeNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'petcarezone_channel',
      'petcarezone',
      description: 'This channel is used for petcarezone.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }


  static Future<bool> isAppInForeground() async {
    final WidgetsBinding widgetsBinding = WidgetsBinding.instance;
    return widgetsBinding?.lifecycleState == AppLifecycleState.resumed;
  }

  Future setFcmToken(String? fcmToken) async {
    final String? androidId = await androidIdPlugin.getId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fcm_info', [androidId!, fcmToken!]);
    logD.i("fcm_info: ${prefs.getStringList('fcm_info')}");
    return await userService.regMobileToken(androidId, 1, fcmToken);
  }

  void refreshFcmToken() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      setFcmToken(newToken);
      logD.i('refresh Token: $newToken');
    }).onError((err) {
      logD.e("토큰 갱신 중 오류 발생: $err");
    });
  }

  static Future fcmRequestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logD.i('FCM 알림 권한이 허용되었습니다.');
    } else {
      logD.e('FCM 알림 권한이 거부되었습니다.');
      await messaging.requestPermission();
    }

    return await FirebaseMessaging.instance.requestPermission(
      badge: true,
      alert: true,
      sound: true,
    );
  }

  //포그라운드로 알림을 받아서 알림을 탭했을 때 페이지 이동
  static void onNotificationTap(NotificationResponse notificationResponse) {
    logD.w('>>> Notification tapped - onNotificationTap called');
    logD.w('notificationResponse: ${notificationResponse?.payload}');
    final response = jsonDecode(notificationResponse.payload.toString());
    final String deepLink = response['deep_link'];
    logD.w('deepLink $deepLink');

    AppLifecycleStateChecker().navigatorKey.currentState?.pushNamed(
      '/$deepLink',
      arguments: notificationResponse,
    );
  }

  //포그라운드에서 푸시 알림을 전송받기 위한 패키지 푸시 알림 발송
  Future showSimpleNotification({
    String? title,
    String? body,
    String? imageUrl,
    required String payload
  }) async {
    Future<String> getBase64FromImage(String imageUrl) async {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
      throw Exception('Failed to load image');
    }

    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      ByteArrayAndroidBitmap.fromBase64String(await getBase64FromImage(imageUrl!)),
      largeIcon: ByteArrayAndroidBitmap.fromBase64String(await getBase64FromImage(imageUrl!)),
      contentTitle: title,
      summaryText: body,
    );

    final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'petcarezone_channel',
      'petcarezone',
      icon: '@mipmap/ic_launcher',
      largeIcon: ByteArrayAndroidBitmap.fromBase64String(await getBase64FromImage(imageUrl!)),
      channelDescription: 'This channel is used for petcarezone.',
      importance: Importance.max,
      priority: Priority.high,
      groupAlertBehavior: GroupAlertBehavior.all,
      styleInformation: bigPictureStyleInformation,
    );
    final NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    return await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails, payload: payload);
  }
}

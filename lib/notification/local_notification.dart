import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flog/screen/floging/floging_screen.dart';
import 'package:flog/screen/floging/shooting_screen_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotification {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  LocalNotification._();

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static initialize() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('mipmap/ic_launcher');

    DarwinInitializationSettings initializationSettingsIOS =
        const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,

        //onSelectNotification: 함수명 추가
        onDidReceiveNotificationResponse: (
      payload,
    ) {
      final context = LocalNotification.navigatorKey.currentContext;
      // 알림 채널 ID에 따라 다른 화면으로 이동
      if (payload == 'channel_id_1') {
        Navigator.push(context!,
            MaterialPageRoute(builder: (context) => ShootingScreen()));
      } else if (payload == 'channel_id_2') {
        Navigator.push(
            context!, MaterialPageRoute(builder: (context) => FlogingScreen()));
      }
    });
  }

  static requestPermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

// 프로그타임 알림
  static Future<void> scheduleRandomNotification(BuildContext context) async {
    tz.initializeTimeZones();

    // 현재 시간을 기준으로 랜덤한 시간을 생성
    final random = Random();
    final hours = random.nextInt(24); // 0부터 23까지의 랜덤한 시간
    final minutes = random.nextInt(60); // 0부터 59까지의 랜덤한 분

    final scheduledTime = tz.TZDateTime.now(tz.local).add(
      Duration(hours: hours, minutes: minutes),
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channel_id_1', '프로그타임알림',
            channelDescription: '프로그타임을 알리는 알림입니다.',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: false);

    // 이전에 예약된 알림이 있다면 취소
    await flutterLocalNotificationsPlugin.cancel(2);

    // 랜덤한 시간에 알림 예약
    flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      '!!FLOG TIME입니다!!',
      '가족들은 무엇을 하고 있을까요? 지금 당장 상태를 알리고 확인하세요!',
      scheduledTime,
      NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          badgeNumber: 1,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showNotification({
    required String userToken,
    required String title,
    required String message,
    required BuildContext context,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      userToken, // 특정 디바이스의 토큰을 채널 ID로 사용
      'channel name',
      channelDescription: 'channel description',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: false,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        badgeNumber: 1,
      ),
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      message,
      platformChannelSpecifics,
      payload: userToken, // 사용자 토큰을 payload로 전달
    );
    print('알림 전송');
  }

  void sendCommentNotification(String recipientToken) async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

    // 알림 페이로드를 구성합니다.
    final notification = {
      'body': '누군가 댓글을 남겼습니다.',
      'title': '댓글 알림',
    };

    final message = {
      'notification': notification,
      'token': recipientToken, // 받는 사용자의 FCM 토큰
    };

    try {
      await _firebaseMessaging.sendMessage();
      print('댓글 알림이 성공적으로 보내졌습니다.');
    } catch (e) {
      print('댓글 알림을 보내는 중 오류가 발생했습니다: $e');
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    tz.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();

    // 이미 예약된 알림이 있는지 확인
    final hasScheduledNotification =
        prefs.getBool('hasScheduledNotification') ?? false;

    if (!hasScheduledNotification) {
      print('예약된 알림이 없습니다.');
      final random = Random();
      final currentDateTime = tz.TZDateTime.now(tz.local);

      // 오늘 랜덤한 시간과 내일 랜덤한 시간 사이에만 알림 예약
      final todayEnd = tz.TZDateTime(
        tz.local,
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        23,
        59,
      );

      final randomDateTime = currentDateTime.add(
        Duration(
          minutes: random.nextInt(todayEnd.minute + 1),
        ),
      );

      // 예약된 알림 시간을 변수에 저장
      final scheduledTime = randomDateTime;

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('channel_id_1', '프로그타임알림',
              channelDescription: '프로그타임을 알리는 알림입니다.',
              importance: Importance.max,
              priority: Priority.max,
              showWhen: false);

      // 이전에 예약된 알림이 있다면 취소
      FlutterLocalNotificationsPlugin().cancel(2);

      // 랜덤한 시간에 알림 예약
      FlutterLocalNotificationsPlugin().zonedSchedule(
        2,
        '!!FLOG TIME입니다!!',
        '가족들은 무엇을 하고 있을까요? 지금 당장 상태를 알리고 확인하세요!',
        randomDateTime,
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
      print('알림이 예약되었습니다.');
      print('예약된 알림 시간: $scheduledTime');
      // 예약된 알림이 있음을 표시
      await prefs.setBool('hasScheduledNotification', true);
    }
    print(prefs.getBool('hasScheduledNotification'));
    return Future.value(true);

    print('예약된 알림있음');
  });
}

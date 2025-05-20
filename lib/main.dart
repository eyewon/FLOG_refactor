import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flog/notification/fcm_controller.dart';
import 'package:flog/providers/user_provider.dart';
import 'package:flog/screen/floging/floging_screen.dart';
import 'package:flog/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:flog/screen/register/sms_login_home.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
//import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'models/model_auth.dart';
import 'screen/register/login_screen.dart';
import 'screen/register/register_screen.dart';
//import 'package:flog/notification/scheduling.dart';

// 백그라운드 설정 코드는 맨 최상단에 위치해야함
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //print('Handling a background message ${message.messageId}');
}

void initializeNotification() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
          'high_importance_channel', 'high_importance_notification',
          importance: Importance.max));
  await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings("@mipmap/ic_launcher"),
  ));
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Firebase 초기화 코드
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  fcmSetting();
  initializeNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          //프로바이더 추가 가능
          ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flog',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(),
            '/login': (context) => SplashScreen(),
            '/register': (context) => const RegisterScreen(),
            '/index': (context) => const FlogingScreen(),
          },
        ));
  }
}

Future<void> fcmSetting() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true);

  var initialzationSettingsIOS = const DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  var initializationSettingsAndroid =
      const AndroidInitializationSettings('@mipmap/launcher_icon');

  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initialzationSettingsIOS);
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.getActiveNotifications();

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (message.notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification?.title,
        notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            icon: '@mipmap/launcher_icon',
          ),
        ),
      );
    }
  });

  // 토큰 발급
  var fcmToken = await FirebaseMessaging.instance.getToken();

  // 토큰 리프레시 수신
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    // save token to server
  });
}

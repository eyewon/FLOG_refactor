// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flog/notification/local_notification.dart';
import 'package:flog/screen/register/login_screen.dart';
import 'package:flog/screen/register/matching_screen.dart';
import 'package:flog/screen/register/start_screen.dart';
import 'package:flog/screen/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:flog/models/model_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var MessageString = "";

  void getMyDevicdeToken() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = await FirebaseMessaging.instance.getToken();
    print("내 디바이스 토큰: $token");
    FirebaseMessaging.instance.requestPermission(
      badge: true,
      alert: true,
      sound: true,
    );
    final CollectionReference userRef = _firestore.collection('User');
    await userRef.doc(prefs.getString('email')).update({'token': token});
  }

  Future<bool> checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authClient =
        Provider.of<FirebaseAuthProvider>(context, listen: false);
    bool isLogin = prefs.getBool('isLogin') ?? false;
    print("[*] 로그인 상태 : " + isLogin.toString());
    if (isLogin) {
      String? email = prefs.getString('email');
      String? password = prefs.getString('password');
      print("[*] 저장된 정보로 로그인 재시도");
      await authClient.loginWithEmail(email!, password!).then((loginStatus) {
        if (loginStatus == AuthStatus.loginSuccess) {
          print("[*] 로그인 성공");
        } else {
          print("[*] 로그인 실패");
          isLogin = false;
          prefs.setBool('isLogin', false);
        }
      });
    }
    return isLogin;
  }

  void moveScreen() async {
    await checkLogin().then((isLogin) async {
      if (isLogin) {
        // 유저의 flogCode 가져오기
        final CollectionReference usersCollection =
            FirebaseFirestore.instance.collection('User');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        DocumentSnapshot userDocument =
            await usersCollection.doc(prefs.getString('email')).get();

        if (userDocument.exists) {
          String flogCode = userDocument.get('flogCode');
          String group_no = "";
          final CollectionReference groupRef =
              FirebaseFirestore.instance.collection('Group');

          try {
            // 'flogCode'와 일치하는 그룹을 조회합니다.
            QuerySnapshot groupSnapshot =
                await groupRef.where('flogCode', isEqualTo: flogCode).get();

            // 조회된 그룹이 있는 경우
            if (groupSnapshot.docs.isNotEmpty) {
              // 첫 번째로 조회된 그룹의 'group_no'를 반환합니다.
              group_no = groupSnapshot.docs.first.get('group_no').toString();
            } else {
              // 일치하는 그룹이 없는 경우
              print('일치하는 그룹이 없습니다.');
              return null;
            }
          } catch (e) {
            // 에러 처리
            print('그룹 조회 중 오류 발생: $e');
            return null;
          }
          if (flogCode == "null") {
            //flogCode가 없는경우(가족 등록 안된 신규 유저)
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text('${prefs.getString('email')}님 환영합니다!')));
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FamilyMatchingScreen(
                        nickname: prefs.getString('email')!)));
          } else {
            // flogCode가 있는경우(가족 등록된 기존 유저)
            FirebaseMessaging.instance.subscribeToTopic(group_no);
            print("$group_no 알림구독됨");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text('${prefs.getString('email')!}님 환영합니다!')));
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        RootScreen(matchedFamilycode: flogCode)));
          }
        }
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => StartScreen()));
      }
    });
  }

  @override
  void initState() {
    getMyDevicdeToken();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        FlutterLocalNotificationsPlugin().show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
                android: AndroidNotificationDetails(
                    'high_importance_channel', 'high_importance_notification',
                    importance: Importance.max)));
        setState(() {
          MessageString = message.notification!.body!;
          print("Foreground 메시지 수신: $MessageString");
        });
      }
    });
    Future.delayed(
        const Duration(seconds: 3), LocalNotification.requestPermission());
    super.initState();
    Timer(Duration(microseconds: 1500), () {
      moveScreen();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/splash.png'),
              fit: BoxFit.cover, // 이미지를 화면에 꽉 채우도록 설정
            ),
          ),
        ),
      ),
    );
  }
}

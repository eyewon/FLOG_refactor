//import 'package:flog/notification/fcm_controller.dart';
//import 'package:flog/notification/local_notification.dart';
//import 'package:flog/notification/postNotifications.dart';
//import 'package:flog/screen/register/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/model_auth.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authClient = Provider.of<FirebaseAuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black, // 뒤로가기 버튼 아이콘 색상
          ), // 이미지 경로 지정
          onPressed: () {
            Navigator.pop(context); // 뒤로가기 기능 추가
          },
        ),
        title: const Text(
          'Setting',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold, // 굵게 설정
          ),
        ),
        backgroundColor: Colors.transparent, // 투명 설정
        elevation: 0, // 그림자 제거
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '일반 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language), // 아이콘 예시
              title: const Text('언어 설정'),
              trailing: const Icon(Icons.arrow_forward_ios), // 화살표 아이콘 예시
              onTap: () { // 언어 설정 화면으로 이동하는 코드를 여기에 추가
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications), // 아이콘 예시
              title: const Text('알림 설정'),
              trailing: const Icon(Icons.arrow_forward_ios), // 화살표 아이콘 예시
              onTap: () {
                // print('알림설정');
                // LocalNotification.showNotification(
                //     userToken:
                //         "dP_i9sr7QwarKSt_gImO_j:APA91bFs7ZWa_KJ3NXIwH-q3CgX7oajJk3T05bW3FdTvIojGvPK3pjp0ZHt60vg3MnUGusZaie8OvJ6I6QqR-9o2YqaGVG966H6d9WNwMTzGq5g5Q4taO03niDzO47csiGGiIsYFJQNc",
                //     context: context,
                //     title: '!!FLOG TIME입니다!!',
                //     message: '가족들은 무엇을 하고 있을까요? 지금 당장 상태를 알리고 확인하세요!');
                // 알림 설정 화면으로 이동하는 코드를 여기에 추가
              },
            ),
            const Divider(), // 분리선 추가
            const Text(
              '계정 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.security), // 아이콘 예시
              title: const Text('보안 설정'),
              trailing: const Icon(Icons.arrow_forward_ios), // 화살표 아이콘 예시
              onTap: () { // 보안 설정 화면으로 이동하는 코드를 여기에 추가
              },
            ),
            ListTile(
                leading: const Icon(Icons.logout), // 아이콘 예시
                title: const Text('로그아웃'),
                trailing: const Icon(Icons.arrow_forward_ios), // 화살표 아이콘 예시
                onTap: () async {
                  await authClient.logout();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('로그아웃되었습니다')));
                  Navigator.of(context).pushNamed('/login');
                }),
          ],
        ),
      ),
    );
  }
}

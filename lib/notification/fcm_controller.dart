import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

final pushFcmUrl =
    'https://us-central1-flog-e708e.cloudfunctions.net/pushFcm'; // Firebase Functions 엔드포인트 변경

Future<void> pushUpdate(String flogCode) async {
  // 업데이트 시 flogCode를 전달
  try {
    final http.Response response = await http.post(
      Uri.parse('$pushFcmUrl/update'), // "/update" 엔드포인트 호출
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8', // 요청 헤더 변경
      },
      body: jsonEncode({'flogCode': flogCode}), // 요청 데이터에 flogCode 추가
    );

    if (response.statusCode == 200) {
      print('Push notification sent successfully.');
    } else {
      print(
          'Failed to send push notification. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending push notification: $e');
    throw Exception("pushFAQ: $e");
  }
}

Future<void> pushAnswer(String sendingUid, String receivingUid) async {
  // sendingUid와 receivingUid를 전달
  try {
    final http.Response response = await http.post(
      Uri.parse('$pushFcmUrl/updateAnswer'), // "/updateAnswer" 엔드포인트 호출
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8', // 요청 헤더 변경
      },
      body: jsonEncode({
        'sendingUid': sendingUid,
        'receivingUid': receivingUid
      }), // 요청 데이터에 sendingUid와 receivingUid 추가
    );

    if (response.statusCode == 200) {
      print('Push notification sent successfully.');
    } else {
      print(
          'Failed to send push notification. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending push notification: $e');
    throw Exception("pushFAQ: $e");
  }
}

void sendNotification(String token, String title, String body) async {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'key=AAAAT-_37n8:APA91bG1SGAS3DipkjSH4C3pFveprmKolT4xC8LKR8Lk7w7ghcMdOZMzVSVCqCjcF847-x3aYHV4YDLZaIzXTOE7cvRssSG9lIJwE9IVqYJZi34MkHkMR9LYYAXmC5hI3r3hMzzo2dyU'
  };
  var request =
      http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
  request.body = json.encode({
    "to": token,
    "notification": {"title": title, "body": body},
    "data": {"KEY": "VALUE"}
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
  }
}

void groupNotification_floging(
    String group_no, String title, String body) async {
  FirebaseMessaging.instance.unsubscribeFromTopic(group_no);
  print("$group_no 알림구독취소");
  var headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'key=AAAAT-_37n8:APA91bG1SGAS3DipkjSH4C3pFveprmKolT4xC8LKR8Lk7w7ghcMdOZMzVSVCqCjcF847-x3aYHV4YDLZaIzXTOE7cvRssSG9lIJwE9IVqYJZi34MkHkMR9LYYAXmC5hI3r3hMzzo2dyU'
  };
  var request =
      http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
  request.body = json.encode({
    "to": "/topics/$group_no",
    "notification": {"title": title, "body": body},
    "data": {"KEY": "VALUE"}
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
  }
}

void groupNotification(String group_no, String title, String body) async {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'key=AAAAT-_37n8:APA91bG1SGAS3DipkjSH4C3pFveprmKolT4xC8LKR8Lk7w7ghcMdOZMzVSVCqCjcF847-x3aYHV4YDLZaIzXTOE7cvRssSG9lIJwE9IVqYJZi34MkHkMR9LYYAXmC5hI3r3hMzzo2dyU'
  };
  var request =
      http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
  request.body = json.encode({
    "to": "/topics/$group_no",
    "notification": {"title": title, "body": body},
    "data": {"KEY": "VALUE"}
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
  }
}

Future<void> callCloudFunction(String functionEndpoint) async {
  try {
    // Cloud Function에 POST 요청 보내기
    final response = await http.post(Uri.parse(functionEndpoint));

    // HTTP 응답 코드 확인
    if (response.statusCode == 200) {
      print('Cloud Function 호출 성공');
    } else {
      print('Cloud Function 호출 실패. 응답 코드: ${response.statusCode}');
    }
  } catch (error) {
    print('Cloud Function 호출 중 오류 발생: $error');
  }
}

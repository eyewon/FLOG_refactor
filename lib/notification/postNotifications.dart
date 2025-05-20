import 'dart:async';
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;

class PostCall {
  final postUrl = 'https://fcm.googleapis.com/fcm/send';

  final data = {
    "notification": {"body": "this is a body", "title": "this is a title"},
    "priority": "high",
    "data": {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done"
    },
    "to":
        "dP_i9sr7QwarKSt_gImO_j:APA91bFs7ZWa_KJ3NXIwH-q3CgX7oajJk3T05bW3FdTvIojGvPK3pjp0ZHt60vg3MnUGusZaie8OvJ6I6QqR-9o2YqaGVG966H6d9WNwMTzGq5g5Q4taO03niDzO47csiGGiIsYFJQNc"
  };

  Future<bool> makeCall() async {
    final headers = {
      'content-type': 'application/json',
      'Authorization': 'key=<FCM SERVER KEY>'
    };

    final response = await http.post(Uri.parse(postUrl),
        body: json.encode(data),
        encoding: Encoding.getByName('utf-8'),
        headers: headers);

    if (response.statusCode == 200) {
      // on success do sth
      return true;
    } else {
      // on failure do sth
      return false;
    }
  }
}

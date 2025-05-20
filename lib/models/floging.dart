// flog 모델 클래스 정의 : 데이터베이스의 flogs 컬렉션에서 가져온 데이터를 표현하고 조작하기 위한 목적
import 'package:cloud_firestore/cloud_firestore.dart';

// 1️⃣ 업로드된 floging
class Floging {
  final String flogingId; // 식별을 위한 해당 플로깅의 ID
  final DateTime date;
  final String uid;
  final String flogCode;
  final String downloadUrl_front;
  final String downloadUrl_back;
  final String caption;

  Floging(
      {required this.flogingId,
      required this.date,
      required this.uid,
      required this.flogCode,
      required this.downloadUrl_front,
      required this.downloadUrl_back,
      required this.caption
      });

  static Floging fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Floging(
      flogingId: snapshot["flogingId"],
      uid: snapshot["uid"],
      date: snapshot["date"],
      flogCode: snapshot["flogCode"],
      downloadUrl_front: snapshot["downloadUrl_front"],
      downloadUrl_back: snapshot["downloadUrl_back"],
      caption: snapshot["caption"]
    );
  }

  Map<String, dynamic> toJson() => {
        "flogingId": flogingId,
        "uid": uid,
        "date": date,
        "flogCode": flogCode,
        "downloadUrl_front": downloadUrl_front,
        "downloadUrl_back": downloadUrl_back,
        "caption": caption
      };
}

// 2️⃣ 해당 floging 아래 달린 댓글
class Comment {
  final String uid;
  final String content;
  final DateTime date;

  Comment({
    required this.uid,
    required this.content,
    required this.date,
  });

  static Comment fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Comment(
      uid: snapshot["uid"],
      content: snapshot["content"],
      date: snapshot["date"],
    );
  }

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "date": date,
        "content": content,
      };
}

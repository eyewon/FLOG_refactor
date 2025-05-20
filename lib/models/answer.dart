// Answer 모델 클래스 정의
import 'package:cloud_firestore/cloud_firestore.dart';

// Answer 모델
class Answer {
  final String answerId; // 식별을 위한 해당 답변의 ID
  final String flogCode;
  final int puzzleNo;
  final int questionNo;
  final Map answers;

  Answer(
      {required this.answerId,
        required this.flogCode,
        required this.puzzleNo,
        required this.questionNo,
        required this.answers
      });

  static Answer fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Answer(
      answerId: snapshot["answerId"],
      flogCode: snapshot["flogCode"],
      puzzleNo: snapshot["puzzleNo"],
      questionNo: snapshot["questionNo"],
      answers: snapshot["answers"]
    );
  }

  Map<String, dynamic> toJson() => {
    "answerId": answerId,
    "flogCode": flogCode,
    "puzzleNo": puzzleNo,
    "questionNo": questionNo,
    "answers": answers
  };
}

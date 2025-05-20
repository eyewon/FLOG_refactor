// Answer 모델 클래스 정의
import 'package:cloud_firestore/cloud_firestore.dart';

// Answer 모델
class Question {
  final int puzzleNo;
  final int questionNo;
  final String questionContent;

  Question(
      {
        required this.puzzleNo,
        required this.questionNo,
        required this.questionContent
      });

  static Question fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Question(
        puzzleNo: snapshot["puzzleNo"],
        questionNo: snapshot["questionNo"],
        questionContent: snapshot["questionContent"]
    );
  }

  Map<String, dynamic> toJson() => {
    "puzzleNo": puzzleNo,
    "questionNo": questionNo,
    "questionContent": questionContent
  };
}

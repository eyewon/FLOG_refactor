import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flog/models/qpuzzle.dart';
import 'package:flog/widgets/checkTodayFlog.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flog/resources/storage_methods.dart';
import '../models/answer.dart';
import '../models/floging.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Floging 데이터베이스에 저장하기

  Future<String> uploadFloging(
      Uint8List file, Uint8List file2, String uid, String flogCode, String caption) async {
    String res = "Some error occurred";
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage('Floging', file, true);
      String photoUrl2 =
          await StorageMethods().uploadImageToStorage('Floging', file2, true);String flogingId = const Uuid().v1(); // creates unique id based on time

      Floging floging = Floging(
          uid: uid,
          date: DateTime.now(),
          downloadUrl_front: photoUrl,
          downloadUrl_back: photoUrl2,
          flogCode: flogCode,
          flogingId: flogingId,
          caption: caption
      );
      _firestore.collection('Floging').doc(flogingId).set(floging.toJson());
      res = "success";
      checkTodayFlog();
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Floging 댓글 저장하기

  Future<String> postComment(String flogingId, String text, String uid) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        _firestore
            .collection('Floging')
            .doc(flogingId)
            .collection('Comment')
            .doc(commentId)
            .set({
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'date': DateTime.now(),
          'flogingId': flogingId,
        });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Flogig 데이터베이스에서 삭제하기

  Future<String> deleteFloging(String flogingId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('posts').doc(flogingId).delete();
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Q-puzzle 데이터베이스에 저장하기

  Future<String> uploadQpuzzle(
      Uint8List file, String flogCode, int puzzleNo, String uid) async {
    String res = "Some error occurred";
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage('Qpuzzle', file, true);
      String puzzleId = const Uuid().v1(); // creates unique id based on time
      Qpuzzle qpuzzle = Qpuzzle(
          puzzleId: puzzleId,
          date: DateTime.now(),
          flogCode: flogCode,
          puzzleNo: puzzleNo,
          isComplete: false,
          pictureUrl: photoUrl,
          qpuzzleUploader: uid,
          qpuzzleTitle: ""
      );

      _firestore.collection('Qpuzzle').doc(puzzleId).set(qpuzzle.toJson());
      final CollectionReference groupRef = _firestore.collection('Group');
      await groupRef.doc(flogCode).update({'qpuzzleUrl': photoUrl});
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Answer 데이터베이스에 저장하기

  Future<String> uploadAnswer(String flogCode, int puzzleNo, int questionNo) async {
    String res = "Some error occurred";
    Map<String, String> answersMap = {};
    try {
      String answerId = const Uuid().v1(); // creates unique id based on time
      Answer answer = Answer(
        answerId: answerId,
        flogCode: flogCode,
        puzzleNo: puzzleNo,
        questionNo: questionNo,
        answers: answersMap);

      _firestore.collection('Answer').doc(answerId).set(answer.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}

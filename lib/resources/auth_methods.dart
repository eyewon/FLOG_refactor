import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flog/models/user.dart' as model;

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // get user details
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('User').doc(currentUser.email).get();

    return model.User.fromSnap(documentSnapshot);
  }

  // 유저 정보 수정하기
  void updateUser(email, field, data) async {
    User currentUser = _auth.currentUser!;
    _firestore.collection("User").doc(email).update({field: data});
  }
}

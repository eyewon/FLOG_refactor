// 인증 관련 기능 처리를 위한 모델 - 파이어베이스와의 통신 등 인증 관련 회원 정보 전반을 다룸

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flog/models/user.dart' as model;

// 인증 관련 상태 표현 - 회원가입 성공/실패, 로그인 성공/실패
enum AuthStatus {
  registerSuccess,
  registerFail,
  loginSuccess,
  loginFail,
}

// Firebase 인증을 관리하기 위한 Provider
class FirebaseAuthProvider with ChangeNotifier {
  FirebaseAuth
      authClient; // Firebase와 연결된 인스턴스를 저장할 변수 - 앱 전역에 똑같은 authClient 유지, 제공
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user; // 로그인 결과 - 현재 로그인된 유저 객체를 저장할 변수

  FirebaseAuthProvider({auth}) : authClient = auth ?? FirebaseAuth.instance;

  Future<AuthStatus> registerWithEmail(
      String email, String password, String nickname, String birth) async {
    try {
      if (email.isNotEmpty ||
          password.isNotEmpty ||
          nickname.isNotEmpty ||
          birth.isNotEmpty) {
        UserCredential credential =
            await authClient.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        model.User user = model.User(
            uid: credential.user!.uid,
            email: email,
            birth: birth,
            nickname: nickname,
            flogCode: "null",
            profile: "0",
            isAnswered: false,
            isUpload: false,
            isQuestionSheetShowed: false,
            ongoing: false,
            token: '');

        // 데이터베이스에 저장
        await _firestore
            .collection("User")
            .doc(credential.user!.email)
            .set(user.toJson());

        return AuthStatus.registerSuccess;
      } else {
        return AuthStatus.registerFail;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        return AuthStatus.registerFail;
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        return AuthStatus.registerFail;
      }
    } catch (e) {
      print(e);
      return AuthStatus.registerFail;
    }
    return AuthStatus.registerFail;
  }

  Future<AuthStatus> loginWithEmail(String email, String password) async {
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        await authClient
            .signInWithEmailAndPassword(email: email, password: password)
            .then((credential) async {
          user = credential.user;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool('isLogin', true);
          prefs.setString('email', email);
          prefs.setString('password', password);
        });
        print("[+] 로그인 유저 : ${user!.email}");

        return AuthStatus.loginSuccess;
      } else {
        return AuthStatus.loginFail;
      }
    } catch (e) {
      print(e);
      return AuthStatus.loginFail;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLogin', false);
    prefs.setString('email', '');
    prefs.setString('password', '');
    user = null;
    await authClient.signOut();
    print("[-] 로그아웃");
  }

  // 그룹에 유저 등록하기
  Future<void> registerGroup(String flogCode, String uid) async {
    final CollectionReference groupRef =
        FirebaseFirestore.instance.collection('Group');
    DocumentSnapshot docSnapshot = await groupRef.doc(flogCode).get();

    // 현재 그룹 컬렉션의 스냅샷을 가져옵니다.
    QuerySnapshot groupSnapshot = await groupRef.get();

    if (docSnapshot.exists) {
      // 그룹이 존재하는 경우 -> 그룹에 추가하기
      print("[*] 기존 그룹에 추가합니다");
      List<dynamic> currentMembers = docSnapshot.get('members');
      currentMembers.add(uid);
      await groupRef.doc(flogCode).update(
          {'members': currentMembers, 'memNumber': currentMembers.length});
    } else {
      // 그룹이 존재하지 않는 경유 -> 그룹 생성하기
      print("[*] 새로운 그룹을 만듭니다");

      int newGroupNumber = groupSnapshot.size + 1;
      model.Group group = model.Group(
          flogCode: flogCode,
          members: [uid],
          frog: 0,
          memNumber: 1,
          qpuzzleUrl: "",
          unlock: [false, false, false, false, false, false],
          selectedIndex: -1,
          isAnyFamilyMemberOngoing: false,
          isAnyFamilyMemberShowedQsheet: false,
          group_no: newGroupNumber.toString(),
          memoryBookNo: 0,
          isMaking: false,
      );
      await _firestore.collection("Group").doc(flogCode).set(group.toJson());
      FirebaseMessaging.instance.subscribeToTopic(newGroupNumber.toString());
      print("$newGroupNumber 알림구독됨");
    }
  }
}

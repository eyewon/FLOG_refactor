// user 모델 클래스 정의 : 데이터베이스의 users 컬렉션에서 가져온 데이터를 표현하고 조작하기 위한 목적
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  final String uid;
  final String email;
  final String nickname;
  final String birth;
  final String profile;
  final String flogCode; // 소속된 가족 코드
  final bool isUpload; // 플로깅 업로드 여부 확인
  final bool isAnswered;
  final bool isQuestionSheetShowed; // 큐퍼즐 답변 여부 확인
  final bool ongoing;
  final String token; //디바이스토큰

  User({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.birth,
    required this.profile,
    required this.flogCode,
    this.isUpload = false, //기본값은 false, 업로드하면 true로 값 변경
    required this.isAnswered,
    required this.isQuestionSheetShowed,
    required this.ongoing,
    required this.token,
  });

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
        nickname: snapshot["nickname"],
        uid: snapshot["uid"],
        email: snapshot["email"],
        profile: snapshot["profile"],
        birth: snapshot["birth"],
        flogCode: snapshot["flogCode"],
        isUpload: snapshot["isUpload"],
        isAnswered: snapshot["isAnswered"],
        isQuestionSheetShowed: snapshot["isQuestionSheetShowed"],
        ongoing: snapshot["ongoing"],
        token: snapshot["token"]);
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'nickname': nickname,
        'birth': birth,
        'profile': profile,
        'flogCode': flogCode,
        'isUpload': isUpload,
        'isAnswered': isAnswered,
        'isQuestionSheetShowed': isQuestionSheetShowed,
        'ongoing': ongoing,
        'token': token,
      };
}

class Group {
  final String flogCode; // 그룹 식별 아이디
  final List<String> members; // 그룹에 해당하는 user 들 리스트화
  final int frog; // 모은 개구리 수
  late final int memNumber; //그룹 멤버수
  final String qpuzzleUrl; // 현재 진행중인 큐퍼즐사진
  final List<bool> unlock; // 현재 진행중인 큐퍼즐의 잠금해제여부
  final int selectedIndex;
  final bool isAnyFamilyMemberOngoing;
  final bool isAnyFamilyMemberShowedQsheet;
  final String group_no; //그룹번호
  final int memoryBookNo;
  final bool isMaking;

  Group({
    required this.flogCode,
      required this.members,
      required this.frog,
      required this.memNumber,
      required this.qpuzzleUrl,
      required this.unlock,
      required this.selectedIndex,
      required this.isAnyFamilyMemberOngoing,
      required this.isAnyFamilyMemberShowedQsheet,
      required this.group_no,
      required this.memoryBookNo,
      required this.isMaking
      });

  // *floging 기능 로직 : 자신의 상태를 업로드해야 다른 구성원 상태 확인 가능
  bool canViewPhotos(String userId) {
    final user =
        members.firstWhere((user) => user == userId); //해당 userId에 해당하는 사용자를 찾기
    return true; //해당 사용자의 isUpload 상태를 확인. 만약 해당 사용자가 이미 업로드한 상태라면 true를 반환
  }

  static Group fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Group(
        flogCode: snapshot["flogCode"],
        members: snapshot["members"],
        frog: snapshot["frog"],
        memNumber: snapshot["memNumber"],
        qpuzzleUrl: snapshot["qpuzzleUrl"],
        unlock: snapshot["unlock"],
        selectedIndex: snapshot["selectedIndex"],
        isAnyFamilyMemberOngoing: snapshot["isAnyFamilyMemberOngoing"],
        isAnyFamilyMemberShowedQsheet: snapshot["isAnyFamilyMemberShowedQsheet"],
        group_no: snapshot["group_no"],
        memoryBookNo: snapshot["memoryBookNo"],
        isMaking: snapshot["isMaking"]
    );
  }

  Map<String, dynamic> toJson() => {
        'flogCode': flogCode,
        'members': members,
        'frog': frog,
        'memNumber': memNumber,
        'qpuzzleUrl': qpuzzleUrl,
        'unlock': unlock,
        'selectedIndex': selectedIndex,
        'isAnyFamilyMemberOngoing': isAnyFamilyMemberOngoing,
        'isAnyFamilyMemberShowedQsheet': isAnyFamilyMemberShowedQsheet,
        'group_no': group_no,
        'memoryBookNo' : memoryBookNo,
        'isMaking' : isMaking
      };
}

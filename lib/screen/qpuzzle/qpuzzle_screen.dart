import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flog/notification/fcm_controller.dart';
import 'package:flog/resources/firestore_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class QpuzzleScreen extends StatefulWidget {
  const QpuzzleScreen({Key? key}) : super(key: key);

  @override
  State<QpuzzleScreen> createState() => _QpuzzleScreenState();
}

class _QpuzzleScreenState extends State<QpuzzleScreen> {
  String appbarText = 'Qpuzzle';
  XFile? image; //불러온 이미지 저장할 변수
  List<bool> unlockStates = []; //6개의 조각에 대한 잠금 상태를 나타내는 리스트
  late int selectedCellIndex; //선택된 셀의 인덱스 : 초기값은 -1
  int tempCellIndex = -1;
  late bool ongoing; //진행중(=나는 답변 완료했으나 가족 모두 답변 완료하지는 x) -> 답변 완료 후 나는 답변하는 화면이 아닌 가족들의 답변 여부 볼 수 있어야 하므로 필요
  int puzzleno = 0;
  late bool isQuestionSheetShowed; //질문창을 이미 조회했는지(조각을 선택했는지)
  late bool isAnswered; //답변 했는지
  late bool isAnyFamilyMemberOngoing;
  late bool isAnyFamilyMemberShowedQsheet;
  String qpuzzleUploader = "";
  int familyMem = 1; //가족 수
  String myanswer = ''; //내 답변 저장할 변수
  String qpuzzleTitle = "";
  TextEditingController answerController = TextEditingController();
  TextEditingController qpuzzleTitleController = TextEditingController();
  bool isSendButtonEnabled = false;
  String groupNo = "";

  // Firestore 인스턴스 생성
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  String currentUserFlogCode = ""; // 현재 로그인한 사용자의 flogCode

  @override
  void initState() {
    super.initState();
    getUserFlogCode();
    getQsheetShowed();
    getOngoing();
    getisAnswered();
    answerController.addListener(_onAnswerTextChanged);
  }

  void _onAnswerTextChanged() {
    setState(() {
      isSendButtonEnabled = answerController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    answerController.dispose();
    qpuzzleTitleController.dispose();
    super.dispose();
  }

  //현재 로그인한 사용자의 flogCode를 Firebase에서 가져오는 함수
  Future<void> getUserFlogCode() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(currentUser.email)
        .get();
    if (userDoc.exists) {
      setState(() {
        currentUserFlogCode = userDoc.data()!['flogCode'];
      });
    }
  }

  //isQuestionSheetShowed 불리언 값을 Firebase에서 가져오는 함수
  Future<void> getQsheetShowed() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(currentUser.email)
        .get();
    if (userDoc.exists) {
      setState(() {
        isQuestionSheetShowed = userDoc.data()!['isQuestionSheetShowed'];
      });
    }
  }

  Future<void> getisAnswered() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(currentUser.email)
        .get();
    if (userDoc.exists) {
      setState(() {
        isAnswered = userDoc.data()!['isAnswered'];
      });
    }
  }

  //ongoing 불리언 값을 Firebase에서 가져오는 함수
  Future<void> getOngoing() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(currentUser.email)
        .get();
    if (userDoc.exists) {
      setState(() {
        ongoing = userDoc.data()!['ongoing'];
      });
    }
  }

  //Qpuzzle 사진 파이어베이스에 업로드
  void postImage(String flogCode, int puzzleNo, String uid) async {
    try {
      Uint8List img = await image?.readAsBytes() as Uint8List;
      await FireStoreMethods().uploadQpuzzle(img, flogCode, puzzleNo, uid);
    } catch (err) {
      //print(err);
    }
  }

  //Answer 문서 파이어베이스에 생성
  void postAnswer(String flogCode, int puzzleNo, int questionNo) async {
    try {
      await FireStoreMethods().uploadAnswer(flogCode, puzzleNo, questionNo);
    } catch (err) {
      //print(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Group')
            .where('flogCode', isEqualTo: currentUserFlogCode)
            .snapshots(),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.hasError) {
            return Text('Error: ${groupSnapshot.error}');
          }
          if (groupSnapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center( //로딩바 구현 부분
                child: SpinKitPumpingHeart(
                  color: Colors.green.withOpacity(0.2),
                  size: 50.0, //크기 설정
                  duration: const Duration(seconds: 3),
                ),
              ),
              backgroundColor: Colors.transparent,
            );
          }
          final groupDocuments = groupSnapshot.data!.docs;
          groupNo = groupDocuments[0]['group_no'];

          //qpuzzleUrl 가져오는 함수
          String? qpuzzleUrl = groupDocuments.isNotEmpty
              ? groupDocuments[0]['qpuzzleUrl'] // qpuzzleUrl 필드가 있는지 확인
              : null;
          if (qpuzzleUrl == "") qpuzzleUrl = null;

          //qpuzzle 들어왔을 때
          if (groupDocuments.isNotEmpty) {
            final unlockList = groupDocuments[0]['unlock'] as List<dynamic>; //unlockList의 각 요소를 bool로 변환하여 unlockStates에 추가
            unlockStates.clear(); //기존 데이터 지우기
            unlockStates.addAll(unlockList.map((dynamic value) => value as bool));
            selectedCellIndex = groupDocuments[0]['selectedIndex']; //selectedIndex 파이어베이스에서 가져오기
            //isAnyFamilyMemberOngoing = groupDocuments[0]['isAnyFamilyMemberOngoing'];
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Qpuzzle').snapshots(),
            builder: (context, puzzleSnapshot) {
              if (puzzleSnapshot.hasError) {
                return Text('Error: ${puzzleSnapshot.error}');
              }
              if (puzzleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final latestPuzzleDocument = puzzleSnapshot.data!.docs; //마지막 큐퍼즐
              final latestDocument = latestPuzzleDocument.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['flogCode'] == currentUserFlogCode;
              }).toList();

              if (latestDocument.isNotEmpty) {
                latestDocument.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  return bData['puzzleNo'].compareTo(aData['puzzleNo']);
                });

                final data = latestDocument[0].data() as Map<String, dynamic>;
                puzzleno = data['puzzleNo']; //우리 가족의 마지막 큐퍼즐의 번호 가져오기
                if (qpuzzleUrl != null) appbarText = 'Qpuzzle #$puzzleno';
                qpuzzleTitle = data['qpuzzleTitle'];
                if (qpuzzleUrl == null) qpuzzleTitle = "";
                qpuzzleUploader = data['qpuzzleUploader'];
              } else {
                // 'flogCode'가 같은 문서가 없을 경우 기본값 1로 설정
                puzzleno = 0;
                if (qpuzzleUrl != null) appbarText = 'Qpuzzle #$puzzleno';
                if (qpuzzleUrl == null) qpuzzleTitle = "";
              }

              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  elevation: 0.0,
                  centerTitle: true,
                  title: Text(
                    appbarText,
                    style: GoogleFonts.balooBhaijaan2(
                      textStyle: const TextStyle(
                        fontSize: 30,
                        color: Color(0xFF62BC1B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                body: SafeArea(
                  child: Center(
                      child: ListView(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20),
                                  StreamBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                      stream: (qpuzzleUploader.isNotEmpty)
                                          ? FirebaseFirestore.instance
                                          .collection("User")
                                          .doc(qpuzzleUploader)
                                          .snapshots()
                                          : null,
                                      builder: (context, snapshot) {
                                        if (qpuzzleUploader.isEmpty) { // qpuzzleUploader가 빈 문자열인 경우
                                          return Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey[200],
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.help_outline, // 물음표 아이콘
                                                size: 30, // 아이콘의 크기 조정
                                                color: Colors.black, // 아이콘의 색상 설정
                                              ),
                                            ),
                                          );
                                        }

                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Center(
                                            //로딩바 구현 부분
                                            child: SpinKitPumpingHeart(
                                              color: Colors.green.withOpacity(0.2),
                                              size: 50.0, //크기 설정
                                              duration: const Duration(seconds: 5),
                                            ),
                                          );
                                        } else if (snapshot.hasError) {
                                          return Text('Error: ${snapshot.error}');
                                        } else {
                                          if (snapshot.data == null || !snapshot.data!.exists) {
                                            return const Text('데이터 없음 또는 문서가 없음'); // Firestore 문서가 없는 경우 또는 데이터가 null인 경우 처리
                                          }
                                        }
                                        Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              "assets/profile/profile_${userData['profile']}.png",
                                              width: 30,
                                              height: 30,
                                            ),
                                          ],
                                        );
                                      }),
                                  const SizedBox(width: 5),
                                  Text(
                                    ': $qpuzzleTitle',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.start,
                                    softWrap: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              if (qpuzzleUrl != null) //qpuzzleUrl이 있을 때 !! 이미지를 표시
                                Stack(
                                  children: [
                                    Container(
                                      width: 340,
                                      height: 510,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(23),
                                        image: DecorationImage(
                                          image: NetworkImage(qpuzzleUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 340,
                                      height: 510,
                                      child: Column(
                                        children: [
                                          for (int row = 0; row < 3; row++) //3행
                                            Row(
                                              children: [
                                                for (int col = 0; col < 2; col++) //2열
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final userSnapshot = await FirebaseFirestore.instance
                                                          .collection('User')
                                                          .doc(
                                                          currentUser.email)
                                                          .get();
                                                      answerController.clear();

                                                      ongoing = userSnapshot['ongoing'] as bool;

                                                      isQuestionSheetShowed = userSnapshot['isQuestionSheetShowed'] as bool;
                                                      isAnswered = userSnapshot['isAnswered'] as bool;
                                                      if (ongoing == true) {
                                                        isAnyFamilyMemberOngoing = true;
                                                        //selectedCellIndex(선택한 조각) 변수 파이어베이스에 업데이트
                                                        FirebaseFirestore.instance
                                                            .collection('Group')
                                                            .where('flogCode',
                                                            isEqualTo:
                                                            currentUserFlogCode)
                                                            .get()
                                                            .then((querySnapshot) {
                                                              if (querySnapshot.docs.isNotEmpty) {
                                                                final docRef = querySnapshot.docs[0].reference;
                                                                docRef.update({'isAnyFamilyMemberOngoing': isAnyFamilyMemberOngoing});
                                                              }
                                                            });
                                                      } else {
                                                        isAnyFamilyMemberOngoing = groupDocuments[0]['isAnyFamilyMemberOngoing'];
                                                        //print('!!$isAnyFamilyMemberOngoing');
                                                      }
                                                      if (isQuestionSheetShowed == true) {
                                                        isAnyFamilyMemberShowedQsheet = true;
                                                        FirebaseFirestore.instance
                                                            .collection('Group')
                                                            .where('flogCode',
                                                            isEqualTo: currentUserFlogCode)
                                                            .get()
                                                            .then((querySnapshot) {
                                                              if (querySnapshot.docs.isNotEmpty) {
                                                                final docRef = querySnapshot.docs[0].reference;
                                                                docRef.update({'isAnyFamilyMemberShowedQsheet': isAnyFamilyMemberShowedQsheet});
                                                              }
                                                            });
                                                      } else {
                                                        isAnyFamilyMemberShowedQsheet = groupDocuments[0]['isAnyFamilyMemberShowedQsheet'];

                                                      }

                                                      if (unlockStates[row * 2 + col] == true || (unlockStates[row * 2 + col] == false
                                                          && ongoing == true && selectedCellIndex == row * 2 + col)) {

                                                        tempCellIndex = row * 2 + col; //문제 번호 표시를 위한 임시 조각 번호 대입
                                                        showModalBottomSheet(
                                                            context: context,
                                                            backgroundColor: Colors.white, //질문창 배경색
                                                            isScrollControlled: true,
                                                            shape: const RoundedRectangleBorder( //위쪽 둥근 모서리
                                                              borderRadius: BorderRadius.vertical(
                                                                  top: Radius.circular(20.0)),
                                                            ),
                                                            builder: (BuildContext context) {
                                                              return SizedBox(
                                                                height: MediaQuery.of(context).size.height * 0.7, //전체 화면의 70% 덮는 크기
                                                                child: StreamBuilder<QuerySnapshot>(
                                                                    stream: FirebaseFirestore.instance
                                                                        .collection('User')
                                                                        .where('flogCode', isEqualTo: currentUserFlogCode)
                                                                        .snapshots(),
                                                                    builder: (context, userSnapshot) {
                                                                      if (userSnapshot.hasError) {
                                                                        return Text('Error: ${userSnapshot.error}');
                                                                      }
                                                                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                                                                        return Center(
                                                                          //로딩바 구현 부분
                                                                          child: SpinKitPumpingHeart(
                                                                            color: Colors.green.withOpacity(0.2),
                                                                            size: 50.0, //크기 설정
                                                                            duration: const Duration(seconds: 3),
                                                                          ),
                                                                        );
                                                                      }

                                                                      final userDocuments = userSnapshot.data!.docs;
                                                                      userDocuments.sort((a, b) {
                                                                        final aData = a.data() as Map<String, dynamic>;
                                                                        final bData = b.data() as Map<String, dynamic>;
                                                                        final aEmail = aData['email'] as String;
                                                                        final bEmail = bData['email'] as String;

                                                                        if (aEmail == currentUser.email) {
                                                                          return -1; // a를 먼저 배치
                                                                        } else if (bEmail == currentUser.email) {
                                                                          return 1; // b를 먼저 배치
                                                                        } else {
                                                                          return aEmail.compareTo(bEmail); //나머지 알파벳순 정렬
                                                                        }
                                                                      });

                                                                      return ListView(
                                                                        children: [
                                                                          const SizedBox(height: 25),
                                                                          Center(
                                                                            child: Image.asset(
                                                                              "assets/profile/profile_0.png",
                                                                              width: 70,
                                                                              height: 70,
                                                                              alignment: Alignment.centerLeft,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 20),
                                                                          StreamBuilder<QuerySnapshot>(
                                                                            stream: FirebaseFirestore.instance
                                                                                .collection("Question")
                                                                                .where('puzzleNo', isEqualTo: puzzleno)
                                                                                .where('questionNo', isEqualTo: tempCellIndex)
                                                                                .snapshots(),
                                                                            builder: (context, snapshot) {
                                                                              if (snapshot.hasError) {
                                                                                return Text('Error: ${snapshot.error}');
                                                                              }
                                                                              if (!snapshot.hasData) {
                                                                                return Scaffold(
                                                                                  body: Center(
                                                                                    //로딩바 구현 부분
                                                                                    child: SpinKitPumpingHeart(
                                                                                      color: Colors.green.withOpacity(0.2),
                                                                                      size: 50.0, //크기 설정
                                                                                      duration: const Duration(seconds: 1),
                                                                                    ),
                                                                                  ),
                                                                                  backgroundColor: Colors.transparent,
                                                                                );
                                                                              }

                                                                              final questionData = snapshot.data!.docs.isNotEmpty
                                                                                  ? snapshot.data!.docs.first.data() as Map<String, dynamic>
                                                                                  : null;

                                                                              if (questionData == null) {
                                                                                return const Text('Question not found');
                                                                              }
                                                                              final questionContent = questionData['questionContent']; // 질문 내용 가져오기
                                                                              return Center(
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 30),
                                                                                  child: Text(
                                                                                    'Q${tempCellIndex + 1}. $questionContent', // 질문 내용을 표시
                                                                                    style: const TextStyle(
                                                                                      fontSize: 18,
                                                                                      fontWeight: FontWeight.bold,
                                                                                    ),
                                                                                    textAlign: TextAlign.left,
                                                                                    softWrap: true,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                          const SizedBox(height: 25),
                                                                          ListView.builder(
                                                                            shrinkWrap: true,
                                                                            physics: const NeverScrollableScrollPhysics(),
                                                                            //스크롤을 비활성화
                                                                            itemCount: userDocuments.length,
                                                                            itemBuilder: (context, rowIndex) {
                                                                              final userData = userDocuments[rowIndex].data() as Map<String, dynamic>;
                                                                              final userProfile = userData['profile'];
                                                                              final userNickname = userData['nickname'];
                                                                              //각 사용자에 대한 답변을 불러오기
                                                                              final answerCollection = FirebaseFirestore.instance.collection('Answer');
                                                                              final query = answerCollection
                                                                                  .where('flogCode', isEqualTo: currentUserFlogCode)
                                                                                  .where('puzzleNo', isEqualTo: puzzleno)
                                                                                  .where('questionNo', isEqualTo: tempCellIndex);

                                                                              return StreamBuilder<QuerySnapshot>(
                                                                                  stream: query.snapshots(),
                                                                                  builder: (context, answerSnapshot) {
                                                                                    if (answerSnapshot.hasError) {
                                                                                      return Text('Error: ${answerSnapshot.error}');
                                                                                    }
                                                                                    if (answerSnapshot.connectionState == ConnectionState.waiting) {
                                                                                      return Center(
                                                                                        //로딩바 구현 부분
                                                                                        child: SpinKitPumpingHeart(
                                                                                          color: Colors.green.withOpacity(0.2),
                                                                                          size: 50.0, //크기 설정
                                                                                          duration: const Duration(seconds: 3),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                    final answerDocuments = answerSnapshot.data!.docs;
                                                                                    String userAnswer = "아직 답변을 작성하지 않았어요.";

                                                                                    for (final answerDoc in answerDocuments) {
                                                                                      final answers = answerDoc['answers'] as Map<String, dynamic>;
                                                                                      final userAnswerText = answers[userData['email']];
                                                                                      if (userAnswerText != null) {
                                                                                        userAnswer = userAnswerText;
                                                                                        break;
                                                                                      }
                                                                                    }
                                                                                    return Container(
                                                                                      //구성원 각각의 답변 상태 or 답변이 나타나는 상자
                                                                                        width: 350,
                                                                                        height: 110,
                                                                                        decoration: BoxDecoration(
                                                                                          borderRadius: BorderRadius.circular(10),
                                                                                          color: Colors.transparent,
                                                                                        ),
                                                                                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                                                                        child: Row(
                                                                                          children: [
                                                                                            const SizedBox(width: 15),
                                                                                            Column(
                                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                                              children: [
                                                                                                const SizedBox(height: 10),
                                                                                                Hero(
                                                                                                  tag: "profile",
                                                                                                  child: Stack(
                                                                                                    children: [
                                                                                                      Container(
                                                                                                        width: 50,
                                                                                                        height: 50,
                                                                                                        decoration: BoxDecoration(
                                                                                                          shape: BoxShape.circle,
                                                                                                          color: Colors.grey[200],
                                                                                                        ),
                                                                                                        child: Center(
                                                                                                          child: ClipOval(
                                                                                                            child: Image.asset(
                                                                                                              "assets/profile/profile_$userProfile.png",
                                                                                                              width: 40,
                                                                                                              height: 40,
                                                                                                              alignment: Alignment.center,
                                                                                                            ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                            const SizedBox(width: 20),
                                                                                            Column(
                                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                                              children: [
                                                                                                Text(
                                                                                                  userNickname,
                                                                                                  style: const TextStyle(
                                                                                                    fontSize: 17,
                                                                                                    fontWeight: FontWeight.bold,
                                                                                                    color: Colors.black,
                                                                                                  ),
                                                                                                ),
                                                                                                const SizedBox(height: 7),
                                                                                                SizedBox(
                                                                                                  child: Text(
                                                                                                    userAnswer,
                                                                                                    style: const TextStyle(
                                                                                                      fontSize: 15,
                                                                                                      color: Colors.black,
                                                                                                    ),
                                                                                                    softWrap: true, // 자동 줄바꿈
                                                                                                  ),
                                                                                                )
                                                                                              ],
                                                                                            )
                                                                                          ],
                                                                                        )
                                                                                    );
                                                                                  });
                                                                            },
                                                                          ),
                                                                        ],
                                                                      );
                                                                    }),
                                                              );
                                                            });
                                                      } else if ((unlockStates[row * 2 + col] == false && isAnyFamilyMemberShowedQsheet == false && isAnyFamilyMemberOngoing == false && isAnswered == false) //아직 안 풀린 조각이면서 질문창 보지도 x 그리고 나는 답변도 아직 x (아직 조각 선택조차 안 한 상태)
                                                          || selectedCellIndex == row * 2 + col && ongoing == false) { //현재 그 조각을 선택하고 있다면 (아직 답변x이지만 그 조각 이전에 이미 선택중인 상태, 질문창 봤을수 있음)

                                                        // 초기화
                                                        isQuestionSheetShowed = true;
                                                        DocumentReference userRef = FirebaseFirestore.instance
                                                            .collection('User')
                                                            .doc(currentUser.email);
                                                        userRef.update({'isQuestionSheetShowed': isQuestionSheetShowed}) // 필드 업데이트
                                                            .then((_) {
                                                              //print('isQuestionSheetShowed 상태가 Firebase Firestore에 업데이트되었습니다.');
                                                            }).catchError((error) {
                                                              //print('isQuestionSheetShowed 상태 업데이트 중 오류 발생: $error');
                                                            });
                                                        isAnyFamilyMemberShowedQsheet = true;
                                                        FirebaseFirestore.instance
                                                            .collection('Group')
                                                            .where('flogCode',
                                                            isEqualTo: currentUserFlogCode)
                                                            .get()
                                                            .then((querySnapshot) {
                                                          if (querySnapshot.docs.isNotEmpty) {
                                                            final docRef = querySnapshot.docs[0].reference;
                                                            docRef.update({'isAnyFamilyMemberShowedQsheet': isAnyFamilyMemberShowedQsheet});
                                                          }
                                                        });
                                                        isAnswered = false;

                                                        setState(() {
                                                          selectedCellIndex = row * 2 + col; //그리고 선택한 조각의 인덱스로 selectedCellIndex 변경
                                                          //isAnswered 변수 false로 초기화
                                                          DocumentReference userRef = FirebaseFirestore.instance
                                                              .collection('User')
                                                              .doc(currentUser.email);
                                                          userRef.update({
                                                            'isAnswered': false
                                                          }) //isAnswered 필드 업데이트
                                                              .then((_) {
                                                                //print('isAnswered 상태가 Firebase Firestore에 업데이트되었습니다.');
                                                              }).catchError((error) {
                                                                //print('isAnswered 상태 업데이트 중 오류 발생: $error');
                                                              });

                                                          //selectedCellIndex(선택한 조각) 변수 파이어베이스에 업데이트
                                                          FirebaseFirestore.instance
                                                              .collection('Group')
                                                              .where('flogCode', isEqualTo: currentUserFlogCode)
                                                              .get()
                                                              .then(
                                                                  (querySnapshot) {
                                                                    if (querySnapshot.docs.isNotEmpty) {
                                                                      final docRef = querySnapshot.docs[0].reference;
                                                                      docRef.update({'selectedIndex': selectedCellIndex});
                                                                    }
                                                                  });
                                                        });
                                                        // 0 1
                                                        // 2 3
                                                        // 4 5
                                                        //형태로 조각 인덱싱하고, 해당 조각 클릭시 인덱스를 저장

                                                        showQuestionSheet(context); //클릭한 조각에 대한 질문탭 나타나기
                                                      }
                                                    },
                                                    child: Container(
                                                      //분할된 조각
                                                      width: 170,
                                                      height: 170,
                                                      decoration: BoxDecoration(
                                                        color: unlockStates[row * 2 + col]
                                                            ? Colors.transparent //unlock되면 투명해져서 사진이 드러남
                                                            : const Color(0xFF000000),
                                                        //unlock되지 않았으면 검정색 조각으로 덮음
                                                        border: Border.all( //테두리
                                                          color: unlockStates[row * 2 + col]
                                                              ? const Color(0xFF62BC1B) //unlock되면 초록 테두리
                                                              : Colors.white,
                                                          //unlock되지 않았으면 흰색 테두리
                                                          width: 2.0, //테두리 두께
                                                        ),
                                                        borderRadius:
                                                        BorderRadius.only( //둥근 테두리 설정
                                                          topLeft: Radius.circular((row == 0 && col == 0) ? 23.0 : 0.0), // 1행 1열 - 좌측 상단 모서리
                                                          topRight: Radius.circular((row == 0 && col == 1) ? 23.0 : 0.0), // 1행 2열 - 우측 상단 모서리
                                                          bottomLeft: Radius.circular((row == 2 && col == 0) ? 23.0 : 0.0), // 3행 1열 - 좌측 하단 모서리
                                                          bottomRight: Radius.circular((row == 2 && col == 1) ? 23.0 : 0.0), // 3행 2열 - 우측 하단 모서리
                                                        ),
                                                      ),
                                                      child: Stack(
                                                        alignment: Alignment.center,
                                                        children: [ //현재 진행 중인 조각이면 - 선택된 조각이 아직 unlock되지 않았고 선택한 조각이면
                                                          if (selectedCellIndex == row * 2 + col && unlockStates[row * 2 + col] == false)
                                                            Stack(
                                                              children: [
                                                                Container(decoration: BoxDecoration(
                                                                  border: Border.all( //초록 테두리
                                                                    color: const Color(0xFF62BC1B),
                                                                    width: 2.0,
                                                                  ),
                                                                  borderRadius: BorderRadius.only( //둥근 모서리
                                                                    topLeft: Radius.circular((row == 0 && col == 0) ? 23.0 : 0.0), // 1행 1열
                                                                    topRight: Radius.circular((row == 0 && col == 1) ? 23.0 : 0.0), // 1행 2열
                                                                    bottomLeft: Radius.circular((row == 2 && col == 0) ? 23.0 : 0.0), // 3행 1열
                                                                    bottomRight: Radius.circular((row == 2 && col == 1) ? 23.0 : 0.0), // 3행 2열
                                                                  ),
                                                                ),
                                                                ),
                                                                Center(
                                                                  child: Image.asset( //발자국 표시
                                                                    "assets/flog_foot_green.png",
                                                                    width: 50,
                                                                    height: 50,
                                                                    color: const Color(0xFF62BC1B),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else if (qpuzzleUrl == null) // qpuzzleUrl이 없을 때!! 회색 상자와 + 버튼 표시
                                Container(
                                  width: 340,
                                  height: 510,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200], // 회색 상자
                                    borderRadius:
                                    BorderRadius.circular(23), // 둥근 모서리
                                  ),
                                  child: Center(
                                    child: InkWell(
                                      onTap: () async {
                                        onPickImage(); // 갤러리에서 사진 선택하여 불러오는 함수
                                      },
                                      child: Image.asset(
                                        "button/plus.png",
                                        width: 30,
                                        height: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 15),
                              StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection("Question")
                                      .where('puzzleNo', isEqualTo: puzzleno)
                                      .where('questionNo',
                                      isEqualTo: selectedCellIndex)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                    if (!snapshot.hasData) {
                                      return Center(
                                        //로딩바 구현 부분
                                        child: SpinKitPumpingHeart(
                                          color: Colors.green.withOpacity(0.2),
                                          size: 50.0, //크기 설정
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }

                                    final questionData = snapshot.data!.docs.isNotEmpty
                                        ? snapshot.data!.docs.first.data() as Map<String, dynamic>
                                        : null;
                                    if (questionData == null) {
                                      return const Text(
                                        '조각이 선택되지 않았습니다.',
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                        softWrap: true, //자동 줄바꿈
                                      );
                                    }
                                    final questionContent =
                                    questionData['questionContent'];
                                    return Container(
                                      width: 350,
                                      decoration: const BoxDecoration(
                                          color: Colors.transparent,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Q${selectedCellIndex + 1}. $questionContent',
                                              style: const TextStyle(
                                                fontSize: 17,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              softWrap: true, //자동 줄바꿈
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ],
                      )),
                ),
              );
            },
          );
        });
  }
  /*-----------------------------함수-----------------------------*/

  //갤러리에서 사진 선택하여 불러오는 함수
  void onPickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    final croppedImage = await ImageCropper() //2:3 비율로 크롭
        .cropImage(
        sourcePath: image!.path,
        aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 3));
    setState(() {
      this.image = XFile(croppedImage!.path);
    });
    final currentUser = FirebaseAuth.instance.currentUser!;
    final usersCollection = FirebaseFirestore.instance.collection("User");
    DocumentSnapshot userDocument =
    await usersCollection.doc(currentUser.email).get();
    if (userDocument.exists) {
      String flogCode = userDocument.get('flogCode');
      postImage(flogCode, puzzleno + 1, currentUser.email!);
      qpuzzleUploader = currentUser.email!;
      //조각별로 Answer 문서 생성
      postAnswer(currentUserFlogCode, puzzleno + 1, 0);
      postAnswer(currentUserFlogCode, puzzleno + 1, 1);
      postAnswer(currentUserFlogCode, puzzleno + 1, 2);
      postAnswer(currentUserFlogCode, puzzleno + 1, 3);
      postAnswer(currentUserFlogCode, puzzleno + 1, 4);
      postAnswer(currentUserFlogCode, puzzleno + 1, 5);
      _showqpuzzleTitleEditingDialog();
    }
  }

  //질문탭 나타나게 하는 함수
  void showQuestionSheet(context) async {
    isQuestionSheetShowed =
    true; //질문탭이 나타나면 isQuestionSheetShowed 변수 boolean값 true로 변경
    //파이어베이스에 isQuestionSheetShowed 변수 업데이트
    DocumentReference userRef =
    FirebaseFirestore.instance.collection('User').doc(currentUser.email);
    userRef.update({'isQuestionSheetShowed': true}).then((_) {
      //print('isQuestionSheetShowed 상태가 Firebase Firestore에 업데이트되었습니다.');
    }).catchError((error) {
      //print('isQuestionSheetShowed 상태 업데이트 중 오류 발생: $error');
    });

    //탭 띄우기
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        //질문창 배경색
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          //위쪽 둥근 모서리
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7, //전체 화면의 70% 덮는 크기
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('User')
                    .where('flogCode', isEqualTo: currentUserFlogCode)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  }
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      //로딩바 구현 부분
                      child: SpinKitPumpingHeart(
                        color: Colors.green.withOpacity(0.2),
                        size: 50.0, //크기 설정
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }

                  final userDocuments = userSnapshot.data!.docs;
                  userDocuments.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aEmail = aData['email'] as String;
                    final bEmail = bData['email'] as String;

                    if (aEmail == currentUser.email) {
                      return -1; // a를 먼저 배치
                    } else if (bEmail == currentUser.email) {
                      return 1; // b를 먼저 배치
                    } else {
                      return aEmail.compareTo(bEmail); //나머지 알파벳순 정렬
                    }
                  });

                  return ListView(
                    children: [
                      const SizedBox(height: 25),
                      Center(
                        child: Image.asset(
                          "assets/profile/profile_0.png",
                          width: 70,
                          height: 70,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("Question")
                              .where('puzzleNo', isEqualTo: puzzleno)
                              .where('questionNo', isEqualTo: selectedCellIndex)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (!snapshot.hasData) {
                              return Scaffold(
                                body: Center(
                                  //로딩바 구현 부분
                                  child: SpinKitPumpingHeart(
                                    color: Colors.green.withOpacity(0.2),
                                    size: 50.0, //크기 설정
                                    duration: const Duration(seconds: 3),
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                              );
                            }

                            final questionData = snapshot.data!.docs.isNotEmpty
                                ? snapshot.data!.docs.first.data()
                            as Map<String, dynamic>
                                : null;
                            if (questionData == null) {
                              return const Text('Question not found');
                            }
                            final questionContent =
                            questionData['questionContent']; // 질문 내용 가져오기
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30), //왼쪽과 오른쪽 간격 지정
                                child: Text(
                                  'Q${selectedCellIndex + 1}. $questionContent',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.left,
                                  softWrap: true, //자동 줄바꿈
                                ),
                              ),
                            );
                          }),
                      const SizedBox(height: 25),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        //스크롤을 비활성화
                        itemCount: userDocuments.length,
                        itemBuilder: (context, rowIndex) {
                          final userData = userDocuments[rowIndex].data()
                          as Map<String, dynamic>;
                          final userProfile = userData['profile'];
                          final userNickname = userData['nickname'];
                          //각 사용자에 대한 답변을 불러오기
                          final answerCollection =
                          FirebaseFirestore.instance.collection('Answer');
                          final query = answerCollection
                              .where('flogCode', isEqualTo: currentUserFlogCode)
                              .where('puzzleNo', isEqualTo: puzzleno)
                              .where('questionNo', isEqualTo: tempCellIndex);

                          return StreamBuilder<QuerySnapshot>(
                              stream: query.snapshots(),
                              builder: (context, answerSnapshot) {
                                if (answerSnapshot.hasError) {
                                  return Text('Error: ${answerSnapshot.error}');
                                }
                                if (answerSnapshot.connectionState == ConnectionState.waiting) {
                                  return Center(
                                    //로딩바 구현 부분
                                    child: SpinKitPumpingHeart(
                                      color: Colors.green.withOpacity(0.2),
                                      size: 50.0, //크기 설정
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                                final answerDocuments = answerSnapshot.data!.docs;
                                String userAnswer = "답변을 작성한 후 확인하세요."; // 변수를 이 부분에서 선언하고 초기화
                                if (isAnswered == true) {
                                  for (final answerDoc in answerDocuments) {
                                    final answers = answerDoc['answers'] as Map<String, dynamic>;
                                    final userAnswerText = answers[userData['email']];
                                    if (userAnswerText != null) {
                                      userAnswer = userAnswerText;
                                      break;
                                    }
                                  }
                                }
                                if (userData['email'] == currentUser.email && isAnswered == false) {
                                  userAnswer = "클릭하여 답변 쓰기...";
                                }

                                return GestureDetector(
                                  onTap: () {
                                    if (userData['email'] == currentUser.email && isAnswered == false) {
                                      //'나'의 박스: '답변 작성하기' 부분을 클릭하면
                                      myanswer = ""; //myanswer 변수 초기화
                                      showAnswerSheet(context); //답변 작성 탭 나타남
                                    }
                                  },
                                  child:Container(
                                    //구성원 각각의 답변 상태 or 답변이 나타나는 상자
                                      width: double.infinity,
                                      height: 110,
                                      //높이 설정
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.transparent,
                                      ),
                                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 15),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 10),
                                              Hero(
                                                tag: "profile",
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.grey[200],
                                                      ),
                                                      child: Center(
                                                        child: ClipOval(
                                                          child: Image.asset(
                                                            "assets/profile/profile_$userProfile.png",
                                                            width: 40,
                                                            height: 40,
                                                            alignment: Alignment
                                                                .center,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 20),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userNickname,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              SizedBox(
                                                child: Text(
                                                  isAnswered == false
                                                      ? userAnswer
                                                      : "답변을 작성한 후 확인하세요.",
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    color: Color(0xFFA9A8A8)
                                                  ),
                                                  softWrap: true, //자동 줄바꿈
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                  ),
                                );
                              });
                        },
                      ),
                    ],
                  );
                }),
          );
        });
  }

  //답변 탭 나타나게 하는 함수
  void showAnswerSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white, //답변창 배경색
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20.0)), //위쪽 둥근 모서리
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7, //전체 화면의 70% 덮는 크기
                    child: StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection("User")
                            .doc(currentUser.email)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            if (snapshot.data == null || !snapshot.data!.exists) {
                              return const Text('데이터 없음 또는 문서가 없음'); // Firestore 문서가 없는 경우 또는 데이터가 null인 경우 처리
                            } //이제 snapshot.data을 안전하게 사용할 수 있음
                            Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;

                            return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('Answer')
                                    .where('flogCode', isEqualTo: currentUserFlogCode)
                                    .where('puzzleNo', isEqualTo: puzzleno)
                                    .where('questionNo',
                                    isEqualTo: selectedCellIndex).snapshots(),
                                builder: (context, answerSnapshot) {
                                  if (answerSnapshot.hasError) {
                                    return Text('Error: ${answerSnapshot.error}');
                                  }
                                  if (answerSnapshot.connectionState == ConnectionState.waiting) {

                                  }

                                  return ListView(
                                    children: [
                                      Column(
                                        children: [
                                          const SizedBox(height: 15),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 20, top: 10),
                                              child: InkWell(
                                                onTap: () async {
                                                  if (isSendButtonEnabled) {
                                                    setState(() {
                                                      isAnswered = true; //전송 버튼 누르면 답변한 것
                                                      ongoing = true; //나는 답변 완료했으므로 ongoing = true

                                                      //파이어베이스에 ongoing 변수 업데이트
                                                      DocumentReference userRef = FirebaseFirestore.instance
                                                          .collection('User')
                                                          .doc(currentUser.email);
                                                      userRef.update({'ongoing': true}).then((_) {
                                                        //print('ongoing 상태가 Firebase Firestore에 업데이트되었습니다.');
                                                      }).catchError((error) {
                                                        //print('ongoing 상태 업데이트 중 오류 발생: $error');
                                                      });
                                                    });

                                                    //파이어베이스에 isAnswered 변수 업데이트
                                                    DocumentReference userRef = FirebaseFirestore.instance
                                                        .collection('User')
                                                        .doc(currentUser.email);
                                                    userRef.update({'isAnswered': true}).then((_) {
                                                      //print('isAnswered 상태가 Firebase Firestore에 업데이트되었습니다.');
                                                    }).catchError((error) {
                                                      //print('isAnswered 상태 업데이트 중 오류 발생: $error');
                                                    });

                                                    //내 답변 파이어베이스에 업로드
                                                    CollectionReference answerCollection = FirebaseFirestore.instance
                                                        .collection('Answer');
                                                    Query query = answerCollection
                                                        .where('flogCode', isEqualTo: currentUserFlogCode)
                                                        .where('puzzleNo', isEqualTo: (puzzleno))
                                                        .where('questionNo', isEqualTo: selectedCellIndex);

                                                    query.get().then((querySnapshot) {
                                                      final existingAnswerDocument = querySnapshot.docs.first;
                                                      Map<String, dynamic> existingAnswers = existingAnswerDocument['answers'];
                                                      existingAnswers[userData['email']] = myanswer;

                                                      existingAnswerDocument.reference.update({'answers': existingAnswers,}).then((_) {
                                                        //print('Answer이 Firebase Firestore에 업데이트되었습니다.');
                                                      }).catchError((error) {
                                                        //print('Answer 업데이트 중 오류 발생: $error');
                                                      });
                                                    });

                                                    //전체 가족 답변 여부 체크해서 result 변수에 담기 (전체 가족 답변 완료 시, true 저장)
                                                    final result = await checkFamilystate();

                                                    if (result == true) {//전체 가족 답변 완료
                                                      setState(() {
                                                        answerController.clear();
                                                        qpuzzleTitleController.clear();
                                                        unlockStates[selectedCellIndex] = true; //해당 조각을 unlock 상태로 변경 (잠금 해제)
                                                        isQuestionSheetShowed = false; //초기화
                                                        isAnyFamilyMemberOngoing = false;
                                                        isAnyFamilyMemberShowedQsheet = false;
                                                        FirebaseFirestore.instance
                                                            .collection('Group')
                                                            .where('flogCode', isEqualTo: currentUserFlogCode)
                                                            .get()
                                                            .then((querySnapshot) {
                                                              if (querySnapshot.docs.isNotEmpty) {
                                                                final docRef = querySnapshot.docs[0].reference;
                                                                docRef.update({
                                                                  'isAnyFamilyMemberOngoing': false,
                                                                  'isAnyFamilyMemberShowedQsheet': false
                                                                });
                                                              }
                                                            });
                                                        myanswer = ""; //myanswer 변수 초기화
                                                        //파이어베이스에 isQuestionSheetShowed 변수 업데이트
                                                        DocumentReference userRef = FirebaseFirestore.instance
                                                            .collection('User')
                                                            .doc(currentUser.email);

                                                        userRef.update({'isQuestionSheetShowed': false}) // 필드 업데이트
                                                            .then((_) {
                                                              //print('isQuestionSheetShowed 상태가 Firebase Firestore에 업데이트되었습니다.');
                                                            }).catchError((error) {
                                                              //print('isQ 상태 업데이트 중 오류 발생: $error');
                                                            });
                                                      });

                                                      //파이어베이스에 unlock 필드 업데이트
                                                      DocumentReference groupRef = FirebaseFirestore.instance
                                                          .collection('Group')
                                                          .doc(currentUserFlogCode);
                                                      groupRef.update({'unlock': unlockStates}).then((_) {
                                                        //print('Unlock 상태가 Firebase Firestore에 업데이트되었습니다.');
                                                      }).catchError((error) {
                                                        //print('Unlock 상태 업데이트 중 오류 발생: $error');
                                                      });
                                                      groupNotification(groupNo, "[Q-puzzle]", "퍼즐 조각이 풀렸습니다!");

                                                      //이제 새로운 조각을 풀어야하기 때문에 나 뿐만 아니라 모든 가족 구성원의 isAnswered 변수 초기화
                                                      final userRefs = firestore
                                                          .collection('User')
                                                          .where('flogCode', isEqualTo: currentUserFlogCode);
                                                      QuerySnapshot userSnapshots = await userRefs.get();

                                                      for (final userSnapshot in userSnapshots.docs) {
                                                        final userDocRef = firestore.doc('User/${userSnapshot.id}');
                                                        await userDocRef.update({'isAnswered': isAnswered});
                                                      }

                                                      //ongoing 변수 초기화
                                                      ongoing = false;

                                                      //파이어베이스에 ongoing 변수 초기화 ->사실 밑에서 전체 문서를 돌리며 해서 안 해도 될 것 같긴 한데 불안해서 남김
                                                      DocumentReference userRef = FirebaseFirestore.instance
                                                          .collection('User')
                                                          .doc(currentUser.email);
                                                      userRef.update({'ongoing': false}) //isAnswered 필드 업데이트
                                                          .then((_) {
                                                            //print('ongoing 상태가 Firebase Firestore에 업데이트되었습니다.');
                                                          }).catchError((error) {
                                                            ///print('ongoing 상태 업데이트 중 오류 발생: $error');
                                                          });

                                                      isAnswered = false;
                                                      //나 뿐만 아니라 모든 가족 구성원의 ongoing, isAnswered 변수 초기화
                                                      for (final userSnapshot in userSnapshots.docs) {
                                                        final userDocRef = firestore.doc('User/${userSnapshot.id}');
                                                        await userDocRef.update({'ongoing': false});
                                                        await userDocRef.update({'isAnswered': false});
                                                      }

                                                      //qpuzzle 완성했을 때
                                                      if (unlockStates.every((unlockState) => unlockState == true)) { //qpuzzleUrl을 ""로 설정하고 unlock 초기화
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);

                                                        FirebaseFirestore.instance
                                                            .collection('Group')
                                                            .where('flogCode', isEqualTo: currentUserFlogCode)
                                                            .get()
                                                            .then((querySnapshot) {
                                                              if (querySnapshot.docs.isNotEmpty) {
                                                                final docRef = querySnapshot.docs[0].reference;
                                                                docRef.update({
                                                                  'qpuzzleUrl': "", //qpuzzleUrl 초기화
                                                                  'unlock': List.generate(6, (_) => false), //unlock 초기화 (6개 조각)
                                                                  'selectedIndex': -1, //선택한 조각 인덱스 초기화
                                                                });
                                                              }
                                                            });
                                                        FirebaseFirestore.instance
                                                            .collection('Qpuzzle')
                                                            .where('flogCode', isEqualTo: currentUserFlogCode)
                                                            .orderBy('puzzleNo', descending: true)
                                                            .snapshots()
                                                            .listen((querySnapshot) {
                                                              if (querySnapshot.docs.isNotEmpty) {
                                                                final docRef = querySnapshot.docs.first.reference;
                                                                docRef.update({
                                                                  'isComplete': true, //Qpuzzle 컬렉션에서 isComplete 필드 반영
                                                                  'qpuzzleUploader': "",
                                                                  'qpuzzleTitle': ""
                                                                });
                                                              }
                                                            });
                                                        groupNotification(
                                                            groupNo,
                                                            "[Q-puzzle]",
                                                            '$puzzleno 번째 퍼즐이 완성되었습니다!\n메모리 박스에서 확인하세요.');
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return AlertDialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(15.0), // 모서리 둥글게
                                                              ),
                                                              title: const Text(
                                                                '퍼즐 완성!',
                                                                style:
                                                                TextStyle(
                                                                  color: Color(0xFF62BC1B),
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                              content: Text(
                                                                '$puzzleno 번째 퍼즐이 완성되었습니다!\n메모리 박스에서 확인하세요.',
                                                                style: const TextStyle(
                                                                  color: Colors.black,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                              actions: <Widget>[
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                                                                  children: [
                                                                    TextButton(
                                                                      style:
                                                                      ButtonStyle(shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                                        RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                                                                        ),
                                                                      ),
                                                                        backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                                                                      ),
                                                                      onPressed: () { //팝업 닫기
                                                                        Navigator.of(context).pop();
                                                                      },
                                                                      child: Text(
                                                                        'OK',
                                                                        style: GoogleFonts.balooBhaijaan2(
                                                                          textStyle: const TextStyle(
                                                                            color: Colors.white,
                                                                            fontWeight: FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                        appbarText = "Qpuzzle";
                                                        return;
                                                      }
                                                    }
                                                    //여기서부터는 전체 가족이 답변 하지 않았더라도 수행됨

                                                    Navigator.pop(context); //답변창 닫기
                                                    Navigator.pop(context); //질문창 닫기

                                                    isQuestionSheetShowed = false; //초기화

                                                    //파이어베이스 초기화
                                                    userRef.update({'isQuestionSheetShowed': false}).then((_) {
                                                      //print('isQuestionSheetShowed 상태가 Firebase Firestore에 업데이트되었습니다.');
                                                    }).catchError((error) {
                                                      //print('isQ 상태 업데이트 중 오류 발생: $error');
                                                    });
                                                  }
                                                },
                                                child: Image.asset(
                                                  "button/send_white.png",
                                                  width: 30,
                                                  height: 30,
                                                  color: isSendButtonEnabled
                                                      ? const Color(0xFF62BC1B)
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Image.asset(
                                              "assets/profile/profile_0.png",
                                              width: 70,
                                              height: 70,
                                              alignment: Alignment.centerLeft,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection("Question")
                                                  .where('puzzleNo', isEqualTo: puzzleno)
                                                  .where('questionNo', isEqualTo: selectedCellIndex)
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasError) {
                                                  return Text(
                                                  'Error: ${snapshot.error}');
                                                }
                                                if (!snapshot.hasData) {
                                                  return Center( //로딩바 구현 부분
                                                    child: SpinKitPumpingHeart(
                                                      color: Colors.green.withOpacity(0.2),
                                                      size: 50.0, //크기 설정
                                                      duration: const Duration(seconds: 5),
                                                    ),
                                                  );
                                                }

                                                final questionData = snapshot
                                                    .data!.docs.isNotEmpty
                                                    ? snapshot.data!.docs.first
                                                    .data()
                                                as Map<String, dynamic>
                                                    : null;
                                                if (questionData == null) {
                                                  return const Text(
                                                      'Question not found'
                                                  );
                                                }
                                                final questionContent = questionData['questionContent']; // 질문 내용 가져오기
                                                return Center(
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 30), //왼쪽과 오른쪽 간격 지정
                                                    child: Text(
                                                      'Q${selectedCellIndex + 1}. $questionContent',
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                          FontWeight.bold),
                                                      textAlign: TextAlign.left,
                                                      softWrap: true, //자동 줄바꿈
                                                    ),
                                                  ),
                                                );
                                              }),
                                          const SizedBox(height: 25),
                                          Padding(
                                            padding:
                                            const EdgeInsets.only(left: 15),
                                            child: Row(children: [
                                              Hero(
                                                tag: "profile",
                                                child: Stack(children: [
                                                  Container(
                                                    width: 60,
                                                    height: 60,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle, //원 모양 프로필 사진
                                                      color: Colors.grey[300], //배경색
                                                    ),
                                                    child: Center(
                                                      child: ClipOval(
                                                        child: Image.asset(
                                                          "assets/profile/profile_${userData['profile']}.png",
                                                          width: 50,
                                                          height: 50,
                                                          alignment:
                                                          Alignment.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ]),
                                              ),
                                              const SizedBox(width: 20),
                                              Text(
                                                userData['nickname'],
                                                textAlign: TextAlign.left,
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.black,
                                                    fontWeight:
                                                    FontWeight.bold),
                                              ),
                                            ]),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: TextField(
                                              //답변 입력창
                                              controller: answerController,
                                              style: const TextStyle(color: Colors.black),
                                              maxLines: null,
                                              keyboardType: TextInputType.multiline,
                                              decoration: const InputDecoration(
                                                  hintText: '클릭하여 답변 쓰기...', //힌트 문구
                                                  hintStyle: TextStyle(color: Colors.grey),
                                                  border: OutlineInputBorder(borderSide: BorderSide.none)
                                              ),
                                              onChanged: (text) {
                                                setState(() {
                                                  myanswer = text; //입력한 내용을 myanswer 변수에 저장
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  );
                                });
                          }
                        })
                )
            ),
          );
        });
  }

  //전체 가족 답변 여부 체크
  Future<bool> checkFamilystate() async {
    DocumentReference currentDocumentRef =
    firestore.collection('Group').doc(currentUserFlogCode);
    DocumentSnapshot groupDocumentSnapshot = await currentDocumentRef.get();
    familyMem = groupDocumentSnapshot['memNumber']; //가족 수

    final userRefs = firestore
        .collection('User')
        .where('flogCode', isEqualTo: currentUserFlogCode);
    QuerySnapshot userSnapshots = await userRefs.get();

    bool allAnswered = true;

    //멤버 수 만큼 for문 돌리면서 isAnswered가 false이면 최종적으로 false 리턴
    for (final userSnapshot in userSnapshots.docs) {
      final isAnswered = userSnapshot['isAnswered'];
      if (isAnswered != true) {
        // 하나라도 업로드되지 않은 사용자가 있으면 false로 설정하고 루프 종료
        allAnswered = false;
        break;
      }
    }
    return allAnswered;
  }

  void _showqpuzzleTitleEditingDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // 모서리 둥글게
            ),
            title: const Text(
              '퍼즐에 대해 설명해주세요!',
              style: TextStyle(
                color: Color(0xFF62BC1B),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qpuzzleTitleController,
                  maxLength: 25,
                  decoration: InputDecoration(
                      hintText: '클릭하여 설명 쓰기...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF62BC1B)),
                        borderRadius: BorderRadius.circular(10),
                      )),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          qpuzzleTitle = qpuzzleTitleController.text;

                          FirebaseFirestore.instance
                              .collection('Qpuzzle')
                              .where('flogCode', isEqualTo: currentUserFlogCode)
                              .orderBy('puzzleNo', descending: true)
                              .snapshots()
                              .listen((querySnapshot) {
                            if (querySnapshot.docs.isNotEmpty) {
                              final docRef = querySnapshot.docs.first.reference;
                              docRef.update({
                                'qpuzzleTitle':
                                qpuzzleTitle //Qpuzzle 컬렉션에서 isComplete 필드 반영
                              });
                            }
                          });
                        });
                        Navigator.of(context).pop();
                        groupNotification(groupNo, "[Q-puzzle]",
                            "새로운 퍼즐이 생성되었습니다! 퍼즐을 확인해보세요");
                      },
                      style: ButtonStyle(
                        shape:
                        MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                          ),
                        ),
                        backgroundColor:
                        MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                      ),
                      child: Text(
                        '확인',
                        style: GoogleFonts.balooBhaijaan2(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ButtonStyle(
                        shape:
                        MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                          ),
                        ),
                        backgroundColor:
                        MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                      ),
                      child: Text(
                        '취소',
                        style: GoogleFonts.balooBhaijaan2(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }
}

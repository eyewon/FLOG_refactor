import 'package:flog/notification/fcm_controller.dart';
//import 'package:flog/notification/local_notification.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flog/resources/firestore_methods.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flog/widgets/comment_card.dart';
import 'package:flog/widgets/checkTodayFlog.dart';

class FlogingDetailScreen extends StatefulWidget {
  final String flogingId;

  const FlogingDetailScreen({
    Key? key,
    required this.flogingId,
  }) : super(key: key);

  @override
  FlogingDetailScreenState createState() => FlogingDetailScreenState();
}

class FlogingDetailScreenState extends State<FlogingDetailScreen> {
  final _commentTextController = TextEditingController();
  String currentUserFlogCode = ""; // 현재 로그인한 사용자의 flogCode
  String currentUserNickname = "";
  bool currentUserUploaded = false;
  bool isSwitched = false;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FireStoreMethods fireStoreMethods = FireStoreMethods();
  final currentUser = FirebaseAuth.instance.currentUser!;

  String rToken = ""; //댓글알림수신토큰

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void onRightTopImageClicked() {
    setState(() {
      isSwitched = !isSwitched;
    });
  }

  // 현재 로그인한 사용자의 flogCode를 Firestore에서 가져오는 함수
  Future<void> getUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(currentUser.email)
        .get();

    if (userDoc.exists) {
      setState(() {
        currentUserFlogCode = userDoc.data()!['flogCode'];
        currentUserNickname = userDoc.data()!['nickname'];
        currentUserUploaded = userDoc.data()!['isUpload'];
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // 모서리 둥글게
          ),
          title: const Text(
            'FLOGing 삭제',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF62BC1B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '이 FLOGing을 삭제하시겠습니까?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                  ),
                  onPressed: () async {
                    try {
                      Navigator.of(context).pop(); // 현재 다이얼로그 닫기
                      Navigator.of(context).pop(); // FlogingDetailScreen 닫기

                      // Firebase에서 Floging 삭제
                      await FirebaseFirestore.instance
                          .collection('Floging')
                          .doc(widget.flogingId)
                          .delete();

                      await checkTodayFlog();
                      await getUserData();

                    } catch (e) {

                      Navigator.of(context).pop(); // 현재 다이얼로그 닫기

                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return const AlertDialog(
                            title: Text('오류 발생'),
                            content: Text('삭제 중에 오류가 발생했습니다.'),
                          );
                        },
                      );
                    }
                  },
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 텍스트 필드 클리어 및 키보드 숨김 함수
  void clearTextFieldAndHideKeyboard() {
    _commentTextController.clear();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final flogingId = widget.flogingId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Floging')
          .where('flogingId', isEqualTo: flogingId)
          .snapshots(),
      builder: (context, flogSnapshot) {
        if (flogSnapshot.hasError) {
          return Text('Error: ${flogSnapshot.error}');
        }

        if (flogSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              //로딩바 구현 부분
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitPumpingHeart(
                    color: Colors.green.withOpacity(0.2),
                    size: 50.0, //크기 설정
                    duration: const Duration(seconds: 3),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '전환중...',
                    style: TextStyle(
                      color: Color(0xFF62BC1B)
                    ),
                  )
                ],
              ),
            ),
            backgroundColor: Colors.white
          );
        }

        final flogDocuments = flogSnapshot.data!.docs; // flogDocuments에서 필요한 데이터 추출
        final flogData = flogDocuments.first.data() as Map<String, dynamic>;
        final caption = flogData['caption'];

        return Scaffold(
          //extendBodyBehindAppBar: true,
          appBar: AppBar(
            toolbarHeight: 65, // 높이 조정
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            elevation: 0.0,
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  '${flogData['uid'].split('@')[0]} FLOGing',
                  style: GoogleFonts.balooBhaijaan2(
                    textStyle: const TextStyle(
                      fontSize: 23,
                      color: Color(0xFF62BC1B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${flogData['date'].toDate().hour.toString().padLeft(2, '0')}:${flogData['date'].toDate().minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.balooBhaijaan2(
                    textStyle: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF62BC1B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
              onPressed: () {// 뒤로가기 버튼 클릭 시 이전 페이지(Floging_Screen)로 이동
                Navigator.pop(context);
              },
            ),
            actions: [
              Visibility(
                visible: (currentUser.email == flogData['uid']), // 삭제 권한이 있는 경우에만 버튼 표시
                child: IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.black,
                  ),
                  onPressed: () {// "삭제" 팝업 다이얼로그를 표시
                    _showDeleteConfirmationDialog();
                  },
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
                children: [
                  const SizedBox(height: 10),
                  Stack(
                    children: <Widget>[
                      Container(
                        width: 350,
                        height: 540,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(!isSwitched ? flogData['downloadUrl_back'] : flogData['downloadUrl_front']),
                            fit: BoxFit.cover,
                          ),
                          color: const Color(0xffd9d9d9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: onRightTopImageClicked,
                          child: Container(
                            width: 78,
                            height: 120,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(isSwitched ? flogData['downloadUrl_back'] : flogData['downloadUrl_front']),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection("User")
                          .doc(flogData['uid'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Scaffold(
                            body: Center(//로딩바 구현 부분
                              child: SpinKitPumpingHeart(
                                color: Colors.green.withOpacity(0.2),
                                size: 50.0, //크기 설정
                                duration: const Duration(seconds: 2),
                              ),
                            ),
                            backgroundColor: Colors.transparent
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          if (snapshot.data == null || !snapshot.data!.exists) {
                            return const Text('데이터 없음 또는 문서가 없음'); // Firestore 문서가 없는 경우 또는 데이터가 null인 경우 처리
                          }
                        }
                        Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
                        rToken = userData['token']; //토큰 받아오기
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/profile/profile_${userData['profile']}.png",
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              caption,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                            ),
                          ],
                        );
                      }),
                  const SizedBox(height: 5),
                  const Divider(),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Floging')
                        .doc(flogingId)
                        .collection('Comment')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, commentSnapshot) {
                      if (commentSnapshot.hasError) {
                        return Text('Error: ${commentSnapshot.error}');
                      }
                      if (commentSnapshot.connectionState == ConnectionState.waiting) {
                        return Scaffold(
                          body: Center(
                            //로딩바 구현 부분
                            child: Column(
                              children: [
                                SpinKitPumpingHeart(
                                  color: Colors.green.withOpacity(0.2),
                                  size: 50.0, //크기 설정
                                  duration: const Duration(seconds: 2),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '댓글 로딩중..',
                                  style: TextStyle(
                                      color: Color(0xFF62BC1B)
                                  ),
                                )
                              ],
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                        );
                      }
                      final commentDocuments = commentSnapshot.data!.docs;

                      if (commentDocuments.isEmpty) {
                        return const Column(
                          children: [
                            Text(
                              '아직 댓글이 없습니다. 댓글을 달아보세요!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 25)
                          ],
                        );
                      }
                      return Column(
                        children: commentDocuments.map((commentDoc) {
                          final commentData = commentDoc.data() as Map<String, dynamic>;
                          final commentId = commentData['commentId'];
                          final text = commentData['text'];
                          final date = commentData['date'];
                          final uid = commentData['uid'];

                          return Column(
                            children: [
                              CommentCard(
                                date: date,
                                commentId: commentId,
                                text: text,
                                uid: uid,
                                flogingId: flogingId,
                              ),
                              const SizedBox(width: 10),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ]
            ),
          ),

          bottomNavigationBar: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection("User")
                  .doc(currentUser.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center( //로딩바 구현 부분
                      child: SpinKitPumpingHeart(
                        color: Colors.green.withOpacity(0.2),
                        size: 50.0, //크기 설정
                        duration: const Duration(seconds: 5),
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  if (snapshot.data == null || !snapshot.data!.exists) {
                    return const Text('데이터 없음 또는 문서가 없음'); // Firestore 문서가 없는 경우 또는 데이터가 null인 경우 처리
                  }

                  // 이제 snapshot.data을 안전하게 사용할 수 있음
                  Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
                  return SafeArea(
                    child: Container(
                      color: Colors.white,
                      height: kToolbarHeight,
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Row(
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
                                  "assets/profile/profile_${userData['profile']}.png",
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 8),
                              child: TextField(
                                controller: _commentTextController,
                                decoration: InputDecoration(
                                  hintText: '${userData['nickname']}로 댓글 달기',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await fireStoreMethods.postComment(
                                widget.flogingId,
                                _commentTextController.text,
                                currentUser.uid,
                              );
                              if (currentUser.email != flogData['uid']) {
                                sendNotification(
                                    rToken,
                                    "[FLOG] ${userData['nickname']}님이 댓글을 달았습니다!",
                                    " ${_commentTextController.text}");
                              }
                              clearTextFieldAndHideKeyboard();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Image.asset(
                                'button/send_green.png',
                                width: 25,
                                height: 25,
                                color: const Color(0xFF62BC1B),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }
              }),
        );
      },
    );
  }
}

//import 'package:flog/notification/local_notification.dart';
import 'package:flutter/material.dart';
import 'package:flog/screen/profile/setting_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  // 유저 프로필 표시를 위해 필요한 생성자 작성해야함
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("User");

  // 닉네임 수정하기
  Future<void> editField(String field, String initialValue) async {
    String newValue = initialValue; // 힌트 텍스트로 사용할 초기값 설정
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // 모서리 둥글게
          ),
          backgroundColor: Colors.white,
          title: const Text(
            '닉네임을 수정하시겠어요?',
            style: TextStyle(color: Colors.black),
          ),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: initialValue,
              hintStyle: const TextStyle(color: Colors.grey),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF62BC1B), // 활성 상태의 밑줄 색상 변경
                ),
              ),
            ),
            onChanged: (value) {
              newValue = value;
            },
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      newValue = "";
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(15.0), // 모서리를 둥글게 설정
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
                    onPressed: () {
                      Navigator.of(context).pop(newValue);

                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<
                          RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                        ),
                      ),
                      backgroundColor:
                      MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                    ),
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
      ),
    );

    //파이어베이스 변경사항 업데이트하기
    if (newValue.trim().isNotEmpty) {
      await usersCollection.doc(currentUser.email).update({field: newValue});
    }
  }

  // 프로필 선택 및 변경하기
  Future<void> editImage(String field, String selectedImage) async {
    String newValue = selectedImage;
    int selectedIndex = int.tryParse(selectedImage) ?? -1; // 인덱스를 숫자로 다룸

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 40),
                      const Expanded(
                        child: Text(
                          '개구리 선택하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ),
                      TextButton(
                        onPressed: () { // '저장' 버튼을 눌렀을 때의 동작 추가
                          if (selectedIndex != -1) {
                            setState(() {
                              newValue = selectedIndex.toString();
                            }); // selectedIndex에 선택된 이미지의 인덱스가 저장되어 있음
                            debugPrint('선택된 이미지 인덱스: $selectedIndex');
                            Navigator.pop(context); // 모달 닫기
                          }
                        },
                        child: const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF62BC1B), // 버튼 텍스트 색상
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                      height: 400,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 3열로 배치
                          mainAxisSpacing: 5.0, // 수직 간격 설정
                          crossAxisSpacing: 5.0, // 수평 간격 설정
                          childAspectRatio: 1, // 가로:세로 비율을 1:1로 설정
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20), // GridView 내부 패딩 설정
                        itemCount: 12, // 이미지 버튼 개수
                        itemBuilder: (context, index) { // 각 이미지를 asset에서 불러오기
                          final imagePath = 'assets/profile/profile_$index.png'; // 이미지 버튼 반환
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.transparent, // 이미지 버튼의 배경색 설정
                              border: Border.all(
                                color: selectedIndex == index
                                    ? const Color(0xFF62BC1B) // 선택된 이미지의 테두리 색상
                                    : Colors.transparent, // 선택되지 않은 이미지는 테두리 없음
                                width: 2.0, // 테두리 두께
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                debugPrint('debug: 클릭됨');
                                setState(() {
                                  selectedIndex = index; // 선택된 이미지의 인덱스 업데이트
                                });
                              },
                              child: Image.asset(
                                imagePath, // 이미지 경로
                                fit: BoxFit.cover, // 이미지를 적절하게 조정
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ),
              ],
            );
          },
        );
      },
    );

    //파이어베이스 변경사항 업데이트하기
    if (newValue.trim().isNotEmpty) {
      await usersCollection.doc(currentUser.email).update({field: newValue});
    }
  }

  // 문의하기 메일 보내기
  void _sendEmail(String who, String id) async {
    final Email email = Email(
      body: '==================\n 프로그 사용에 관한 문의 사항을 작성해주세요! 빠른 시일 내에 답변드리겠습니다.\n\n문의 주시는 분 : $who, $id\n==================\n\n',
      subject: '[FLOG 문의]',
      recipients: ['holdup2023.ewha@gmail.com'],
      cc: [],
      bcc: [],
      attachmentPaths: [],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (error) {
      String title = "기본 메일 앱을 사용할 수 없기 때문에 앱에서 바로 문의를 전송하기 어려운 상황입니다.\n\n아래 이메일로 연락주시면 친절하게 답변해드릴게요 :)\n\nholdup2023.ewha@gmail.com";
      String message = "";
      _showErrorAlert(title: title, message: message);
    }
  }

  // 메일앱 사용 불가 시 알람창
  void _showErrorAlert({String? title, String? message}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0.0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300.0, maxHeight: 400.0), // 알람창 크기
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (title != null)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                if (title != null && message != null) const SizedBox(height: 10.0),
                if (message != null)
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13.0),
                  ),
                const SizedBox(height: 20.0),
                const Divider(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 화면 UI build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0.0, // 그림자 없음
        centerTitle: true,
        title:
        Text(
          'Profile',
          style: GoogleFonts.balooBhaijaan2(
            textStyle: const TextStyle(
              fontSize: 30,
              color: Color(0xFF62BC1B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings, // 프로필 편집 아이콘
              color: Colors.black, // 아이콘 색상
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection("User")
              .doc(currentUser.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if (snapshot.data == null || !snapshot.data!.exists) {
                return const Text('데이터 없음 또는 문서가 없음'); // Firestore 문서가 없는 경우 또는 데이터가 null인 경우 처리
              }
              // 이제 snapshot.data을 안전하게 사용할 수 있음
              Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
              // 데이터 처리
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ListView(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // 전체적으로 센터 정렬
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Hero(
                            tag: "profile",
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, //원 모양 프로필 사진
                                    color: Colors.grey[300], //배경색
                                  ),
                                  child: Center(
                                    child: ClipOval(
                                      child: Image.asset(
                                        "assets/profile/profile_${userData['profile']}.png",
                                        width: 100,
                                        height: 100,
                                        alignment: Alignment.center,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: Image.asset(
                                      'button/edit.png',
                                      width: 30,
                                      height: 30,
                                      color: const Color(0xFF62BC1B),
                                    ),
                                    onPressed: () => editImage('profile', userData['profile']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          child: Text(
                            userData['nickname'],
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF62BC1B)
                            ),
                          ),
                          onPressed: () =>
                              editField('nickname', userData['nickname']),
                        ),
                        Text(
                            userData['email'],
                            style: const TextStyle(fontSize: 15)
                        ),
                        const SizedBox(height: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Text('가족코드 복사하기',
                                  style: TextStyle(fontSize: 17)
                              ),
                              trailing: Row(
                                mainAxisSize:
                                MainAxisSize.min, // 아이콘과 텍스트를 최소 크기로 설정
                                children: [
                                  Text(
                                    userData['flogCode'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 15, // 아이콘 크기 조절
                                    color: Colors.black, // 아이콘 색상 설정
                                  ),
                                ],
                              ), // 화살표 아이콘 예시
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: userData['flogCode']));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${userData['nickname']}님의 가족 코드가 복사되었습니다! 가족들에게 공유해주세요.'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                            ),
                            const Divider(), // 분리선 추가
                            ListTile(
                              leading: const Text(
                                  '문의하기',
                                  style: TextStyle(fontSize: 17)
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 15, // 아이콘 크기 조절
                                color: Colors.black, // 아이콘 색상 설정
                              ), // 화살표 아이콘 예시
                              onTap: () {
                                _sendEmail(userData['nickname'], userData['email']);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              );
            }
          }),
    );
  }
}

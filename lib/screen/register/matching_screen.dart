import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flog/screen/register/matching_code_entering_screen.dart';
import 'package:flog/screen/register/matching_waiting_for_family.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';


class FamilyMatchingScreen extends StatefulWidget {
  final String nickname;
  const FamilyMatchingScreen({required this.nickname, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _FamilyMatchingScreenState();
}

class _FamilyMatchingScreenState extends State<FamilyMatchingScreen> {
  late String familycode;

  String? get uid => null;

  @override
  void initState() {
    super.initState();
    getFamilyCode();
  }

  Future<void> getFamilyCode() async {
    familycode = '';
    var random = Random();
    var leastcharindex = []; //꼭 들어가야 할 문자
    var skipCharacter = [
      //포함하지 않은 문자
      0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
      0x40, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60
    ];
    var min = 0x30; //사용할 아스키 문자 시작
    var max = 0x7A; //사용할 아스키 문자 마지막
    var code = []; //생성한 코드

    while (code.length <= 15) {
      //가족 코드는 15글자
      var tmp = min + random.nextInt(max - min); //랜덤으로 아스키 값 받기
      if (skipCharacter.contains(tmp)) {
        continue;
      }
      code.add(tmp);
    }

    while (leastcharindex.length < 3) {
      //특수문자, 숫자, 문자 섞기 위해 하나씩 지정하여 꼭 넣기
      var ran = random.nextInt(15);
      if (!leastcharindex.contains(ran)) {
        leastcharindex.add(ran);
      }
    }
    code[leastcharindex[0]] = 0x21; //!
    code[leastcharindex[1]] = 0x78; //x
    code[leastcharindex[2]] = 0x30; //0

    familycode = String.fromCharCodes(code.cast<int>());

    try {
      final CollectionReference groupListCollection =
          FirebaseFirestore.instance.collection('GroupList');

      // 'familyCode'를 저장할 새로운 문서를 추가합니다.
      await groupListCollection.doc(familycode).set({'flogCode': familycode});

      //print('Family code saved successfully.');
    } catch (e) {
      //print('Error saving family code: $e');
    }

    setState(() {
      familycode = familycode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/matching_screen_background.png"),
                  fit: BoxFit.cover, // 이미지를 화면에 꽉 채우도록 설정
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 400),
                  const Text(
                    '생성된 FLOG 코드',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    familycode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: familycode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.nickname}님의 가족 코드가 복사되었습니다!'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WaitingForFamily(familycode: familycode),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 0,
                      backgroundColor: Colors.white,
                      minimumSize: const Size(300, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'FLOG 코드 공유',
                      style: TextStyle(
                        color: Color(0xFF62BC1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MatchingCodeEnteringScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 0,
                      backgroundColor: const Color(0xFF62BC1B),
                      minimumSize: const Size(300, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'FLOG 코드 입력',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

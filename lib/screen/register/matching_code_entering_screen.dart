import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flog/models/model_auth.dart';
import 'package:flog/resources/auth_methods.dart';
import 'package:flog/screen/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchingCodeEnteringScreen extends StatefulWidget {
  const MatchingCodeEnteringScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EnteringState();
}

class _EnteringState extends State<MatchingCodeEnteringScreen> {
  TextEditingController codeController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white12,
        elevation: 0.0,
        leading: IconButton(
          icon: Image.asset('button/back_arrow.png', width: 20, height: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 10),
                Image.asset("assets/profile/profile_0.png", width: 50, height: 50),
                const SizedBox(width: 7),
                const Text(
                  'FLOG 코드를 입력해서 가족을 연결해주세요.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: 340,
                child: TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                      hintText: 'code',
                      hintStyle: TextStyle(
                          color: Colors.black12,
                          fontWeight: FontWeight.w900,
                          fontSize: 25,
                          fontStyle: FontStyle.italic),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF62BC1B)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black26))),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(

                onPressed: () async {
                  String enteredFamilycode = codeController
                      .text; //텍스트 필드에 입력된 가족코드 받아서 저장 - 파이어베이스에 넣을듯

                  final CollectionReference groupRef =
                      FirebaseFirestore.instance.collection('GroupList');
                  DocumentSnapshot docSnapshot =
                      await groupRef.doc(enteredFamilycode).get();

                  if (docSnapshot.exists && auth.currentUser != null) {
                    //그룹 등록하기
                    final authClient = Provider.of<FirebaseAuthProvider>(
                        context,
                        listen: false);
                    authClient.registerGroup(
                        enteredFamilycode, auth.currentUser!.email!);

                    //유저 정보 flogCode 업데이트
                    AuthMethods().updateUser(auth.currentUser!.email!,
                        'flogCode', enteredFamilycode);
                  } else if (docSnapshot.exists && auth.currentUser == null) {
                    //그룹 등록하기
                    final authClient = Provider.of<FirebaseAuthProvider>(
                        context,
                        listen: false);
                    authClient.registerGroup(
                        enteredFamilycode, "currentUser가 NULL입니다.");

                    //유저 정보 flogCode 업데이트
                    AuthMethods().updateUser(
                        "currentUser가 NULL입니다.", 'flogCode', enteredFamilycode);
                  } else {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                          const SnackBar(content: Text('flogCode를 다시 확인하여주세요!')));
                    return;
                  }

                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        //다음 스크린으로 가족코드 전달되는지 확인 위해 매개변수로 전달
                        builder: (context) =>
                            RootScreen(matchedFamilycode: enteredFamilycode)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 0,
                  backgroundColor: const Color(0xFF62BC1B),
                  minimumSize: const Size(300, 50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  '완료',
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
    );
  }
}

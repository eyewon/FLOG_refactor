import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flog/models/model_auth.dart';
import 'package:flog/models/model_login.dart';
import 'package:flog/screen/register/matching_screen.dart';
import 'package:flog/screen/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginFieldModel(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black, // 뒤로가기 버튼 아이콘 색상
            ), // 이미지 경로 지정
            onPressed: () {
              Navigator.pop(context); // 뒤로가기 기능 추가
            },
          ),
          title: const Text(
            '로그인',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold, // 굵게 설정
            ),
          ),
          backgroundColor: Colors.transparent, // 투명 설정
          elevation: 0, // 그림자 제거
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 세로 중간 정렬
            children: [
              Image.asset(
                "assets/flog_name_3d.png",
                width: 180,
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft, // 좌측 정렬
                child: Padding(
                  padding: EdgeInsets.only(left: 65.0), // 좌측으로 20.0만큼 패딩 추가
                  child: Text(
                    '계정에 로그인하세요.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold, // 굵게 설정
                    ),
                  ),
                ),
              ),
              const EmailInput(),
              const PasswordInput(),
              const SizedBox(height: 10),
              const LoginButton(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, // 수직 가운데 정렬
                  children: [
                    Text(
                      '아직 계정이 없으신가요?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10), // 원하는 간격을 설정
                    SignUpButton(),
                  ],
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}

class EmailInput extends StatelessWidget {
  const EmailInput({super.key});

  @override
  Widget build(BuildContext context) {
    final loginField = Provider.of<LoginFieldModel>(context, listen: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      width: MediaQuery.of(context).size.width * 0.8,
      child: TextField(
        onChanged: (email) {
          loginField.setEmail(email);
        },
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'Email', // Hint Text
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)), // 네모 상자의 모서리 둥글기 설정
            borderSide: BorderSide(color: Colors.grey), // 테두리 색 설정
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12), // 내용 안의 패딩 조정
          hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // 힌트 텍스트 스타일
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(color: Color(0xFF62BC1B), width: 2.0
            ), // 선택됐을 때 테두리 색 변경
          ),

        ),
      ),
    );
  }
}

class PasswordInput extends StatelessWidget {
  const PasswordInput({super.key});

  @override
  Widget build(BuildContext context) {
    final loginField = Provider.of<LoginFieldModel>(context, listen: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      width: MediaQuery.of(context).size.width * 0.8,
      child: TextField(
        onChanged: (password) {
          loginField.setPassword(password);
        },
        obscureText: true,
        decoration: const InputDecoration(
          hintText: 'Password', // Hint Text
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(10.0)), // 네모 상자의 모서리 둥글기 설정
            borderSide: BorderSide(color: Colors.grey), // 테두리 색 설정
          ),
          contentPadding:
              EdgeInsets.symmetric(vertical: 12, horizontal: 12), // 내용 안의 패딩 조정
          hintStyle: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold), // 힌트 텍스트 스타일
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(
                color: Color(0xFF62BC1B), width: 2.0), // 선택됐을 때 테두리 색 변경
          ),
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authClient =
        Provider.of<FirebaseAuthProvider>(context, listen: false);
    final loginField = Provider.of<LoginFieldModel>(context, listen: false);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.height * 0.05,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF62BC1B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        onPressed: () async {
          await authClient
              .loginWithEmail(loginField.email, loginField.password)
              .then((loginStatus) async {
            if (loginStatus == AuthStatus.loginSuccess) {
              // 유저의 flogCode 가져오기
              final CollectionReference usersCollection =
                  FirebaseFirestore.instance.collection('User');
              DocumentSnapshot userDocument =
                  await usersCollection.doc(loginField.email).get();
              String flogCode = userDocument.get('flogCode');
              if (flogCode == "null") {
                //flogCode가 없는경우(가족 등록 안된 신규 유저)
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Text('${authClient.user!.email!}님 환영합니다!')));
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FamilyMatchingScreen(
                            nickname: authClient.user!.email!)));
              } else {
                // flogCode가 있는경우(가족 등록된 기존 유저)
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Text('${authClient.user!.email!}님 환영합니다!')));
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            RootScreen(matchedFamilycode: flogCode)));
              }
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text("로그인에 실패했습니다. 다시 시도해주세요.")),
                );
            }
          });
        },
        child: const Text(
          '로그인 하기',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold, // 굵게 설정
          ),
        ),
      ),
    );
  }
}

class SignUpButton extends StatelessWidget {
  const SignUpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/register');
        },
        child: Text(
          'Sign Up',
          style: TextStyle(color: theme.primaryColor),
        ));
  }
}

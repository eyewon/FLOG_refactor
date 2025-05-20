import 'package:flog/models/model_auth.dart';
import 'package:flog/models/model_register.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterFieldModel(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black, // 뒤로가기 버튼 아이콘 색상
            ),// 이미지 경로 지정
            onPressed: () {
              Navigator.pop(context); // 뒤로가기 기능 추가
            },
          ),
          title: const Text('회원가입',
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
                const SizedBox(height: 90),
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
                      '계정을 생성하세요.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold, // 굵게 설정
                      ),
                    ),
                  ),
                ),
                const EmailInput(),
                const PasswordInput(),
                const PasswordConfirmInput(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BirthInput(),
                    SizedBox(width: 10),
                    NicknameInput()
                  ],
                ),
                const SizedBox(height: 10),
                const ReisterButton(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center, // 수직 가운데 정렬
                    children: [
                      Text(
                        '이미 계정이 있으신가요?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10), // 원하는 간격을 설정
                      SignInButton(),
                    ],
                  ),
                ),
              ],
            ),
        ),
        resizeToAvoidBottomInset: true,
      ),
    );
  }
}

class EmailInput extends StatelessWidget {
  const EmailInput({super.key});

  @override
  Widget build(BuildContext context) {
    final registerField =
        Provider.of<RegisterFieldModel>(context, listen: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      width: 340,
      child: TextField(
        onChanged: (email) {
          registerField.setEmail(email);
        },
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email', // Hint Text
          hintText: 'example@example.com',
          labelStyle: TextStyle(
            color: Colors.grey, // labelText 색상 변경
            fontWeight: FontWeight.bold,
          ),
          hintStyle: TextStyle(
            color: Colors.grey, // hintText 색상 변경
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)), // 네모 상자의 모서리 둥글기 설정
            borderSide: BorderSide(color: Colors.grey), // 테두리 색 설정
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12), // 내용 안의 패딩 조정
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(color: Color(0xFF609966), width: 2.0), // 선택됐을 때 테두리 색 변경
          ),
        ),
      ),
    );
  }
}

class PasswordInput extends StatefulWidget {
  const PasswordInput({super.key});

  @override
  PasswordInputState createState() => PasswordInputState();
}

class PasswordInputState extends State<PasswordInput> {
  final TextEditingController _pwcontroller = TextEditingController();
  String _errorText = '';

  @override
  void dispose() {
    _pwcontroller.dispose();
    super.dispose();
  }

  void _validateInput(String password) {
    if (password.length < 8) {
      setState(() {
        _errorText = '비밀번호는 8자 이상이어야 합니다.';
      });
    } else {
      setState(() {
        _errorText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerField =
        Provider.of<RegisterFieldModel>(context, listen: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      width: 340,
      child: TextField(
        controller: _pwcontroller,
        onChanged: (password) {
          _validateInput(password);
          registerField.setPassword(password);
        },
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password', // Hint Text
          hintText: '8자 이상 입력해주세요.',
          labelStyle: const TextStyle(
            color: Colors.grey, // labelText 색상 변경
            fontWeight: FontWeight.bold,
          ),
          hintStyle: const TextStyle(
            color: Colors.grey, // hintText 색상 변경
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)), // 네모 상자의 모서리 둥글기 설정
            borderSide: BorderSide(color: Colors.grey), // 테두리 색 설정
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), // 내용 안의 패딩 조정
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(color: Color(0xFF609966), width: 2.0), // 선택됐을 때 테두리 색 변경
          ),
          errorText: _errorText.isNotEmpty ? _errorText : null,
        ),
      ),
    );
  }
}

class PasswordConfirmInput extends StatelessWidget {
  const PasswordConfirmInput({super.key});

  @override
  Widget build(BuildContext context) {
    final registerField =
        Provider.of<RegisterFieldModel>(context); // listen == true
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      width: 340,
      child: TextField(
        onChanged: (password) {
          registerField.setPasswordConfirm(password);
        },
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password Confirm', // Hint Text
          hintText: '비밀번호를 다시 입력해주세요.',
          labelStyle: const TextStyle(
            color: Colors.grey, // labelText 색상 변경
            fontWeight: FontWeight.bold,
          ),
          hintStyle: const TextStyle(
            color: Colors.grey, // hintText 색상 변경
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)), // 네모 상자의 모서리 둥글기 설정
            borderSide: BorderSide(color: Colors.grey), // 테두리 색 설정
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), // 내용 안의 패딩 조정
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(color: Color(0xFF609966), width: 2.0), // 선택됐을 때 테두리 색 변경
          ),
          errorText: registerField.password != registerField.passwordConfirm
              ? "비밀번호가 일치하지 않습니다."
              : null,
        ),
        ),
    );
  }
}

class NicknameInput extends StatelessWidget {
  const NicknameInput({super.key});

  @override
  Widget build(BuildContext context) {
    final registerField = Provider.of<RegisterFieldModel>(context, listen: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 5, 20, 5),
      width: 165,
      child: TextField(
        onChanged: (nickname) {
          registerField.setNickname(nickname);
        },
        decoration: const InputDecoration(
          labelText: 'Nickname', // Hint Text
          hintText: '닉네임을 입력',
          labelStyle: TextStyle(
            color: Colors.grey, // labelText 색상 변경
            fontWeight: FontWeight.bold,
          ),
          hintStyle: TextStyle(
            color: Colors.grey, // hintText 색상 변경
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)), // 네모 상자의 모서리 둥글기 설정
            borderSide: BorderSide(color: Colors.grey), // 테두리 색 설정
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12), // 내용 안의 패딩 조정
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(color: Color(0xFF609966), width: 2.0), // 선택됐을 때 테두리 색 변경
          ),
        ),
      ),
    );
  }
}

class BirthInput extends StatefulWidget {
  const BirthInput({super.key});

  @override
  BirthInputState createState() => BirthInputState();
}

class BirthInputState extends State<BirthInput> {
  final TextEditingController _birthcontroller = TextEditingController();
  String _errorText = '';

  @override
  void dispose() {
    _birthcontroller.dispose();
    super.dispose();
  }

  void _validateInput(String input) {
    if (input.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(input)) {
      setState(() {
        _errorText = '숫자 6자리로 입력해주세요.';
      });
    } else {
      setState(() {
        _errorText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerField =
        Provider.of<RegisterFieldModel>(context, listen: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 0, 5),
      width: 165,
      child: TextField(
        controller: _birthcontroller,
        onChanged: (birth) {
          _validateInput(birth);
          registerField.setBirth(birth);
        },
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Birth', // Hint Text
          hintText: 'YYMMDD 형식',
          labelStyle: const TextStyle(
            color: Colors.grey, // labelText 색상 변경
            fontWeight: FontWeight.bold,
          ),
          hintStyle: const TextStyle(
            color: Colors.grey, // hintText 색상 변경
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)), // 네모 상자의 모서리 둥글기 설정
            borderSide: BorderSide(color: Colors.grey), // 테두리 색 설정
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), // 내용 안의 패딩 조정
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(color: Color(0xFF609966), width: 2.0), // 선택됐을 때 테두리 색 변경
          ),
          errorText: _errorText.isNotEmpty ? _errorText : null,
        ),
      ),
    );
  }
}

class ReisterButton extends StatelessWidget {
  const ReisterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authClient = Provider.of<FirebaseAuthProvider>(context, listen: false);
    final registerField = Provider.of<RegisterFieldModel>(context, listen: false);
    return SizedBox(
      width: 300,
      height: 45,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF62BC1B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
          onPressed: () async {
            await authClient
                .registerWithEmail(registerField.email, registerField.password,
                    registerField.nickname, registerField.birth)
                .then((registerStatus) {
              if (registerStatus == AuthStatus.registerSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('회원가입이 완료되었습니다!')),
                  );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('회원가입을 실패했습니다. 다시 시도해주세요.')),
                  );
              }
            });
          },
          child: const Text(
            '회원가입 하기',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold, // 굵게 설정
            ),
          ),
      ),
    );
  }
}

class SignInButton extends StatelessWidget {
  const SignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(
          'Sign In',
          style: TextStyle(color: theme.primaryColor),
        ));
  }
}

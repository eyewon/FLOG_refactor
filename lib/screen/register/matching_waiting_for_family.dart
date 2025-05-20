import 'package:flutter/material.dart';

class WaitingForFamily extends StatefulWidget {
  final String familycode;
  const WaitingForFamily({required this.familycode, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WaitingState();
}

class _WaitingState extends State<WaitingForFamily>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white10,
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
                  'FLOG 코드를 가족에게 공유하여\n가족 그룹에 들어오라고 알려주세요!',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.familycode,
                  style: const TextStyle(
                      fontSize: 35, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flog/screen/register/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: null,
        body: SafeArea(
            child: Center(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/splash.png'),
                    fit: BoxFit.cover, // 이미지를 화면에 꽉 채우도록 설정
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 600),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),

                        ),
                        side: BorderSide(color: Color(0xff62BC1B),
                        width: 4.0),
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        minimumSize: const Size(300, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'START',
                        style: GoogleFonts.balooBhaijaan2(
                          textStyle: const TextStyle(
                            fontSize: 25,
                            color: Color(0xff62BC1B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
        ),
      ),
    );
  }
}
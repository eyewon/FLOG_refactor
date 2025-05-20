import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MemoryBoxVideoScreen extends StatefulWidget {
  @override
  MemoryBoxVideoState createState() => MemoryBoxVideoState();
}

class MemoryBoxVideoState extends State<MemoryBoxVideoScreen> {
  VideoPlayerController? _controller;
  // Firestore 인스턴스 생성
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  String currentUserFlogCode = ""; // 현재 로그인한 사용자의 flogCode

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 사용자의 flogCode를 가져오고 데이터를 초기화하는 함수
  Future<void> _initializeData() async {
    await getUserFlogCode(); // 사용자의 flogCode를 가져옴
    await _initializeController(); // VideoPlayerController 초기화
  }

  // 현재 로그인한 사용자의 flogCode를 Firebase에서 가져오는 함수
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

  Future<void> _initializeController() async {
    try {
      // Firebase에서 현재 사용자의 flogcode와 일치하는 데이터만 가져오기
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Group')
          .where('flogCode', isEqualTo: currentUserFlogCode)
          .get();

      // 가져온 데이터에서 동영상 URL 가져오기
      final String videoUrl = snapshot.docs.first['videoUrl'] as String;

      setState(() {
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      });

      // VideoPlayerController 초기화를 위해 await 사용
      await _controller!.initialize();

      setState(() {
        // 초기화가 완료되면 setState를 통해 UI를 갱신
      });
    } catch (e) {
      print("Error initializing video controller: $e");
      // 에러 처리를 원하는 대로 추가
    }
  }




  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month;
    return Scaffold(
      /*---상단 Memory Box 바---*/
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
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const SizedBox(width: 35),
            const SizedBox(width: 10),
            Text('Memory Box',
                style: GoogleFonts.balooBhaijaan2(
                    textStyle: TextStyle(
                      fontSize: 30,
                      color: Color(0xff62BC1B),
                      fontWeight: FontWeight.bold,
                    ))),
          ],
        ),
        elevation: 0.0, //그림자 없음
        centerTitle: true,
      ),
      /*---화면---*/
      backgroundColor: Colors.white, //화면 배경색

      body: Column(
        children: [
          SizedBox(height: 70),
          Center(
            child:

            Container(
              margin: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white, width: 1.5),
                color: Colors.transparent,
              ),
              child: Center(
                child: _controller != null
                    ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                )
                    : Container(
                  color: Colors.transparent,
                  width: 10,
                  height: 100,
                  child: SpinKitPumpingHeart(
                    color: Colors.green.withOpacity(0.2),
                    size: 50.0, //크기 설정
                    duration: const Duration(seconds: 3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              '$currentMonth월 우리 가족의 모습을',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '영상으로 만나보세요!',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Wrap the play or pause in a call to `setState`. This ensures the
            // correct icon is shown.
            setState(() {
              // If the video is playing, pause it.
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                // If the video is paused, play it.
                _controller!.play();
              }
            });
          },
          // Display the correct icon depending on the state of the player.
          backgroundColor: Color(0xff62BC1B),
          child: Icon(
            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        )
    );
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }
}


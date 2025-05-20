import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flog/screen/memorybox/memorybox_book_screen.dart';
import 'package:flog/screen/memorybox/memorybox_detail_screen.dart';
import 'package:flog/screen/memorybox/memorybox_everyday_showall_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/member_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'memorybox_valuableday_showall_screen.dart';
import 'memorybox_video_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MemoryBoxScreen extends StatefulWidget {
  const MemoryBoxScreen({Key? key}) : super(key: key);

  @override
  MemoryBoxState createState() => MemoryBoxState();
}

class MemoryBoxState extends State<MemoryBoxScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  String currentUserFlogCode = ""; // 현재 로그인한 사용자의 flogCode

  int frog = 0;
  int coinNum = 1;

  @override
  void initState() {
    super.initState();
    getUserFlogCode();
  }

  //현재 로그인한 사용자의 flogCode를 Firestore에서 가져오는 함수
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
    //print(currentUserFlogCode);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('User').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

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
        }

        final documents = snapshot.data!.docs;
        final profiles = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['flogCode'] == currentUserFlogCode;
        }).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Person(
            profileNum: data['profile'],
            nickname: data['nickname'],
          );
        }).toList();

        return StreamBuilder<QuerySnapshot> (
            stream: FirebaseFirestore.instance.collection('Group').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center( //로딩바 구현 부분
                    child: SpinKitPumpingHeart(
                      color: Colors.green.withOpacity(0.2),
                      size: 50.0, //크기 설정
                      duration: const Duration(seconds: 5),
                    ),
                  ),
                );
              }

              final documents = snapshot.data!.docs;
              documents.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['flogCode'] == currentUserFlogCode;
              }).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                frog = data['frog'];
                return frog;
              }).toList();

              return Scaffold(
                /*---상단 Memory Box 바---*/
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  elevation: 0.0, // 그림자 없음
                  centerTitle: true,
                  title: Text(
                    'Memory Box',
                    style: GoogleFonts.balooBhaijaan2(
                      textStyle: const TextStyle(
                        fontSize: 30,
                        color: Color(0xFF62BC1B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                /*---화면---*/
                backgroundColor: Colors.white, //화면 배경색
                body: ListView(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 20, right: 10, left: 10),
                      child: Container(
                        height: 200,
                        width: 390,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1), // 그림자의 색상
                              spreadRadius: 3, // 그림자가 퍼지는 정도
                              blurRadius: 2, // 그림자의 흐림 정도
                              offset: const Offset(0, 1), // 그림자의 위치 (가로, 세로)
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    for (final profile in profiles)
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Person(
                                          profileNum: profile.profileNum,
                                          nickname: profile.nickname,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            flogCoinNum(),
                          ],
                        ),
                      ),
                    ),
                    ourEveryday(),
                    ourValuableday(),
                    const SizedBox(height: 20)
                  ],
                ),
              );
            }
        );
      },
    );
  }

  
  //모은 개구리 수 보여주기
  Widget flogCoinNum() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 10),
        Image.asset(
          "assets/flog_coin_green.png",
          width: 30,
          height: 30,
        ),
        const SizedBox(width: 10),
        Text(
          '모은 개구리수 : $frog마리',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ],
    );
  }

  // 이 함수는 위젯 안에 추가됩니다.
  Widget ourEveryday() {
    final now = DateTime.now(); // 현재 날짜와 시간
    final startDate = DateTime(now.year, now.month, now.day - 13); // 오늘부터 13일 이전의 날짜 계산

    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 10, left: 10),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1), // 그림자의 색상
              spreadRadius: 3, // 그림자가 퍼지는 정도
              blurRadius: 2, // 그림자의 흐림 정도
              offset: const Offset(0, 1), // 그림자의 위치 (가로, 세로)
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '우리의 모든 날',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: 350,
              decoration: BoxDecoration(
                color: const Color(0xffd6d6d6).withOpacity(0.4),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Flexible(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 10.0,
                      ),
                      itemCount: 14, // 14일간의 날짜 수
                      itemBuilder: (BuildContext context, int index) {
                        final currentDate = startDate.add(Duration(days: index));
                        final containerNumber = currentDate.day;
                        final formattedDate = DateFormat('yy.MM.dd').format(currentDate);

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MemoryBoxDetailScreen(
                                  selectedDate: formattedDate,
                                ),
                              ),
                            );
                          },
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Floging')
                                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(currentDate))
                                .where('date', isLessThan: Timestamp.fromDate(currentDate.add(const Duration(days: 1))))
                                .where('flogCode', isEqualTo: currentUserFlogCode)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }

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
                              }

                              final flogDocuments = snapshot.data?.docs ?? [];

                              if (flogDocuments.isEmpty) {
                                return Container(
                                  margin: const EdgeInsets.all(3.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    containerNumber.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700
                                    ),
                                  ),
                                );
                              }

                              // 가져온 플로깅 사진을 사용하여 이미지 컨테이너를 생성하고 반환
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => MemoryBoxDetailScreen(
                                        selectedDate: formattedDate,
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    ..._buildFlogImageContainers(flogDocuments), // 플로깅 사진을 추가
                                    Center(
                                      child: Text(
                                        containerNumber.toString(),
                                        style: const TextStyle(color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 133),
                      OutlinedButton(
                        onPressed: () { // "전체 보기" 버튼 클릭 시 동작
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MemoryBoxEverydayShowAllScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 2.0, color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          '전체 보기',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 80),
                      InkWell(
                        onTap: () {
                          //자동 영상 생성
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MemoryBoxVideoScreen(),
                            ),
                          );
                        },
                        child: Image.asset(
                          "button/video.png",
                          width: 35,
                          height: 35,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }


  Widget ourValuableday() {

    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 10, left: 10),
      child: Container(
        height: 310,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1), // 그림자의 색상
              spreadRadius: 3, // 그림자가 퍼지는 정도
              blurRadius: 2, // 그림자의 흐림 정도
              offset: const Offset(0, 1), // 그림자의 위치 (가로, 세로)
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '우리의 소중한 날',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            Container(
              height: 250,
              width: 350,
              decoration: BoxDecoration(
                color: const Color(0xffd6d6d6).withOpacity(0.4),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Qpuzzle')
                          .where('flogCode', isEqualTo: currentUserFlogCode)
                          .where('isComplete', isEqualTo : true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Scaffold(
                            body: Center( // 로딩바 구현 부분
                              child: SpinKitPumpingHeart(
                                color: Colors.green.withOpacity(0.2),
                                size: 50.0, // 크기 설정
                                duration: const Duration(seconds: 3), // 속도 설정
                              ),
                            ),
                            backgroundColor: Colors.transparent, // 투명 배경 설정
                          );

                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              '어서 큐퍼즐을 완성해보세요!',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black38,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          );
                        }

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.0 / 3.0,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (BuildContext context, int index) {
                            final imagePath = docs[index]['pictureUrl'];

                            return Container(
                              margin: const EdgeInsets.all(3.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white, width: 2),
                                color: const Color(0x70ffffff),
                                image: DecorationImage(
                                  image: NetworkImage(imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 133),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MemoryBoxValuabledayShowAllScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 2.0, color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          '전체 보기',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 80),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MemoryBoxBookScreen(),
                            ),
                          );
                        },
                        child: Image.asset(
                          "button/book.png",
                          width: 35,
                          height: 35,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFlogImageContainers(List<DocumentSnapshot> flogDocuments) {
    List<Widget> imageContainers = [];

    double radius = 20 * 0.5;

    if (flogDocuments.length == 1) { // flogDocuments의 길이가 1인 경우, 동그라미를 센터에 놓음
      final flogData = flogDocuments[0].data() as Map<String, dynamic>;
      final backImageURL = flogData['downloadUrl_back'];

      imageContainers.add(
        Center(
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xffd6d6d6),
              image: DecorationImage(
                image: NetworkImage(backImageURL),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    } else if (flogDocuments.length == 2) { // flogDocuments의 길이가 2인 경우, 대각선으로 배치
      final flogData1 = flogDocuments[0].data() as Map<String, dynamic>;
      final flogData2 = flogDocuments[1].data() as Map<String, dynamic>;

      final backImageURL1 = flogData1['downloadUrl_back'];
      final backImageURL2 = flogData2['downloadUrl_back'];

      imageContainers.add(
        Positioned(
          left: 8, // 왼쪽 상단에 배치
          top: 8,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xffd6d6d6),
              image: DecorationImage(
                image: NetworkImage(backImageURL1),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );

      imageContainers.add(
        Positioned(
          right: 8, // 오른쪽 하단에 배치
          bottom: 8,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xffd6d6d6),
              image: DecorationImage(
                image: NetworkImage(backImageURL2),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    } else { // flogDocuments의 길이가 3 이상인 경우, 세잎 클로버 모양으로 배치
      for (int i = 0; i < flogDocuments.length; i++) {
        double angle = (-pi / 2) + (2 * pi / flogDocuments.length) * i; // 정삼각형의 각도 계산

        double centerX = radius * cos(angle) + radius; // 중점 x 좌표 계산
        double centerY = radius * sin(angle) + radius; // 중점 y 좌표 계산

        final flogData = flogDocuments[i].data() as Map<String, dynamic>;
        final backImageURL = flogData['downloadUrl_back'];

        imageContainers.add(
          Positioned(
            left: centerX + 5, // 이미지 컨테이너 중점 기준으로 x 좌표 조절
            top: centerY + 5, // 이미지 컨테이너 중점 기준으로 y 좌표 조절
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffd6d6d6),
                image: DecorationImage(
                  image: NetworkImage(backImageURL),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      }
    }
    return imageContainers;
  }
}

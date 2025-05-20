import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'memorybox_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoryBoxEverydayShowAllScreen extends StatelessWidget {
  const MemoryBoxEverydayShowAllScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Row(
          children: [
            SizedBox(width: 105),
            Text(
              '모든 날',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 0.0, //그림자 없음
        centerTitle: true,
      ),
      body: const Center(
        child: SafeArea(
          child: Column(
              children: [
                SizedBox(height: 25), //간격
                MemoryBoxInfiniteCalendar(),
              ]
          ),
        ),
      ),
    );
  }
}

class MemoryBoxInfiniteCalendar extends StatefulWidget {
  const MemoryBoxInfiniteCalendar({Key? key}) : super(key: key);

  @override
  MemoryBoxInfiniteCalendarState createState() => MemoryBoxInfiniteCalendarState();
}

class MemoryBoxInfiniteCalendarState extends State<MemoryBoxInfiniteCalendar> {
  late PageController _pageController;
  late DateTime _currentDate;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  String currentUserFlogCode = ""; // 현재 로그인한 사용자의 flogCode

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _pageController = PageController(initialPage: 100); //100개월(=8년 4개월정도..)까지 저장 가능
    getUserData();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentDate = DateTime.now().add(Duration(days: (page - 99) * 30));
    });
  }

  Future<void> getUserData() async {
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
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged, //페이지가 변경될 때 호출
        itemCount: 100,
        itemBuilder: (BuildContext context, int page) {
          final currentDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
          return _buildMonthCalendar(currentDate.year, currentDate.month);
        },
      ),
    );
  }

  Widget _buildMonthCalendar(int year, int month) {
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    int today = DateTime.now().day; //해당 월의 첫 번째 날 요일 가져오기(1: 월요일, 7: 일요일)
    int firstDayOfWeek = DateTime(year, month, 1).weekday; //일요일(7)을 1로 변경
    if (firstDayOfWeek == 7) {
      firstDayOfWeek = 1;
    } else {
      firstDayOfWeek++;
    }

    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          DateFormat('yyyy.MM').format(DateTime(year, month)),
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 30),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(width: 32),
            Text(
              "일",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5),
            Text(
                "월",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5),
            Text(
                "화",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5),
            Text(
                "수",
              style: TextStyle(
                color: Colors.black,
                 fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5),
            Text(
                "목",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5),
            Text(
                "금",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5),
            Text(
                "토",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 33),
          ],
        ),
        const SizedBox(height: 20),
        _buildGrid(year, month, daysInMonth, today, firstDayOfWeek),
      ],
    );
  }

  Widget _buildGrid(int year, int month, int daysInMonth, int today, int firstDayOfWeek) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    return Container(
      height: 350,
      width: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 10.0,
        ),
        itemCount: daysInMonth + firstDayOfWeek - 1, // 첫 번째 날 이전의 빈 칸도 포함
        itemBuilder: (BuildContext context, int index) {
          if (index < firstDayOfWeek - 1) {
            // 첫 번째 날 이전의 빈 날짜 칸
            return Container();
          }

          final containerNumber = index - firstDayOfWeek + 2;
          final day = containerNumber.toString().padLeft(2, '0');
          final formattedMonth = month.toString().padLeft(2, '0');
          final formattedYear = year%100;
          final formattedDate = '$formattedYear.$formattedMonth.$day';

          if ((year == currentYear && month == currentMonth && containerNumber > today) ||
              (year == currentYear && month > currentMonth) || (year > currentYear)) {
            //현재 월 이후의 날짜인 경우 회색에 숫자만 적힌 빈 컨테이너
            return GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.all(3.0),
                alignment: Alignment.center,
                child: Text(
                  containerNumber.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          } else {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Floging')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(year, month, containerNumber)))
                  .where('date', isLessThan: Timestamp.fromDate(DateTime(year, month, containerNumber + 1)))
                  .where('flogCode', isEqualTo: currentUserFlogCode)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Error: ${snapshot.error}');
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      //로딩바 구현 부분
                      child: SpinKitPumpingHeart(
                        color: Colors.green.withOpacity(0.2),
                        size: 40.0, //크기 설정
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
                        color: Colors.grey,
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
            );
          }
        },
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
    } else if (flogDocuments.length == 2) {
      // flogDocuments의 길이가 2인 경우, 대각선으로 배치
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
    } else {
      // flogDocuments의 길이가 3 이상인 경우, 세잎 클로버 모양으로 배치
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


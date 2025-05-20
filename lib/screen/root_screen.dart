//Bottom Navigation Bar와 Tab Bar View 구현 위함
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flog/screen/floging/floging_screen.dart';
import 'package:flog/screen/floging/shooting_screen_back.dart';
import 'package:flog/screen/qpuzzle/qpuzzle_screen.dart';
import 'package:flog/screen/memorybox/memorybox_screen.dart';
import 'package:flog/screen/profile/profile_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


class RootScreen extends StatefulWidget {
  final String matchedFamilycode;
  const RootScreen({required this.matchedFamilycode, Key? key}) : super(key: key);

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  final currentUser = FirebaseAuth.instance.currentUser!;

  final _pages = const [
    FlogingScreen(),
    QpuzzleScreen(),
    MemoryBoxScreen(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {

    //print('개발 중 확인용 - ${widget.matchedFamilycode}의 가족');
    return WillPopScope(
      onWillPop: () async => false,
      child:
        Scaffold(
          body: _pages[_currentIndex], 
          bottomNavigationBar: BottomTabBar(
           currentIndex: _currentIndex,
           onTabTapped: (index) {
             setState(() {
               _currentIndex = index;
             });
           },
         ),
          floatingActionButton: //Floating + 버튼 - shooting
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                .collection("User")
                .doc(currentUser.email)
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    //로딩바 구현 부분
                    child: SpinKitPumpingHeart(
                      color: Colors.green.withOpacity(0.2),
                      size: 50.0, //크기 설정
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  if (snapshot.data == null || !snapshot.data!.exists) {
                    return const Text('데이터 없음 또는 문서가 없음'); // Firestore 문서가 없는 경우 또는 데이터가 null인 경우 처리
                  }
                }
                Map<String, dynamic> userData =
                snapshot.data!.data() as Map<String, dynamic>;
                return SizedBox(
                  width: 70, // 원하는 너비
                  height: 70, // 원하는 높이
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF62BC1B),
                    onPressed: () { // 버튼 클릭 시 동작
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShootingScreen(),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 12,
                          left: 4,
                          child: Image.asset(
                            "assets/profile/profile_${userData['profile']}.png",
                            width: 60,
                            height: 60,
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Image.asset(
                                "button/plus.png",
                                width: 13,
                                height: 13,
                                color: const Color(0xFF62BC1B),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
    );
  }
}

class BottomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const BottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTabTapped,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('button/floging_line.png', width: 30, height: 30),
          activeIcon: Image.asset('button/floging_fill.png', width: 30, height: 30, color: const Color(0xFF62BC1B)),
          label: 'Floging',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('button/qpuzzle_line.png', width: 30, height: 30),
          activeIcon: Image.asset('button/qpuzzle_fill.png', width: 30, height: 30, color: const Color(0xFF62BC1B)),
          label: 'Qpuzzle',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('button/memorybox_line.png', width: 30, height: 30),
          activeIcon: Image.asset('button/memorybox_fill.png', width: 30, height: 30, color: const Color(0xFF62BC1B)),
          label: 'memory box',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('button/profile_line.png', width: 30, height: 30),
          activeIcon: Image.asset('button/profile_fill.png', width: 30, height: 30, color: const Color(0xFF62BC1B)),
          label: 'setting',
        ),
      ],
    );
  }
}
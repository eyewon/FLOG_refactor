import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class MemoryBoxBookScreen extends StatefulWidget {
  const MemoryBoxBookScreen({Key? key}) : super(key: key);

  @override
  MemoryBoxBookState createState() => MemoryBoxBookState();
}
class MemoryBoxBookState extends State<MemoryBoxBookScreen> {
  bool isMaking = false;
  String currentUserFlogCode = ""; // 현재 로그인한 사용자의 flogCode
  int memoryBookNo = 0;

  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    getUserFlogCode();
    getisMaking();
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

  Future<void> getisMaking() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('Group')
        .doc(currentUserFlogCode)
        .get();

    if (groupDoc.exists) {
      setState(() {
        isMaking = groupDoc.data()!['isMaking'];
      });
    }

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*---상단 Memory Box 바---*/
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context); // 뒤로가기 기능 추가
          },
        ),
        backgroundColor: Colors.white,
        title: Text('Memory Box',
            style: GoogleFonts.balooBhaijaan2(
                textStyle: const TextStyle(
                  fontSize: 30,
                  color: Color(0xFF62BC1B),
                  fontWeight: FontWeight.bold,
                ),
            ),
        ),
        elevation: 0.0, //그림자 없음
        centerTitle: true,
      ),
        /*---화면---*/
        backgroundColor: Colors.white, //화면 배경색
        body: Column(
          children: [
            const SizedBox(height: 70),
            const Center(
                child: Text(
                  '가족들의 소중한 사진을\n오프라인으로 만나보세요!',
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
            ),
            const SizedBox(height: 30),
            Image.asset(
              "assets/memory_book.png",
              width: 250, height: 250,
            ),
            const SizedBox(height: 40),
            StreamBuilder<QuerySnapshot> (
                stream: FirebaseFirestore.instance.collection('Group').snapshots(),
                builder: (context, snapshot) {
                  if(snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if(snapshot.connectionState == ConnectionState.waiting){
                    return Center( //로딩바 구현 부분
                        child: SpinKitPumpingHeart(
                          color: Colors.green.withOpacity(0.2),
                          size: 50.0, //크기 설정
                          duration: const Duration(seconds: 5),
                        ),
                    );
                  }
                  final documents = snapshot.data!.docs;
                  documents.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['flogCode'] == currentUserFlogCode;
                  }).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    memoryBookNo = data['memoryBookNo'];
                    isMaking = data['isMaking'];
                  }).toList();
                  return ElevatedButton(
                    //추억북 신청하기 버튼을 누르면
                    onPressed: !isMaking ? () async{
                      setState(() {
                        memoryBookNo = memoryBookNo + 1;
                        isMaking = true;
                        FirebaseFirestore.instance.collection('Group').doc(currentUserFlogCode).update({
                          'memoryBookNo': memoryBookNo,
                        });
                        FirebaseFirestore.instance.collection('Group').doc(currentUserFlogCode).update({
                          'isMaking': isMaking,
                        });
                      });
                    } : null,
                    //추억북 신청하기 버튼 디자인
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                        fixedSize: const Size(270, 60),
                        backgroundColor: const Color(0xFF62BC1B)
                    ),
                    child: Text(
                      !isMaking? '${memoryBookNo+1}번째 추억북 신청하기' : '$memoryBookNo번째 추억북 제작중 ...',
                      style: const TextStyle(
                        fontSize: 23,
                        color: Colors.white,
                      ),
                    ),
                  );
                }
            )
          ],
        ),
    );
  }
}
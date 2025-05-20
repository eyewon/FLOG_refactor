import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/blurred_flog_card.dart';
import '../../widgets/flog_card.dart';
import 'package:flog/screen/floging/floging_detail_screen.dart';

class MemoryBoxDetailScreen extends StatefulWidget {
  final String selectedDate;
  const MemoryBoxDetailScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  MemoryBoxDetailState createState() => MemoryBoxDetailState();
}

class MemoryBoxDetailState extends State<MemoryBoxDetailScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  late bool currentUserUploaded = false;
  String currentUserFlogCode = "";

  @override
  void initState() {
    super.initState();
    getUserFlogCode();
  }

  Future<void> getUserFlogCode() async {
    final userDoc = await FirebaseFirestore.instance.collection('User').doc(currentUser.email).get();
    if (userDoc.exists) {
      setState(() {
        currentUserFlogCode = userDoc.data()!['flogCode'];
        currentUserUploaded = userDoc.data()!['isUpload'];
      });
    }
    //print(currentUserFlogCode);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('User')
          .where('flogCode', isEqualTo: currentUserFlogCode)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Text('Error: ${userSnapshot.error}');
        }
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        userSnapshot.data!.docs;


        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            leading: IconButton(
              icon: Image.asset(
                "button/back_arrow.png",
                width: 20,
                height: 20,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              widget.selectedDate,
              style: GoogleFonts.balooBhaijaan2(
                textStyle: const TextStyle(
                  fontSize: 30,
                  color: Color(0xFF62BC1B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Floging')
                .where('flogCode', isEqualTo: currentUserFlogCode)
                .snapshots(),
            builder: (context, flogSnapshot) {
              if (flogSnapshot.hasError) {
                return Text('Error: ${flogSnapshot.error}');
              }
              if (flogSnapshot.connectionState == ConnectionState.waiting) {
                return Center(//로딩바 구현 부분
                  child: SpinKitPumpingHeart(
                    color: Colors.green.withOpacity(0.2),
                    size: 50.0, //크기 설정
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              final flogDocuments = flogSnapshot.data!.docs;

              final selectedParts = widget.selectedDate.split('.');
              final selectedYear = int.parse(selectedParts[0]);
              final selectedMonth = int.parse(selectedParts[1]);
              final selectedDay = int.parse(selectedParts[2]);

              final flogCount = flogDocuments.where((flogDoc) {
                final flogData = flogDoc.data() as Map<String, dynamic>;
                final date = flogData['date'] as Timestamp;
                final flogDate = date.toDate();
                return flogDate.year % 100 == selectedYear &&
                    flogDate.month == selectedMonth &&
                    flogDate.day == selectedDay;
              }).length;

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2개의 열로 플로그 카드 표시
                  mainAxisSpacing: 10, // 수직 방향 간격
                  crossAxisSpacing: 10, // 수평 방향 간격
                  childAspectRatio: 0.8, // 카드의 가로 세로 비율 (플로그 카드에 따라 조정)
                ),
                itemCount: flogCount, // 선택한 날짜에 해당하는 Flog 개수로 설정
                padding: const EdgeInsets.all(50.0),
                itemBuilder: (context, index) {
                  final selectedFlogDocs = flogDocuments.where((flogDoc) {
                    final flogData = flogDoc.data() as Map<String, dynamic>;
                    final date = flogData['date'] as Timestamp;
                    final flogDate = date.toDate();
                    return flogDate.year % 100 == selectedYear && flogDate.month == selectedMonth && flogDate.day == selectedDay;
                  }).toList();

                  if (index < selectedFlogDocs.length) {
                    final flogData = selectedFlogDocs[index].data() as Map<String, dynamic>;
                    final isToday = DateTime.now().year % 100 == selectedYear &&
                        DateTime.now().month == selectedMonth &&
                        DateTime.now().day == selectedDay;

                    return (isToday && !currentUserUploaded) ?
                    BlurredFlogCard(
                      date: flogData['date'],
                      frontImageURL: flogData['downloadUrl_front'],
                      backImageURL: flogData['downloadUrl_back'],
                      flogCode: flogData['flogCode'],
                      flogingId: flogData['flogingId'],
                      uid: flogData['uid'],
                    ) : GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FlogingDetailScreen(flogingId: flogData['flogingId']),
                          ),
                        );
                      },
                      child: FlogCard(
                        date: flogData['date'],
                        frontImageURL: flogData['downloadUrl_front'],
                        backImageURL: flogData['downloadUrl_back'],
                        flogCode: flogData['flogCode'],
                        flogingId: flogData['flogingId'],
                        uid: flogData['uid'],
                      ),
                    );
                }
                  return Container();
                },
              );
            },
          ),
        );
      },
    );
  }
}

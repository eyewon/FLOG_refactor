import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class MemoryBoxValuabledayShowAllScreen extends StatefulWidget {
  const MemoryBoxValuabledayShowAllScreen({Key? key}) : super(key: key);

  @override
  MemoryBoxValuabledayShowAllScreenState createState() => MemoryBoxValuabledayShowAllScreenState();
}

class MemoryBoxValuabledayShowAllScreenState extends State<MemoryBoxValuabledayShowAllScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  String currentUserFlogCode = "";

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

  Future<List<String>> getQuestions(int puzzleNumber) async {
    final questions = <String>[];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('Question')
        .where('puzzleNo', isEqualTo: puzzleNumber)
        .orderBy('questionNo')
        .get();

    for (final doc in querySnapshot.docs) {
      final questionContent = doc['questionContent'] as String;
      questions.add(questionContent);
    }
    return questions;
  }

  void _showQuestionBottomSheet(int puzzleNumber, int questionNo) async {

    questionNo = questionNo -1;
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('User')
                    .where('flogCode', isEqualTo: currentUserFlogCode)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  }
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Center( //로딩바 구현 부분
                        child: SpinKitPumpingHeart(
                          color: Colors.green.withOpacity(0.2),
                          size: 50.0, //크기 설정
                          duration: const Duration(seconds: 3),
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                    );
                  }

                  final userDocuments = userSnapshot.data!.docs;
                  userDocuments.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aEmail = aData['email'] as String;
                    final bEmail = bData['email'] as String;

                    if (aEmail == currentUser.email) {
                      return -1;
                    } else if (bEmail == currentUser.email) {
                      return 1;
                    } else {
                      return aEmail.compareTo(bEmail); //나머지 알파벳순 정렬
                    }
                  });

                  return ListView(
                    children: [
                      const SizedBox(height: 25),
                      Center(
                        child: Image.asset(
                          "assets/profile/profile_0.png",
                          width: 70,
                          height: 70,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder <QuerySnapshot> (
                          stream: FirebaseFirestore.instance
                              .collection("Question")
                              .where('puzzleNo', isEqualTo: puzzleNumber)
                              .where('questionNo', isEqualTo: questionNo)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            final questionData = snapshot.data!.docs.isNotEmpty
                                ? snapshot.data!.docs.first.data() as Map<String, dynamic>
                                : null;
                            if (questionData == null) {
                              return const Text('Question not found');
                            }
                            final questionContent = questionData['questionContent']; // 질문 내용 가져오기
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30), //왼쪽과 오른쪽 간격 지정
                                child: Text(
                                  'Q${questionNo + 1}. $questionContent',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold
                                  ),
                                  textAlign: TextAlign.left,
                                  softWrap: true, //자동 줄바꿈
                                ),
                              ),
                            );
                          }
                      ),
                      const SizedBox(height: 25),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userDocuments.length,
                        itemBuilder: (context, rowIndex) {
                          final userData = userDocuments[rowIndex].data() as Map<String, dynamic>;
                          final userProfile = userData['profile'];
                          final userNickname = userData['nickname'];
                          //각 사용자에 대한 답변을 불러오기
                          final answerCollection = FirebaseFirestore.instance.collection('Answer');
                          final query = answerCollection
                              .where('flogCode', isEqualTo: currentUserFlogCode)
                              .where('puzzleNo', isEqualTo: puzzleNumber)
                              .where('questionNo', isEqualTo: questionNo);

                          return StreamBuilder <QuerySnapshot> (
                              stream: query.snapshots(),
                              builder: (context, answerSnapshot){
                                if(answerSnapshot.hasError){
                                  return Text('Error: ${answerSnapshot.error}');
                                }
                                if (answerSnapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator(color: Colors.white);
                                }
                                final answerDocuments = answerSnapshot.data!.docs;
                                String userAnswer = '';
                                  for (final answerDoc in answerDocuments) {
                                    final answers = answerDoc['answers'] as Map<String, dynamic>;
                                    final userAnswerText = answers[userData['email']];
                                    if(userAnswerText != null) {
                                      userAnswer = userAnswerText;
                                      break;
                                    }
                                  }

                                return Container(
                                      width: double.infinity,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.transparent,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 20),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 15),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 10),
                                              Hero(
                                                tag: "profile",
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.grey[200],
                                                      ),
                                                      child: Center(
                                                        child: ClipOval(
                                                          child: Image.asset(
                                                            "assets/profile/profile_$userProfile.png",
                                                            width: 40,
                                                            height: 40,
                                                            alignment: Alignment.center,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 20),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userNickname,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height:7),
                                              SizedBox(
                                                width: 260,
                                                child: Text(
                                                userAnswer,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black,
                                                ),
                                                softWrap: true, // 자동 줄바꿈
                                              ),
                                              )
                                            ],
                                          )
                                        ],
                                      )
                                );
                              });
                        },
                      ),
                    ],
                  );
                }
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            SizedBox(width: 95),
            Text(
              '소중한 날',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 0.0,
        centerTitle: true,
      ),
      body: Center(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 25),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Qpuzzle')
                      .where('flogCode', isEqualTo: currentUserFlogCode)
                      .where('isComplete', isEqualTo: true)
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
                            duration: const Duration(seconds: 3),
                          ),
                        ),
                        backgroundColor: Colors.transparent,
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          '완성된 소중한 날이 아직 없어요.\n\n어서 큐퍼즐을 완성해보세요!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView(
                      children: docs.map((doc) {
                        final imagePath = doc['pictureUrl'];
                        final puzzleNumber = doc['puzzleNo'];

                        return FutureBuilder<List<String>>(
                          future: getQuestions(puzzleNumber),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Scaffold(
                                body: Center( //로딩바 구현 부분
                                  child: SpinKitPumpingHeart(
                                    color: Colors.green.withOpacity(0.2),
                                    size: 50.0, //크기 설정
                                    duration: const Duration(seconds: 3),
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                              );
                            }
                            if (snapshot.hasError) {
                              //print('Error: ${snapshot.error}');
                              return Text('Error: ${snapshot.error}');
                            }

                            final questions = snapshot.data;

                            if (questions != null) { // questions가 null이 아닌 경우에만 .map 호출
                              return Row(
                                children: [
                                  Stack(
                                    children:[
                                      Container(
                                        width: 200,
                                        height: 300,
                                        margin: const EdgeInsets.all(3.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: Colors.white, width: 1.5),
                                          color: const Color(0xFFCED3CE),
                                          image: DecorationImage(
                                            image: NetworkImage(imagePath),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0x99ffffff),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '#$puzzleNumber',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]
                                  ),
                                  const SizedBox(width: 10), // 사진과 질문 사이 간격
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: questions.asMap().entries.map((entry) {
                                        final questionNo = entry.key + 1; // questionNo는 0부터 시작하지 않고 1부터 시작한다고 가정
                                        final question = entry.value;
                                        return Column(
                                          children: [
                                            if (entry.key > 0) const Divider(height: 1, thickness: 1, color: Color(0xFF62BC1B)), // 상단 구분선 (첫 번째 질문 이후부터 추가)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0), // 상단과 하단 간격 조절
                                              child: GestureDetector(
                                                onTap: () {
                                                  _showQuestionBottomSheet(puzzleNumber, questionNo);
                                                },
                                                child: Text(
                                                  'Q$questionNo. $question',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              );
                            } else { // questions가 null인 경우에 대한 대체 처리
                              return const CircularProgressIndicator();
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



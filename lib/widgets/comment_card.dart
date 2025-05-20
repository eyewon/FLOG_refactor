// 댓글 달기 기능 구현
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';


class CommentCard extends StatelessWidget {
  final Timestamp date;
  final String commentId;
  final String text;
  final String uid;
  final String flogingId;

  CommentCard({
    super.key,
    required this.date,
    required this.commentId,
    required this.text,
    required this.uid,
    required this.flogingId,
  });

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;

  // 댓글 삭제 함수
  Future<void> _showDeleteCommentConfirmationDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // 모서리 둥글게
          ),
          title: const Text(
            '댓글 삭제',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF62BC1B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '이 댓글을 삭제하시겠습니까?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                  ),
                  onPressed: () async {
                    try {
                      // Firebase에서 댓글 삭제
                      await FirebaseFirestore.instance
                          .collection('Floging')
                          .doc(flogingId)
                          .collection('Comment')
                          .doc(commentId)
                          .delete();

                      Navigator.of(context).pop();
                    } catch (e) {
                      Navigator.of(context).pop();

                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return const AlertDialog(
                            title: Text('오류 발생'),
                            content: Text('댓글 삭제 중에 오류가 발생했습니다.'),
                          );
                        },
                      );
                    }
                  },
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection('User')
        .where('uid', isEqualTo: uid)
        .snapshots(),
    builder: (context, userSnapshot) {
      if (userSnapshot.hasError) {
        return Text('Error: ${userSnapshot.error}');
      }
      if (userSnapshot.connectionState ==
          ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }
      final userDocuments = userSnapshot.data!.docs;
      final userData = userDocuments.first.data() as Map<String, dynamic>;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
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
                    "assets/profile/profile_${userData['profile']}.png",
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: userData['nickname'],
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const WidgetSpan(
                            child: SizedBox(width: 4),
                          ),
                          TextSpan(
                            text: DateFormat('yy.MM.dd HH:mm').format(date.toDate()),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.uid == uid), // 자신이 쓴 댓글만 삭제할 수 있도록 하는 조건
              child: IconButton(
                onPressed: () {
                  _showDeleteCommentConfirmationDialog(context);
                },
                icon: const Icon(
                  Icons.delete_rounded,
                  size: 16,
                ),
              )
            ),
          ],
        ),
      );
    }
    );
  }
}

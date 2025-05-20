import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> checkTodayFlog() async {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final day = now.day;

  final userDocRef = FirebaseFirestore.instance
      .collection('User')
      .doc(currentUser.email);

  final flogSnapshot = await FirebaseFirestore.instance
      .collection('Floging')
      .where('uid', isEqualTo: currentUser.email)
      .get();

  final flogDocuments = flogSnapshot.docs;

  final todayFlog = flogDocuments.where((flogDoc) {
    final flogData = flogDoc.data() as Map<String, dynamic>;
    final date = flogData['date'] as Timestamp;
    final flogDate =
    DateTime.fromMicrosecondsSinceEpoch(date.microsecondsSinceEpoch);
    return flogDate.year == year && flogDate.month == month &&
        flogDate.day == day;
  });

  // Firebase에 업로드 상태 업데이트
  if (todayFlog.isNotEmpty) {
    userDocRef.update({'isUpload': true});
  } else {
    userDocRef.update({'isUpload': false});
  }
}

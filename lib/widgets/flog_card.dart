// 업로드한 상태를 보여주는 카드 기능 구현
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FlogCard extends StatelessWidget {
  final Timestamp date;
  final String frontImageURL;
  final String backImageURL;
  final String flogCode;
  final String flogingId;
  final String uid;

  const FlogCard({
    super.key,
    required this.date,
    required this.frontImageURL,
    required this.backImageURL,
    required this.flogCode,
    required this.flogingId,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          width: 130, // FlogCard의 너비 설정
          height: 200, // FlogCard의 높이 설정
          decoration: BoxDecoration(
                image: DecorationImage(image: NetworkImage(backImageURL),
                    fit: BoxFit.cover,
                ),
            color: const Color(0xffd9d9d9),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        // 후면 사진 표시 (동그란 모양)
        Positioned(
          top: 8, // 상단 위치
          right: 8, // 오른쪽 위치
          child: Container(
            width: 52,
            height: 80,
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(frontImageURL),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, // 상단 위치
          left: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(uid.split('@')[0], style: const TextStyle(color: Colors.white),),
                Text('${date.toDate().hour.toString().padLeft(2, '0')}:${date.toDate().minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white)), //hh:mm 형식으로 표시
              ],
            ),
          ),
        )
      ],
    );
  }
}

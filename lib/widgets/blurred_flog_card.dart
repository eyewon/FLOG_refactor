// 업로드한 상태를 보여주는 카드 기능 구현
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class BlurredFlogCard extends StatelessWidget {
  final Timestamp date;
  final String frontImageURL;
  final String backImageURL;
  final String flogCode;
  final String flogingId;
  final String uid;

  const BlurredFlogCard({
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
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0), // 반지름을 조절하여 원하는 만큼 둥글게 만듭니다.
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withOpacity(0.2)
                ),
              ),
            )
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
        ),
        Positioned(
          top: 70, // 상단 위치
          left: 19,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'button/hidden.png',
                width: 30,
                height: 30,
              ),
              const SizedBox(height: 10),
              const Text(
                '상태를 공유하고 확인하세요 !',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

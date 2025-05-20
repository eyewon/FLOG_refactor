import 'package:flutter/material.dart';

typedef OnStickerTap = void Function(int id);

class StickerPicker extends StatelessWidget {
  final OnStickerTap onStickerTap;

  const StickerPicker({
    required this.onStickerTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD1E0CA), //배경색 설정
        borderRadius: BorderRadius.circular(15.0),
      ),
      height: 110,
      width: 380,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      onStickerTap(index + 1);
                    },
                    child: Image.asset(
                      'assets/emoticons/emoticon_${index + 1}.png',
                      height: 43,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      onStickerTap(index + 6);
                    },
                    child: Image.asset(
                      'assets/emoticons/emoticon_${index + 6}.png',
                      height: 43,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 8),
            ]
        ),
      ),
    );
  }
}
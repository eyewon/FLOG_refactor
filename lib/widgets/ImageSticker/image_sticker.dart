import 'package:flutter/material.dart';

class ImageSticker extends StatefulWidget {
  final VoidCallback onTransform;
  final String imgPath;
  final bool isSelected;

  const ImageSticker({
    required this.onTransform,
    required this.imgPath,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageStickerState();
}

class _ImageStickerState extends State<ImageSticker> {
  double scale = 0.3;
  double hTransform = 0;
  double vTransform = 0;
  double actualScale = 0.3;

  double maxWidth = 345; // 사진의 최대 너비
  double maxHeight = 458; // 사진의 최대 높이

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTransform();
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        widget.onTransform();
        setState(() {
          scale = details.scale * actualScale;
          vTransform += details.focalPointDelta.dy;
          hTransform += details.focalPointDelta.dx;

          hTransform = hTransform.clamp(-10, maxWidth - maxWidth * scale);
          vTransform = vTransform.clamp(-70, maxHeight - maxHeight * scale - 10);

        });
      },
      onScaleEnd: (ScaleEndDetails details) {
        actualScale = scale;
      },
      child: Container(
        transform: Matrix4.identity()
          ..translate(hTransform, vTransform)
          ..scale(scale, scale),
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.0,
            color: Colors.transparent,
          ),
        ),
        child: Image.asset(widget.imgPath),
      ),
    );
  }
}
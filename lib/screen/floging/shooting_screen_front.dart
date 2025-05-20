import 'package:camera/camera.dart';
import 'package:flog/screen/floging/shooting_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ShootingScreenFront extends StatefulWidget {
  final String backImagePath;
  const ShootingScreenFront({Key? key, required this.backImagePath})
      : super(key: key);

  @override
  State<ShootingScreenFront> createState() => _ShootingScreenFrontState();
}

class _ShootingScreenFrontState extends State<ShootingScreenFront> {
  CameraController? _cameraController; //카메라 컨트롤러
  String? _tempFrontImagePath; //임시 전면 사진 저장

  bool _isCameraReady = false;

  bool _isCameraInitialized = false; //카메라 초기화되었는지
  bool _isProcessing = false; //사진 찍히고 있는지
  bool _isFlashOn = true; //플래시 켜져있는지
  bool isFaceDetected = false;

  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  //전면 카메라 - 가능한 카메라들의 목록을 하나 하나 검사하면서 전면 카메라를 발견하면 탐색 멈춤
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    for (CameraDescription camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        _initializeCameraController(camera);
        break;
      }
    }
    setState(() {
      _isCameraInitialized = true; // 카메라 초기화 완료
    });
    await _initializeFaceDetector();
  }

  Future<void> _initializeFaceDetector() async {
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.15,
    );

    _faceDetector = FaceDetector(options: options);
  }

  void _updateDetectingState(List<Face> faces) {
    if (faces.isNotEmpty) {
      setState(() {
        isFaceDetected = true;
      });
    } else {
      setState(() {
        isFaceDetected = false;
      });
    }
  }

  //카메라 컨트롤러 initalize
  void _initializeCameraController(CameraDescription camera) {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    _cameraController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isCameraReady = true; //카메라 컨트롤러 initalize 마쳤을 때
        });
      }
    });
  }

  void _showFaceDetectingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
          _navigateToEditScreen(context);
        });
        String message = isFaceDetected
            ? '얼굴을 보여주셨군요!\n가족들이 좋아할거예요!'
            : '얼굴이 인식되지 않았어요ㅠㅠ\n가족들이 당신을 보고싶어할거예요!ㅠ.ㅠ';
        String title = isFaceDetected ? '얼굴 감지 성공!' : '얼굴 감지 실패!';

        return Stack(
          children: [
            const ModalBarrier(
              color: Colors.white, // 배경 색상과 투명도 설정
              dismissible: false, // 배경 터치를 막음
            ),
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 0.0, // 그림자 없음
              backgroundColor: const Color(0xFFD1E0CA), // 배경색 설정
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF62BC1B),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                height: 70,
                width: 300,
                child: Center(
                    child: SizedBox(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //Edit Screen으로 전환하는 함수
  void _navigateToEditScreen(BuildContext context) {
    if (_tempFrontImagePath != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShootingEditScreen(
            backImagePath: widget.backImagePath,
            frontImagePath: _tempFrontImagePath!,
          ),
        ),
      );
    }
  }

  //전면 카메라 촬영
  void _takeFrontPicture(BuildContext context) async {
    if (_cameraController == null || !_isCameraReady || _isProcessing) return;
    setState(() {
      _isProcessing = true; // 사진 처리 중 표시
    });
    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);
      _updateDetectingState(faces);
      setState(() {
        _tempFrontImagePath = image.path;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false; // 사진 처리 실패 시 처리 중 표시 해제
      });
    }
    _showFaceDetectingDialog();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope( //뒤로가기 막음
        onWillPop: () async => false,
        child: Expanded(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                'Floging',
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
            body: Center(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10), // 간격
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20), //둥근 모서리
                          child: SizedBox(
                            width: 360,
                            height: 540,
                            child: _cameraController != null && _isCameraReady
                                ? CameraPreview(_cameraController!)
                                : Container(color: Colors.white,),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0), // 모서리 둥글게
                                    ),
                                    title: const Text(
                                      '메인 화면으로 돌아가시겠습니까?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF62BC1B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: const Text(
                                      '메인으로 돌아가면\n방금 찍은 사진은 복구할 수 없어요!',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 15),
                                      textAlign: TextAlign.center,
                                    ),
                                    actions: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(left: 40, right: 40),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              style: ButtonStyle(
                                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                                                  ),
                                                ),
                                                backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                                              ),
                                              child: const Text(
                                                '취소',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              },
                                              style: ButtonStyle(
                                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(15.0), // 모서리를 둥글게 설정
                                                  ),
                                                ),
                                                backgroundColor:
                                                MaterialStateProperty.all<Color>(const Color(0xFF62BC1B)),
                                              ),
                                              child: const Text(
                                                '확인',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: 30,
                              height: 30,
                              child: Image.asset(
                                "button/close.png",
                                width: 20,
                                height: 20,
                                color: Colors.white,
                              ),
                            )
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            //플래시 아이콘 버튼
                            onTap: () {
                              setState(() {
                                _isFlashOn = !_isFlashOn; // 플래시 상태를 토글
                                if (_isFlashOn) {
                                  _cameraController?.setFlashMode(FlashMode.auto);
                                } else {
                                  _cameraController?.setFlashMode(FlashMode.off);
                                }
                              });
                            },
                            child: Container(
                              height: 70,
                              decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8)
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    "button/flash.png",
                                    width: 50,
                                    height: 50,
                                    color: _isFlashOn
                                        ? Colors.white
                                        : Colors.grey, // 플래시 상태에 따라 아이콘 색상 변경
                                  ),
                                  Text(
                                    _isFlashOn ? "자동" : "OFF", // 텍스트 내용
                                    style: TextStyle(
                                      color: _isFlashOn
                                          ? Colors.white
                                          : Colors.grey, // 텍스트 색상 변경
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10), //간격
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell( //전면 카메라 촬영 버튼
                          onTap: _cameraController != null && _isCameraReady ? () {
                            _takeFrontPicture(context);
                          } : null,
                          child: _isProcessing ? Center( //로딩바 구현 부분
                            child: Column(
                              children: [
                                SpinKitPumpingHeart(
                                  color: Colors.green.withOpacity(0.2),
                                  size: 50.0, //크기 설정
                                  duration: const Duration(seconds: 2),
                                ),
                                const Text(
                                  '촬영중!',
                                  style: TextStyle(
                                    color: Color(0xFF62BC1B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ) : Image.asset(
                            "button/shooting.png",
                            width: 70,
                            height: 70,
                            color: _cameraController != null && _isCameraReady && _isCameraInitialized
                                ? const Color(0xFF62BC1B)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}
